{-# LANGUAGE CPP #-}

module Clang.Discover (
    -- * Types
    BuiltinIncDirConfig(..)
  , Paths(..)
  , ClangExe
  , BuiltinIncDir
    -- * Trace messages
  , DiscoverMsg(..)
    -- * API
  , getPaths
  ) where

import Control.Applicative (asum, (<|>))
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Trans.Maybe
import Data.Maybe
import Data.Text (Text)
import Data.Text qualified as Text
import GHC.Exception
import GHC.Stack
import System.Directory qualified as Dir
import System.Environment qualified as Env
import System.FilePath qualified as FilePath
import System.Process (readProcess)

#ifdef mingw32_HOST_OS
import Data.Char qualified as Char
import System.FilePath.Posix qualified as Posix
import System.FilePath.Windows qualified as Windows
#endif

import Clang.Version
import System.IO.Error

{-------------------------------------------------------------------------------
  Types
-------------------------------------------------------------------------------}

-- | Configure builtin include directory automatic configuration
data BuiltinIncDirConfig =
    -- | Do not configure the builtin include directory
    BuiltinIncDirDisable

    -- | Configure the builtin include directory using the resource directory
    -- from @clang@
  | BuiltinIncDirClang
  deriving (Eq, Show)

-- | Discovered path information
data Paths = Paths {
    pClangExe      :: Maybe ClangExe
  , pBuiltinIncDir :: Maybe BuiltinIncDir
  }

-- | Path to the @clang@ executable
type ClangExe = FilePath

-- | Path to the builtin include directory
type BuiltinIncDir = FilePath

{-------------------------------------------------------------------------------
  Trace messages
-------------------------------------------------------------------------------}

data DiscoverMsg =
    -- | @LLVM_PATH@ is not an existing directory (skipped)
    DiscoverLlvmPathNotFound FilePath

    -- | @llvm-config@ found using @PATH@
  | DiscoverLlvmConfigPathFound FilePath

    -- | @llvm-config --prefix@ produced unexpected output
  | DiscoverLlvmConfigPrefixUnexpected String

    -- | IO error calling @llvm-config --prefix@
  | DiscoverLlvmConfigPrefixIOError IOError

    -- | @clang@ not found
  | DiscoverClangNotFound

    -- | The @clang@ version does not match the @libclang@ version
  | DiscoverClangVersionMismatch Text Text

    -- | Builtin include directory not found using @clang@
  | DiscoverClangIncDirNotFound BuiltinIncDir

    -- | Builtin include directory found using @clang@
  | DiscoverClangIncDirFound BuiltinIncDir

    -- | @clang@ not found using @LLVM_PATH@
  | DiscoverLlvmPathClangExeNotFound FilePath

    -- | @clang@ found using @LLVM_PATH@
  | DiscoverLlvmPathClangExeFound FilePath

    -- | @clang@ not found using @llvm-config@
  | DiscoverLlvmConfigClangExeNotFound FilePath

    -- | @clang@ found using @llvm-config@
  | DiscoverLlvmConfigClangExeFound FilePath

    -- | @clang@ found using @PATH@
  | DiscoverClangPathFound FilePath

    -- | @clang --version@ produced unexpected output
  | DiscoverClangVersionUnexpected String

    -- | IO error calling @clang --version@
  | DiscoverClangVersionIOError IOError

    -- | @clang -print-resource-dir@ produced unexpected output
  | DiscoverClangPrintResourceDirUnexpected String

    -- | IO error calling @clang -print-resource-dir@
  | DiscoverClangPrintResourceDirIOError IOError
  deriving stock (Show)

{-------------------------------------------------------------------------------
  API
-------------------------------------------------------------------------------}

-- | Try to discover paths for the @clang@ executable, and the builtin include
-- directory
--
-- === Clang executable
--
-- The @clang@ executable is run to discover the builtin include directory.
--
-- This function tries to determine the path to the @clang@ executable by using
-- the first successful result of the following strategies:
--
-- 1. @${LLVM_PATH}/bin/clang@
-- 2. @$(llvm-config --prefix)/bin/clang@ (llvm-config is found using PATH)
-- 3. @clang@ (clang is found using PATH)
--
-- === Builtin include directory
--
-- LLVM/Clang determines the builtin include directory based on the path of the
-- @clang@ executable being run. When using @libclang@, there is not enough
-- information to determine the absolute builtin include directory.
--
-- Upstream issues:
--
-- * https://github.com/llvm/llvm-project/issues/18150
-- * https://github.com/llvm/llvm-project/issues/51256
--
-- The builtin include directory is in the Clang resource directory, which
-- contains the executables, headers, and libraries used by the Clang compiler.
--
-- When 'BuiltinIncDirClang' is used, this function tries to determine the
-- builtin include directory using the @clang@ executable discovered as
-- described above, using @$(clang -print-resource-dir)/include@.
getPaths ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> BuiltinIncDirConfig
  -> IO Paths
getPaths trace config = do
    mClangExe <- runMaybeT $ findClangExe trace
    mBuiltinIncDir <- case config of
      BuiltinIncDirDisable -> return Nothing
      BuiltinIncDirClang   -> runMaybeT $
        getBuiltinIncDirWithClang trace (myHoistMaybe mClangExe)
    let paths = Paths {
            pClangExe      = mClangExe
          , pBuiltinIncDir = mBuiltinIncDir
          }
    return paths
  where
    -- | hoistMaybe was only added in transformers-0.6.0.0
    myHoistMaybe :: Maybe a -> MaybeT IO a
    myHoistMaybe = MaybeT . pure

{-------------------------------------------------------------------------------
  Auxiliary functions
-------------------------------------------------------------------------------}

-- | Get the builtin include directory using @clang@
--
-- @clang -print-resource-dir@ is called to get the resource directory, and the
-- builtin include directory is the @include@ subdirectory within it.
getBuiltinIncDirWithClang ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> MaybeT IO ClangExe
  -> MaybeT IO BuiltinIncDir
getBuiltinIncDirWithClang trace getExe = do
    exe <- getExe <|> do
      liftIO $ trace callStack DiscoverClangNotFound
      MaybeT $ return Nothing
    clangVersionString <- getClangVersion trace exe
    let clangVersion = parseClangVersion clangVersionString
    unless (isCompatibleClangVersion runtimeClangVersion clangVersion) $ do
      liftIO $ trace callStack $
        DiscoverClangVersionMismatch
          runtimeClangVersionString
          clangVersionString
      MaybeT $ return Nothing
    resourceDir <- getClangResourceDir trace exe
    ifM
     trace
     DiscoverClangIncDirNotFound
     DiscoverClangIncDirFound
     Dir.doesDirectoryExist
     (FilePath.joinPath [resourceDir, "include"])

-- | Find the @clang@ executable
--
-- 1. @${LLVM_PATH}/bin/clang@
-- 2. @$(llvm-config --prefix)/bin/clang@ (llvm-config is found using PATH)
-- 3. @clang@ (clang is found using PATH)
findClangExe ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> MaybeT IO ClangExe
findClangExe trace = asum [auxLlvmPath, auxLlvmConfig, auxPath]
  where
    auxLlvmPath :: MaybeT IO ClangExe
    auxLlvmPath = do
      prefix <- lookupLlvmPath trace
      ifM
        trace
        DiscoverLlvmPathClangExeNotFound
        DiscoverLlvmPathClangExeFound
        Dir.doesFileExist
        (FilePath.joinPath [prefix, "bin", clangExe])

    auxLlvmConfig :: MaybeT IO ClangExe
    auxLlvmConfig = do
      exe <- findLlvmConfigExe trace
      prefix <- getLlvmConfigPrefix trace exe
      ifM
        trace
        DiscoverLlvmConfigClangExeNotFound
        DiscoverLlvmConfigClangExeFound
        Dir.doesFileExist
        (FilePath.joinPath [prefix, "bin", clangExe])

    auxPath :: MaybeT IO ClangExe
    auxPath = do
      exe <- MaybeT $ Dir.findExecutable clangExe
      liftIO $ trace callStack (DiscoverClangPathFound exe)
      return exe

-- | @clang@ executable name for the current platform
clangExe :: FilePath
clangExe =
#ifdef mingw32_HOST_OS
    "clang.exe"
#else
    "clang"
#endif

-- | Lookup @LLVM_PATH@ environment variable
lookupLlvmPath ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> MaybeT IO FilePath
lookupLlvmPath trace = do
    prefix <- MaybeT $ fmap normWinPath <$> Env.lookupEnv "LLVM_PATH"
    MaybeT $ Dir.doesDirectoryExist prefix >>= \case
      True  -> return (Just prefix)
      False -> do
        trace callStack (DiscoverLlvmPathNotFound prefix)
        return Nothing

-- | Find the @llvm-config@ executable using @PATH@
findLlvmConfigExe ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> MaybeT IO FilePath
findLlvmConfigExe trace = do
    exe <- MaybeT $ Dir.findExecutable llvmConfigExe
    liftIO $ trace callStack (DiscoverLlvmConfigPathFound exe)
    return exe

-- | @llvm-config@ executable name for the current platform
llvmConfigExe :: FilePath
llvmConfigExe =
#ifdef mingw32_HOST_OS
    "llvm-config.exe"
#else
    "llvm-config"
#endif

-- | Get the prefix from @llvm-config@
--
-- This function calls @llvm-config --prefix@ and captures the output.
getLlvmConfigPrefix ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> FilePath  -- ^ @llvm-config@ path
  -> MaybeT IO FilePath
getLlvmConfigPrefix trace exe = MaybeT $
    checkOutput
      trace
      DiscoverLlvmConfigPrefixUnexpected
      DiscoverLlvmConfigPrefixIOError
      (fmap normWinPath . parseSingleLine)
      (readProcess exe ["--prefix"] "")

-- | Get the Clang version from @clang@
--
-- This function calls @clang --version@ and captures the output.  The full
-- version string in the first line is returned.
getClangVersion ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> FilePath  -- ^ @clang@ path
  -> MaybeT IO Text
getClangVersion trace exe = MaybeT $
    checkOutput
      trace
      DiscoverClangVersionUnexpected
      DiscoverClangVersionIOError
      (fmap Text.pack . parseFirstLine)
      (readProcess exe ["--version"] "")

-- | Get the resource directory from @clang@
--
-- This function calls @clang -print-resource-dir@ and captures the output.
getClangResourceDir ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> FilePath  -- ^ @clang@ path
  -> MaybeT IO FilePath
getClangResourceDir tracer exe = MaybeT $
    checkOutput
      tracer
      DiscoverClangPrintResourceDirUnexpected
      DiscoverClangPrintResourceDirIOError
      (fmap normWinPath . parseSingleLine)
      (readProcess exe ["-print-resource-dir"] "")

--------------------------------------------------------------------------------

-- | Normalise Windows paths
--
-- This is just the identity function on non-Windows platforms.
normWinPath :: FilePath -> FilePath
#ifdef mingw32_HOST_OS
normWinPath path
    -- | Do not change paths with no @/@ in them
    | '/' `notElem` path = path
    | otherwise = case path of
        -- Convert POSIX absolute paths specifying the Windows drive
        '/' : drv : '/' : relPath -> Char.toUpper drv : ":\\" ++ aux relPath
        -- Do not change other POSIX absolute paths
        '/' : _                   -> path
        -- Normalise hybrid paths
        drv : ':' : '/' : relPath -> Char.toUpper drv : ":\\" ++ aux relPath
        -- Normalise relative paths
        relPath                   -> aux relPath
  where
    aux :: FilePath -> FilePath
    aux = Windows.joinPath . Posix.splitDirectories
#else
normWinPath = id
#endif

-- | Return a path only if it passes a predicate, tracing result
ifM ::
     HasCallStack
  => (CallStack -> DiscoverMsg -> IO ())
  -> (FilePath -> DiscoverMsg)  -- ^ not found constructor
  -> (FilePath -> DiscoverMsg)  -- ^ found constructor
  -> (FilePath -> IO Bool)           -- ^ predicate
  -> FilePath                        -- ^ path
  -> MaybeT IO FilePath
ifM trace mkNotFound mkFound p path = MaybeT $ p path >>= \case
    True  -> Just path <$ trace callStack (mkFound    path)
    False -> Nothing   <$ trace callStack (mkNotFound path)

--------------------------------------------------------------------------------

-- | Run a read action and check the output
checkOutput ::
     HasCallStack
  => (CallStack -> msg -> IO ())
  -> (String  -> msg)      -- ^ Unexpected output constructor
  -> (IOError -> msg)      -- ^ Error constructor
  -> (String  -> Maybe a)  -- ^ Output parser
  -> IO String             -- ^ Read action
  -> IO (Maybe a)
checkOutput trace mkUnexpected mkError parse action =
    tryIOError action >>= \case
      Right s -> case parse s of
        x@Just{} -> return x
        Nothing  -> Nothing <$ trace callStack (mkUnexpected (abbr s))
      Left  e -> Nothing <$ trace callStack (mkError e)
  where
    -- Abbreviate arbitrarily long strings in trace messages
    abbr :: String -> String
    abbr s = case splitAt 60 s of
      (_, []) -> s
      (s', _) -> s' ++ " ..."

-- | Parse a single line of output
parseSingleLine :: String -> Maybe String
parseSingleLine s = case lines s of
    [s'] -> Just s'
    _    -> Nothing

-- | Parse the first line of output
parseFirstLine :: String -> Maybe String
parseFirstLine = listToMaybe . lines

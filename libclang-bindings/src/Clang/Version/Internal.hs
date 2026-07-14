{-# LANGUAGE TemplateHaskell #-}

module Clang.Version.Internal (
    -- * Definition
    ClangVersion(..)
  , parseClangVersion
    -- * CLANG_VERSION macro
  , checkUserClangVersion
  ) where

import Control.Monad (unless)
import Data.Char qualified as Char
import Data.Maybe
import Data.Text (Text)
import Data.Text qualified as Text
import Foreign.C.String qualified as C
import Language.Haskell.TH.Syntax qualified as TH
import Text.Read (readMaybe)

import Version_libclang_bindings (clangVersionCompileTime)

{-------------------------------------------------------------------------------
  Definition
-------------------------------------------------------------------------------}

-- | Clang version
--
-- We're intentionally /not/ deriving 'Ord', to ensure that version comparisons
-- take 'ClangVersionUnknown' into account.
data ClangVersion =
    -- | Parsed version number (major, minor, patch)
    ClangVersion (Int, Int, Int)

    -- | Unknown version
    --
    -- We get the version by parsing the result of @clang_getClangVersion@,
    -- which explicitly says
    --
    -- > Return a version string, suitable for showing to a user, but not
    -- > intended to be parsed (the format is not guaranteed to be stable).
    --
    -- Unfortunately, @libclang@ does not provide any other means of getting
    -- the version number. We therefore parse the string anyway, and use
    -- 'ClangVersionUnknown' when that fails.
    --
    -- NOTE: While @Index.h@ does provide @CINDEX_VERSION_MAJOR@ (which is
    -- always zero) and @CINDEX_VERSION_MINOR@, unfortunately they do not map
    -- cleanly to @clang@ versions, and do not provide sufficient resolution.
    -- For example, a @CINDEX_VERSION_MINOR@ value of 64 could be any version
    -- between @17.0.0@ and @20.1.7@ (and possibly more still).
  | ClangVersionUnknown Text
  deriving stock (Show, Eq) -- No 'Ord'

-- | Parse clang version string
--
-- @clang_getClangVersion@ may return something like
--
-- > "Ubuntu clang version 14.0.0-1ubuntu1.1"
-- > "Ubuntu clang version 18.1.3 (1ubuntu1)"
-- > "Ubuntu clang version 19.1.1 (1ubuntu1~24.04.2)"
-- > "clang version 14.0.6"
-- > "clang version 14.0.6 (git@github.com:llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"
-- > "clang version 18.1.8 (https://github.com/llvm/llvm-project.git ad36915a8c42d51218eee4b53f2c0aae80eb17e9)"
-- > "clang version 20.1.4 (https://github.com/llvm/llvm-project ec28b8f9cc7f2ac187d8a617a6d08d5e56f9120e)"
--
-- We try to find the proper version (14.0.0, 18.1.3, ..) in this string.
parseClangVersion :: Text -> ClangVersion
parseClangVersion versionString =
      maybe (ClangVersionUnknown versionString) ClangVersion
    . (>>= readParts)
    . listToMaybe
    . mapMaybe exactlyThree
    . map (splitOn '.' . takeWhile isPartOfVersionProper)
    . words
    $ Text.unpack versionString
  where
    isPartOfVersionProper :: Char -> Bool
    isPartOfVersionProper c = (c >= '0' && c <= '9') || (c == '.')

    exactlyThree :: [a] -> Maybe (a, a, a)
    exactlyThree [x, y, z]  = Just (x, y, z)
    exactlyThree _otherwise = Nothing

    readParts :: (String, String, String) -> Maybe (Int, Int, Int)
    readParts (x, y, z) = (,,) <$> readMaybe x <*> readMaybe y <*> readMaybe z

{-------------------------------------------------------------------------------
  Auxiliary
-------------------------------------------------------------------------------}

-- | Split on every occurrence of the separator
--
-- > splitOn '.' "18.1.3" == ["18","1","3"]
splitOn :: forall a. Eq a => a -> [a] -> [[a]]
splitOn sep = go
  where
    go :: [a] -> [[a]]
    go [] = []
    go xs = case break (== sep) xs of
              (pref, [])        -> [pref]
              (pref, _sep:rest) -> pref : go rest

{-------------------------------------------------------------------------------
  CLANG_VERSION macro
-------------------------------------------------------------------------------}

-- There is no way to portably stringify a preprocessor macro in GHC.  (See
-- <https://gitlab.haskell.org/ghc/ghc/-/issues/12516>.)  To work around this,
-- we stringify the macro in C and define a C function that returns the string.
$([] <$ TH.addForeignSource TH.LangC (unlines
  [ "#define LCB_STR_HELPER(s) #s"
  , "#define LCB_STR(s) LCB_STR_HELPER(s)"
  , "const char *user_clang_version ="
  , "#ifdef CLANG_VERSION"
  , "  LCB_STR(CLANG_VERSION);"
  , "#else"
  , "  \"CLANG_VERSION_NOT_SET\";"
  , "#endif"
  , "const char *get_user_clang_version(void) {"
  , "  return user_clang_version;"
  , "}"
  ]))

foreign import ccall unsafe "get_user_clang_version"
  get_user_clang_version :: IO C.CString

-- | Clang version specified in the @CLANG_VERSION@ macro
data UserClangVersion =
    -- | Parsed version
    --
    -- This includes the original string (for error messages) as well as the
    -- major, minor (optional), and patch (optional) numbers.
    UserClangVersion (String, Int, Maybe Int, Maybe Int)

    -- | Unknown version
  | UserClangVersionUnknown String

-- | Get the Clang version specified in the @CLANG_VERSION@ macro
--
-- This function returns 'Nothing' when the macro is not set.
getUserClangVersion :: IO (Maybe UserClangVersion)
getUserClangVersion =
    get_user_clang_version >>= C.peekCString >>= return . \case
      "CLANG_VERSION_NOT_SET" -> Nothing
      s -> Just $
        case sequence (parse s) of
          Just [major, minor, patch] ->
            UserClangVersion (s, major, Just minor, Just patch)
          Just [major, minor] ->
            UserClangVersion (s, major, Just minor, Nothing)
          Just [major] ->
            UserClangVersion (s, major, Nothing, Nothing)
          _otherwise ->
            UserClangVersionUnknown s
  where
    parse :: String -> [Maybe Int]
    parse s = case span Char.isDigit s of
      (l@(_:_), "")    -> [readMaybe l]
      (l@(_:_), '.':r) -> readMaybe l : parse r
      _otherwise       -> [Nothing]

-- | Check the compile-time Clang version against the Clang version specified in
-- the @CLANG_VERSION@ macro
--
-- Users may /optionally/ specify a Clang version in the @CLANG_VERSION@ macro.
-- When set, this function is used to check that the compile-time Clang version
-- matches, failing if not.  When not set, no check is performed.
--
-- Only the version number is checked.  The following checks are supported:
--
-- * @MAJOR@ to just check the major version (example: @21@)
-- * @MAJOR.MINOR@ to check the major and minor versions (example: @21.1@)
-- * @MAJOR.MINOR.PATCH@ to check the major, minor, and patch versions
--   (example: @21.1.8@)
--
-- The primary motivation for this is to distinguish the Clang version in cached
-- builds in the Cabal store.  Cabal does not consider system dependencies to
-- determine when a package needs to be rebuilt.  This is particularly
-- problematic for @libclang-bindings@ because the LLVM/Clang project has
-- frequent releases, and it is easy to run into a situation where a library
-- cached in the Cabal store no longer works.  This can be solved by clearing
-- the Cabal store, but doing so may result in time-consuming recompilation of
-- many other packages.  The @CLANG_VERSION@ macro provides a workaround:
-- changing GHC options forces Cabal to rebuild the library.
--
-- The @CLANG_VERSION@ macro is generally set in a @cabal.project.local@ file,
-- by configuring @-optc@ in @ghc-options@.  Note that @cc-options@ is /not/
-- sufficient to force Cabal to rebuild the library.  Example:
--
-- @
-- package libclang-bindings
--   ghc-options: -optc=-DCLANG_VERSION=21.1
-- @
checkUserClangVersion :: TH.Q [TH.Dec]
checkUserClangVersion = TH.runIO getUserClangVersion >>= ([] <$) . \case
    Nothing -> return ()
    Just (UserClangVersionUnknown s) ->
      fail $ "Unable to parse CLANG_VERSION: " ++ s
    Just (UserClangVersion (uVersion, uMajor, mUMinor, mUPatch)) ->
      case parseClangVersion clangVersionCompileTime of
        ClangVersionUnknown t ->
          fail $ "Unable to parse linked libclang version: " ++ Text.unpack t
        ClangVersion (major, minor, patch) -> do
          let compatible =
                uMajor == major
                  && maybe True (== minor) mUMinor
                  && maybe True (== patch) mUPatch
          unless compatible . fail $
            "CLANG_VERSION " ++ uVersion ++ " does not match "
              ++ Text.unpack clangVersionCompileTime

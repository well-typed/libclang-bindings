module Test.Discover (tests) where

import Control.Monad (forM_)
import Data.IORef
import GHC.Stack (CallStack)
import System.Directory (doesDirectoryExist, doesFileExist)
import Test.Tasty
import Test.Tasty.HUnit

import Clang.Discover

{-------------------------------------------------------------------------------
  List of tests

  'getPaths' inspects (and the tests below temporarily set) process-global
  environment variables, so the tests are run sequentially to avoid races with
  each other.

  We cannot assume that @clang@ is installed (and so cannot assume that any
  particular path /is/ discovered), but the assertions below hold regardless of
  the platform or whether @clang@ is available.
-------------------------------------------------------------------------------}

tests :: TestTree
tests = sequentialTestGroup "Test.Discover" AllFinish [
      testCaseInfo "discovered paths exist"      testDiscoveredPathsExist
    , testCase     "disabled config"             testDisabledConfig
    ]

-- | Smoke test against the real environment
--
-- Discovery must not crash, and any path that /is/ reported must actually exist
-- on disk.
testDiscoveredPathsExist :: IO String
testDiscoveredPathsExist = do
    msgsRef <- newIORef []
    let trace _cs msg = modifyIORef' msgsRef (msg :)

    paths <- getPaths trace BuiltinIncDirClang
    forM_ (pClangExe paths) $ \exe -> do
      exists <- doesFileExist exe
      assertBool ("discovered clang executable does not exist: " ++ exe) exists
    forM_ (pBuiltinIncDir paths) $ \dir -> do
      exists <- doesDirectoryExist dir
      assertBool ("discovered builtin include dir does not exist: " ++ dir) exists

    -- Report what was discovered (and the collected trace) on success.
    msgs <- reverse <$> readIORef msgsRef
    return $ unlines $ [
          "clang executable:    " ++ show (pClangExe      paths)
        , "builtin include dir: " ++ show (pBuiltinIncDir paths)
        , "trace:"
        ] ++ map (("  " ++) . show) msgs

-- | With discovery disabled, no builtin include dir is reported, whether or not
-- @clang@ is installed
--
-- We clear the environment variable so that an ambient setting cannot override
-- the config.
testDisabledConfig :: Assertion
testDisabledConfig = do
    paths <- getPaths ignoreTrace BuiltinIncDirDisable
    assertEqual "disabled config yields no builtin include dir"
      Nothing (pBuiltinIncDir paths)

{-------------------------------------------------------------------------------
  Auxiliary functions
-------------------------------------------------------------------------------}

-- | A trace function that discards all messages
ignoreTrace :: CallStack -> DiscoverMsg -> IO ()
ignoreTrace _cs _msg = return ()

{-# LANGUAGE OverloadedStrings #-}

-- | Convenience functions around the clang bindings
--
-- Intended for unqualified import.
module Test.Util.Clang (
    -- * Top-level call into clang
    withInput
  , withInputUsing
  , parseUsing
  ) where

import Control.Exception
import Data.Default
import Test.Util.Input (TestInput (..))

import Clang.Args
import Clang.Enum.Bitfield
import Clang.Enum.Simple
import Clang.HighLevel qualified as HighLevel
import Clang.HighLevel.Types
import Clang.LowLevel.Core

{-------------------------------------------------------------------------------
  Top-level call into clang
-------------------------------------------------------------------------------}

withInput :: TestInput -> (CXTranslationUnit -> IO a) -> IO a
withInput = withInputUsing def mempty

withInputUsing ::
     ClangArgs
  -> BitfieldEnum CXTranslationUnit_Flags
  -> TestInput
  -> (CXTranslationUnit -> IO a)
  -> IO a
withInputUsing args flags (TestInput input) onSuccess =
    HighLevel.withUnsavedFile "test.h" input $ \file ->
    HighLevel.withIndex DisplayDiagnostics   $ \ix   ->
    HighLevel.withTranslationUnit2
      ix
      (Just "test.h")
      args
      [file]
      flags
      onFailure
      onSuccess
  where
    onFailure :: SimpleEnum CXErrorCode -> IO a
    onFailure = throwIO . userError . show

parseUsing :: Fold IO a -> TestInput -> IO [a]
parseUsing fold input = do
    withInput input $ \unit -> do
      root   <- clang_getTranslationUnitCursor unit
      HighLevel.clang_visitChildren root fold

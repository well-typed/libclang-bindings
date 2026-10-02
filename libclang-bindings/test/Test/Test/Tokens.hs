{-# LANGUAGE OverloadedStrings #-}

-- | Test tokenization of cursor extents
module Test.Test.Tokens (tests) where

import Data.Default (def)
import Data.Text (Text)
import Test.Tasty
import Test.Tasty.HUnit
import Test.Util.Clang qualified as Clang
import Test.Util.Input (TestInput)
import Test.Util.Input qualified as Input

import Clang.Args
import Clang.Enum.Bitfield
import Clang.Enum.Simple
import Clang.HighLevel qualified as HighLevel
import Clang.HighLevel.Types
import Clang.LowLevel.Core

{-------------------------------------------------------------------------------
  List of tests
-------------------------------------------------------------------------------}

tests :: TestTree
tests = testGroup "Test.Test.Tokens" [
      testCase "macroDefinition"        tokenize_macroDefinition
    , testCase "commandLineMacro"       tokenize_commandLineMacro
    , testCase "declStartsInExpansion"  tokenize_declStartsInExpansion
    ]

{-------------------------------------------------------------------------------
  Tests
-------------------------------------------------------------------------------}

tokenize_macroDefinition :: Assertion
tokenize_macroDefinition = do
    tokens <- tokenizeCursor def input CXCursor_MacroDefinition "FOO"
    assertEqual "" ["FOO", "(", "x", ")", "x", "+", "1"] tokens
  where
    input :: TestInput
    input = "#define FOO(x) x + 1\n"

-- | A @-D@ macro lives in Clang's predefines buffer, which has no 'CXFile'
tokenize_commandLineMacro :: Assertion
tokenize_commandLineMacro = do
    tokens <- tokenizeCursor args "" CXCursor_MacroDefinition "FOO"
    assertEqual "" ["FOO", "(", "x", ")", "x", "+", "1"] tokens
  where
    args :: ClangArgs
    args = ClangArgs ["-DFOO(x)=x + 1"]

-- | The range is tokenized as is, from the spelling location of its start
tokenize_declStartsInExpansion :: Assertion
tokenize_declStartsInExpansion = do
    tokens <- tokenizeCursor def input CXCursor_VarDecl "x"
    assertEqual "" ["int", "T", "x"] tokens
  where
    input :: TestInput
    input = Input.unlines [
        "#define T int"
      , "T x;"
      ]

{-------------------------------------------------------------------------------
  Auxiliary
-------------------------------------------------------------------------------}

-- | Tokenize the extent of the top-level cursor with the given kind and name
tokenizeCursor ::
     ClangArgs
  -> TestInput
  -> CXCursorKind
  -> Text
  -> IO [Text]
tokenizeCursor args input kind name =
    Clang.withInputUsing args flags input $ \unit -> do
      root    <- clang_getTranslationUnitCursor unit
      extents <- HighLevel.clang_visitChildren root $ simpleFold $ \curr -> do
        currKind <- fromSimpleEnum <$> clang_getCursorKind curr
        currName <- clang_getCursorSpelling curr
        if currKind == Right kind && currName == name
          then foldContinueWith =<< clang_getCursorExtent curr
          else foldContinue
      case extents of
        [extent] ->
          map (getTokenSpelling . tokenSpelling)
            <$> HighLevel.clang_tokenize unit extent
        _otherwise ->
          assertFailure $ "expected one cursor, found " ++ show (length extents)
  where
    flags :: BitfieldEnum CXTranslationUnit_Flags
    flags = bitfieldEnum [CXTranslationUnit_DetailedPreprocessingRecord]

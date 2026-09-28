module Clang.HighLevel.Tokens (
    Token(..)
  , TokenSpelling(..)
  , clang_tokenize
  ) where

import Control.Exception
import Control.Monad
import Control.Monad.IO.Class
import Data.Text (Text)
import GHC.Generics (Generic)
import GHC.Stack

import Clang.Enum.Simple
import Clang.HighLevel.SourceLoc (MultiLoc, Range, SingleLoc)
import Clang.HighLevel.SourceLoc qualified as SourceLoc
import Clang.LowLevel.Core hiding (clang_tokenize)
import Clang.LowLevel.Core qualified as Core
import Clang.Paths (SourcePath)

{-------------------------------------------------------------------------------
  Definition
-------------------------------------------------------------------------------}

data Token path a = Token {
      tokenKind       :: !(SimpleEnum CXTokenKind)
    , tokenSpelling   :: !a
    , tokenExtent     :: !(Range (MultiLoc path))
    , tokenCursorKind :: !(SimpleEnum CXCursorKind)
    }
  deriving stock (Eq, Ord, Functor, Foldable, Traversable, Generic)

deriving stock instance (Show a, Show (Range (MultiLoc path))) => Show (Token path a)

newtype TokenSpelling = TokenSpelling {
      getTokenSpelling :: Text
    }
  deriving stock (Show, Eq, Ord, Generic)

{-------------------------------------------------------------------------------
  Extraction
-------------------------------------------------------------------------------}

-- | Get all tokens in the specified range
clang_tokenize ::
     (MonadIO m, HasCallStack)
  => CXTranslationUnit
  -> (path -> Text)
  -> Range (SingleLoc path)
  -> m [Token SourcePath TokenSpelling]
clang_tokenize unit getPath range = do
    cxRange <- SourceLoc.fromRange unit getPath range
    liftIO $
      bracket
          (Core.clang_tokenize unit cxRange)
          (uncurry $ Core.clang_disposeTokens unit) $ \(tokens, numTokens) -> do
        if numTokens == 0
          then return []
          else do
            cursors <- clang_annotateTokens unit tokens numTokens
            forM [0 .. pred numTokens] $ \i -> do
              cursor <- index_CXCursorArray cursors i
              toToken unit (index_CXTokenArray tokens i) cursor

toToken ::
     MonadIO m
  => CXTranslationUnit -> CXToken -> CXCursor -> m (Token SourcePath TokenSpelling)
toToken unit token cursor = do
    tokenKind       <- clang_getTokenKind token
    tokenSpelling   <- TokenSpelling <$> clang_getTokenSpelling unit token
    tokenExtent     <- SourceLoc.toRangeSourcePath =<< Core.clang_getTokenExtent unit token
    tokenCursorKind <- clang_getCursorKind cursor
    return Token{
        tokenKind
      , tokenSpelling
      , tokenExtent
      , tokenCursorKind
      }

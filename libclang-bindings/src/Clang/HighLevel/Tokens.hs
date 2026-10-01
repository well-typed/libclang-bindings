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

import Clang.Enum.Simple
import Clang.HighLevel.SourceLoc (MultiLoc, Range)
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
--
-- @libclang@ lexes the source text between the spelling locations of the start
-- and end of the range.
--
-- Consequently, a range that starts inside a macro expansion starts in the
-- macro definition. For example, given
--
-- > #define T int
-- > T x;
--
-- the extent of @x@ starts at the @int@ produced by expanding @T@, and yields
-- the tokens @int T x@: the text from the @int@ in the definition to @x@.
clang_tokenize ::
     MonadIO m
  => CXTranslationUnit
  -> CXSourceRange
  -> m [Token SourcePath TokenSpelling]
clang_tokenize unit range =
    liftIO $
      bracket
          (Core.clang_tokenize unit range)
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

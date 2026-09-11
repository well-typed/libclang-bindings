-- | Utilities for working with source locations
module Clang.HighLevel.SourceLoc (
    -- * Definition
    SingleLoc(..)
  , MultiLoc(..)
  , Range(..)
    -- * Comparisons
  , compareSingleLoc
  , rangeContainsLoc
    -- * Conversion (CXFile)
  , toMultiCXFile
    -- * Conversion (RealPath)
  , toSingleRealPath
  , toMultiRealPath
  , toRangeRealPath
  , fromSingle
  , fromRange
    -- * Conversion (SourcePath)
  , toSingleSourcePath
  , toMultiSourcePath
  , toRangeSourcePath
    -- * Get single location
  , clang_getExpansionLocation
  , clang_getPresumedLocation
  , clang_getSpellingLocation
  , clang_getFileLocation
    -- * Pretty-printing
    --
    -- We export these separately, because the 'Show' instance also adds quotes
    -- (in order to produce valid Haskell syntax).
  , ShowFile(..)
  , prettySingleLoc
  , prettyMultiLoc
  , prettyRangeSingleLoc
  , prettyRangeMultiLoc
    -- * File to RealPath
  , ClangRealPathException(..)
  , clang_getRealPath
  , clang_tryGetRealPath
    -- * Convenience wrappers
    -- * for @CXSourceLocation@
  , clang_getDiagnosticLocation
  , clang_getCursorLocation
  , clang_getCursorLocation'
  , clang_getTokenLocation
    -- ** for @CXSourceRange@
  , clang_getDiagnosticRange
  , clang_getDiagnosticFixIt
  , clang_Cursor_getSpellingNameRange
  , clang_getCursorExtent
  , clang_getTokenExtent
  ) where

import Control.Exception (Exception, throwIO)
import Control.Monad
import Control.Monad.IO.Class
import Data.List (intercalate)
import Data.Text (Text)
import Data.Text qualified as Text
import Foreign.C
import GHC.Generics (Generic)
import GHC.Stack

import Clang.LowLevel.Core qualified as Core
import Clang.LowLevel.Core.Pointers (CXFile)
import Clang.Paths

{-------------------------------------------------------------------------------
  Definition
-------------------------------------------------------------------------------}

-- | A single location in a file
--
data SingleLoc path = SingleLoc {
      singleLocPath   :: !path
    , singleLocLine   :: !Int
    , singleLocColumn :: !Int
    , singleLocOffset :: !Int
    }
  deriving stock (Eq, Ord, Generic, Functor, Foldable, Traversable)

-- | Presumed location
--
-- Presumed locations arise from @#line@ directives, and as such don't provide
-- an offset.
data PresumedLoc = PresumedLoc {
      presumedLocPath   :: !SourcePath
    , presumedLocLine   :: !Int
    , presumedLocColumn :: !Int
    }
  deriving stock (Eq, Ord, Generic)


-- | Multiple related source locations
--
-- 'Core.CXSourceLocation' in @libclang@ corresponds to @SourceLocation@ in
-- @clang@, which can actually correspond to /multiple/ source locations in a
-- file; for example, in a header file such as
--
-- > #define M1 int
-- >
-- > struct ExampleStruct {
-- >   M1 m1;
-- >   ^
-- > };
--
-- then the source location at the caret (@^@) has an \"expansion location\",
-- which is the position at the caret, and a \"spelling location\", which
-- corresponds to the location of the @int@ token in the macro definition.
--
-- References:
--
-- * <https://clang.llvm.org/doxygen/classclang_1_1SourceLocation.html>
-- * <https://clang.llvm.org/doxygen/classclang_1_1SourceManager.html>
--   (@getExpansionLoc@, @getSpellingLoc@, @getDecomposedSpellingLoc@)
data MultiLoc path = MultiLoc {
      -- | Expansion location
      --
      -- If the location refers into a macro expansion, this corresponds to the
      -- location of the macro expansion.
      --
      -- See <https://clang.llvm.org/doxygen/group__CINDEX__LOCATIONS.html#gadee4bea0fa34550663e869f48550eb1f>
      multiLocExpansion :: !(SingleLoc path)

      -- | Presumed location
      --
      -- The given source location as specified in a @#line@ directive.
      --
      -- See <https://clang.llvm.org/doxygen/group__CINDEX__LOCATIONS.html#ga03508d9c944feeb3877515a1b08d36f9>
    , multiLocPresumed :: !(Maybe PresumedLoc)

      -- | Spelling location
      --
      -- If the location refers into a macro instantiation, this corresponds to
      -- the /original/ location of the spelling in the source file.
      --
      -- /WARNING/: This field is only populated correctly from @llvm >= 19.1.0@;
      -- prior to that this is equal to 'multiLocFile'.
      -- See <https://github.com/llvm/llvm-project/pull/72400>.
      --
      -- See <https://clang.llvm.org/doxygen/group__CINDEX__LOCATIONS.html#ga01f1a342f7807ea742aedd2c61c46fa0>
    , multiLocSpelling :: !(Maybe (SingleLoc path))

      -- | File location
      --
      -- If the location refers into a macro expansion, this corresponds to the
      -- location of the macro expansion.
      -- If the location points at a macro argument, this corresponds to the
      -- location of the use of the argument.
      --
      -- See <https://clang.llvm.org/doxygen/group__CINDEX__LOCATIONS.html#gae0ee9ff0ea04f2446832fc12a7fd2ac8>
    , multiLocFile :: !(Maybe (SingleLoc path))
    }
  deriving stock (Eq, Ord, Generic, Functor, Foldable, Traversable)

-- | Range
--
-- 'Core.CXSourceRange' corresponds to @SourceRange@ in @clang@
-- <https://clang.llvm.org/doxygen/classclang_1_1SourceLocation.html>,
-- and therefore to @Range MultiLoc@; see 'MultiLoc' for additional discussion.
data Range a = Range {
      rangeStart :: !a
    , rangeEnd   :: !a
    }
  deriving stock (Eq, Ord, Generic)
  deriving stock (Functor, Foldable, Traversable)

{-------------------------------------------------------------------------------
  Comparisons
-------------------------------------------------------------------------------}

-- | Compare locations
--
-- Returns 'Nothing' if the locations aren't in the same file.
compareSingleLoc :: Eq path => SingleLoc path -> SingleLoc path -> Maybe Ordering
compareSingleLoc a b = do
    guard $ singleLocPath a == singleLocPath b
    return $
      compare
        (singleLocLine a, singleLocColumn a)
        (singleLocLine b, singleLocColumn b)

-- | Check if a location falls within the given range
--
-- Treats the range as half-open, with an inclusive lower bound and exclusive
-- upper bound (following 'Core.CXSourceRange').
--
-- Returns 'Nothing' if the three locations are not all in the same file.
rangeContainsLoc :: Eq path => Range (SingleLoc path) -> SingleLoc path -> Maybe Bool
rangeContainsLoc Range{rangeStart, rangeEnd} loc = do
    afterStart <- (/= LT) <$> compareSingleLoc loc rangeStart
    beforeEnd  <- (== LT) <$> compareSingleLoc loc rangeEnd
    return $ afterStart && beforeEnd

{-------------------------------------------------------------------------------
  Show instances

  Technically speaking the validity of these instances depends on 'IsString'
  instances which we do not (yet?) define.
-------------------------------------------------------------------------------}

instance Show (SingleLoc RealPath)         where show = show . prettySingleLoc getRealPath ShowFile
instance Show (MultiLoc RealPath)          where show = show . prettyMultiLoc  getRealPath ShowFile
instance Show (Range (SingleLoc RealPath)) where show = show . prettyRangeSingleLoc getRealPath
instance Show (Range (MultiLoc RealPath))  where show = show . prettyRangeMultiLoc  getRealPath

instance Show (SingleLoc SourcePath)         where show = show . prettySingleLoc getSourcePath ShowFile
instance Show (MultiLoc SourcePath)          where show = show . prettyMultiLoc  getSourcePath ShowFile
instance Show (Range (SingleLoc SourcePath)) where show = show . prettyRangeSingleLoc getSourcePath
instance Show (Range (MultiLoc SourcePath))  where show = show . prettyRangeMultiLoc  getSourcePath

deriving stock instance {-# OVERLAPPABLE #-} Show a => Show (Range a)

{-------------------------------------------------------------------------------
  Pretty-printing

  These instances mimic the behaviour of @SourceLocation::print@ and
  @SourceRange::print@ in @clang@.
-------------------------------------------------------------------------------}

data ShowFile = ShowFile | HideFile

prettySingleLoc :: (path -> String) -> ShowFile -> SingleLoc path -> String
prettySingleLoc getPath showFile loc = case showFile of
    -- Use space instead of first colon to avoid GHC literate preprocessor mangling
    ShowFile -> getPath singleLocPath ++ " "
                  ++ show singleLocLine ++ ":" ++ show singleLocColumn
    HideFile -> show singleLocLine ++ ":" ++ show singleLocColumn
  where
    SingleLoc{singleLocPath, singleLocLine, singleLocColumn} = loc

prettyMultiLoc :: forall path. (path -> String) -> ShowFile -> MultiLoc path -> String
prettyMultiLoc getPath showFile multiLoc =
    intercalate " " . concat $ [
        [ prettySingleLoc getPath showFile multiLocExpansion ]
      , [ "<Presumed=" ++ presumed loc       ++ ">" | Just loc <- [multiLocPresumed] ]
      , [ "<Spelling=" ++ single getPath loc ++ ">" | Just loc <- [multiLocSpelling] ]
      , [ "<File="     ++ single getPath loc ++ ">" | Just loc <- [multiLocFile]     ]
      ]
  where
    MultiLoc{
        multiLocExpansion
      , multiLocPresumed
      , multiLocSpelling
      , multiLocFile} = multiLoc

    expansionFilePath :: FilePath
    expansionFilePath = getPath (singleLocPath multiLocExpansion)

    presumed :: PresumedLoc -> String
    presumed loc = single getSourcePath SingleLoc{
          singleLocPath   = presumedLocPath   loc
        , singleLocLine   = presumedLocLine   loc
        , singleLocColumn = presumedLocColumn loc
        , singleLocOffset = 0 -- not used for pretty-printing
        }

    single :: (p -> String) -> SingleLoc p -> String
    single get loc =
        prettySingleLoc get
          (if get (singleLocPath loc) == expansionFilePath
             then HideFile else ShowFile)
          loc

prettyRangeSingleLoc :: Eq path => (path -> String) -> Range (SingleLoc path) -> String
prettyRangeSingleLoc getPath = prettySourceRangeWith
      singleLocPath
      (prettySingleLoc getPath)

prettyRangeMultiLoc :: Eq path => (path -> String) -> Range (MultiLoc path) -> String
prettyRangeMultiLoc getPath =
    prettySourceRangeWith
      (singleLocPath . multiLocExpansion)
      (prettyMultiLoc getPath)

prettySourceRangeWith ::
     Eq p
  => (a -> p)
  -> (ShowFile -> a -> String)
  -> Range a -> String
prettySourceRangeWith path pretty Range{rangeStart, rangeEnd} = concat [
      "<"
    , pretty ShowFile rangeStart
    , "-"
    , pretty
        (if path rangeStart == path rangeEnd then HideFile else ShowFile)
        rangeEnd
    , ">"
    ]

{-------------------------------------------------------------------------------
  Conversion
-------------------------------------------------------------------------------}

-- | Build a 'MultiLoc' holding raw 'CXFile' handles.
--
toMultiCXFile :: MonadIO m => Core.CXSourceLocation -> m (MultiLoc CXFile)
toMultiCXFile location = do
    expansion <- toSingleCXFile =<< Core.clang_getExpansionLocation location
    presumed  <- clang_getPresumedLocation location
    spelling  <- toSingleCXFile =<< Core.clang_getSpellingLocation location
    file      <- toSingleCXFile =<< Core.clang_getFileLocation location

    expansionName <- Core.clang_getFileName (singleLocPath expansion)

    let differentSingle loc = do
            guard . not $
              Core.clang_File_isEqual (singleLocPath loc) (singleLocPath expansion)
            guard $ singleLocLine   loc /= singleLocLine   expansion
            guard $ singleLocColumn loc /= singleLocColumn expansion
            return loc

        differentPresumed loc = do
            guard $ getSourcePathText (presumedLocPath loc) /= expansionName
            guard $ presumedLocLine   loc /= singleLocLine   expansion
            guard $ presumedLocColumn loc /= singleLocColumn expansion
            return loc

    return MultiLoc{
        multiLocExpansion = expansion
      , multiLocPresumed  = differentPresumed presumed
      , multiLocSpelling  = differentSingle spelling
      , multiLocFile      = differentSingle file
      }
  where
    toSingleCXFile (f, line, column, offset) = return SingleLoc{
        singleLocPath   = f
      , singleLocLine   = fromIntegral line
      , singleLocColumn = fromIntegral column
      , singleLocOffset = fromIntegral offset
      }

-- | Throws 'ClangRealPathException' for virtual files.
toMultiRealPath :: (MonadIO m, HasCallStack) => Core.CXSourceLocation -> m (MultiLoc RealPath)
toMultiRealPath location =
    traverse clang_getRealPath =<< toMultiCXFile location

toMultiSourcePath :: MonadIO m => Core.CXSourceLocation -> m (MultiLoc SourcePath)
toMultiSourcePath location =
    traverse (fmap SourcePath . Core.clang_getFileName) =<< toMultiCXFile location

toRangeRealPath :: (MonadIO m, HasCallStack) => Core.CXSourceRange -> m (Range (MultiLoc RealPath))
toRangeRealPath = toRangeWith toMultiRealPath

toRangeSourcePath :: MonadIO m => Core.CXSourceRange -> m (Range (MultiLoc SourcePath))
toRangeSourcePath = toRangeWith toMultiSourcePath

fromSingle ::
     (MonadIO m, HasCallStack)
  => Core.CXTranslationUnit -> (path -> Text) -> SingleLoc path -> m Core.CXSourceLocation
fromSingle unit get SingleLoc{singleLocPath, singleLocLine, singleLocColumn} = do
     let path = get singleLocPath
     file <- Core.clang_getFile unit path
     Core.clang_getLocation
       unit
       file
       (fromIntegral singleLocLine)
       (fromIntegral singleLocColumn)

fromRange ::
     (MonadIO m, HasCallStack)
  => Core.CXTranslationUnit -> (path -> Text) -> Range (SingleLoc path) -> m Core.CXSourceRange
fromRange unit get Range{rangeStart, rangeEnd} = do
    rangeStart' <- fromSingle unit get rangeStart
    rangeEnd'   <- fromSingle unit get rangeEnd
    Core.clang_getRange rangeStart' rangeEnd'

{-------------------------------------------------------------------------------
  Get single location
-------------------------------------------------------------------------------}

clang_getExpansionLocation :: (MonadIO m, HasCallStack) => Core.CXSourceLocation -> m (SingleLoc RealPath)
clang_getExpansionLocation location =
    toSingleRealPath =<< Core.clang_getExpansionLocation location

clang_getPresumedLocation :: MonadIO m => Core.CXSourceLocation -> m PresumedLoc
clang_getPresumedLocation location =
    toPresumed <$> Core.clang_getPresumedLocation location

clang_getSpellingLocation :: (MonadIO m, HasCallStack) => Core.CXSourceLocation -> m (SingleLoc RealPath)
clang_getSpellingLocation location =
    toSingleRealPath =<< Core.clang_getSpellingLocation location

clang_getFileLocation :: (MonadIO m, HasCallStack) => Core.CXSourceLocation -> m (SingleLoc RealPath)
clang_getFileLocation location =
    toSingleRealPath =<< Core.clang_getFileLocation location

{-------------------------------------------------------------------------------
  Convenience wrappers for @CXSourceLocation@
-------------------------------------------------------------------------------}

-- | Retrieve the source location of the given diagnostic.
clang_getDiagnosticLocation :: MonadIO m => Core.CXDiagnostic -> m (MultiLoc SourcePath)
clang_getDiagnosticLocation diagnostic =
    toMultiSourcePath =<< Core.clang_getDiagnosticLocation diagnostic

-- | Retrieve the physical location of the source construct referenced by the
-- given cursor.
clang_getCursorLocation :: (MonadIO m, HasCallStack) => Core.CXCursor -> m (MultiLoc RealPath)
clang_getCursorLocation cursor =
    toMultiRealPath =<< Core.clang_getCursorLocation cursor

-- | Like 'clang_getCursorLocation', but only retrieve the expansion location
clang_getCursorLocation' :: (MonadIO m, HasCallStack) => Core.CXCursor -> m (SingleLoc RealPath)
clang_getCursorLocation' cursor =
    clang_getExpansionLocation =<< Core.clang_getCursorLocation cursor

-- | Retrieve the source location of the given token.
clang_getTokenLocation ::
     (MonadIO m, HasCallStack)
  => Core.CXTranslationUnit -> Core.CXToken -> m (MultiLoc RealPath)
clang_getTokenLocation unit token =
    toMultiRealPath =<< Core.clang_getTokenLocation unit token

{-------------------------------------------------------------------------------
  Convenience wrappers for @CXSourceRange@
-------------------------------------------------------------------------------}

-- | Retrieve a source range associated with the diagnostic.
clang_getDiagnosticRange ::
     MonadIO m
  => Core.CXDiagnostic -> CUInt -> m (Range (MultiLoc SourcePath))
clang_getDiagnosticRange diagnostic range =
    toRangeSourcePath =<< Core.clang_getDiagnosticRange diagnostic range

-- | Retrieve the replacement information for a given fix-it.
clang_getDiagnosticFixIt ::
     MonadIO m
  => Core.CXDiagnostic
  -> CUInt
  -> m (Range (MultiLoc SourcePath), Text)
clang_getDiagnosticFixIt diagnostic fixit = do
    (range, replacement) <- Core.clang_getDiagnosticFixIt diagnostic fixit
    (, replacement) <$> toRangeSourcePath range

-- | Retrieve a range for a piece that forms the cursors spelling name.
clang_Cursor_getSpellingNameRange ::
     (MonadIO m, HasCallStack)
  => Core.CXCursor
  -> CUInt
  -> CUInt
  -> m (Maybe (Range (MultiLoc RealPath)))
clang_Cursor_getSpellingNameRange cursor pieceIndex options = do
    mRange <- Core.clang_Cursor_getSpellingNameRange cursor pieceIndex options
    case mRange of
      Nothing    -> return Nothing
      Just range -> Just <$> toRangeWith toMultiRealPath range

-- | Retrieve the physical extent of the source construct referenced by the
-- given cursor.
clang_getCursorExtent :: (MonadIO m, HasCallStack) => Core.CXCursor -> m (Range (MultiLoc RealPath))
clang_getCursorExtent cursor =
    toRangeRealPath =<< Core.clang_getCursorExtent cursor

-- | Retrieve a source range that covers the given token.
clang_getTokenExtent ::
     (MonadIO m, HasCallStack)
  => Core.CXTranslationUnit
  -> Core.CXToken
  -> m (Range (MultiLoc RealPath))
clang_getTokenExtent unit token =
    toRangeRealPath =<< Core.clang_getTokenExtent unit token

{-------------------------------------------------------------------------------
  Exceptions
-------------------------------------------------------------------------------}

-- | Thrown by 'clang_getRealPath' when the file has no backing file on disk
data ClangRealPathException =
    ClangRealPathException SourcePath CallStack
  deriving stock (Show)
  deriving anyclass (Exception)

{-------------------------------------------------------------------------------
  Auxiliary
-------------------------------------------------------------------------------}

-- | Get the 'RealPath' for a 'Core.CXFile'
--
-- Precondition: the file must be on disk. Throws 'ClangRealPathException'
-- for virtual files.
clang_getRealPath :: (MonadIO m, HasCallStack) => Core.CXFile -> m RealPath
clang_getRealPath file = do
    path <- Core.clang_File_tryGetRealPathName file
    if Text.null path
      then do
        name <- SourcePath <$> Core.clang_getFileName file
        liftIO . throwIO $ ClangRealPathException name callStack
      else return (RealPath path)

-- | Try to get the 'RealPath' for a 'Core.CXFile'
--
-- Returns 'Nothing' for virtual/in-memory files.
clang_tryGetRealPath :: MonadIO m => Core.CXFile -> m (Maybe RealPath)
clang_tryGetRealPath file = do
    path <- Core.clang_File_tryGetRealPathName file
    return $ if Text.null path then Nothing else Just (RealPath path)

-- | Build a @SingleLoc RealPath@. Throws 'ClangRealPathException' for virtual
-- files.
toSingleRealPath ::
     (MonadIO m, HasCallStack)
  => (Core.CXFile, CUInt, CUInt, CUInt) -> m (SingleLoc RealPath)
toSingleRealPath (file, line, column, offset) = do
    realPath <- clang_getRealPath file
    return SingleLoc{
        singleLocPath   = realPath
      , singleLocLine   = fromIntegral line
      , singleLocColumn = fromIntegral column
      , singleLocOffset = fromIntegral offset
      }

-- | Build a @SingleLoc SourcePath@ via @clang_getFileName@.
-- Caller must ensure the 'Core.CXFile' is non-null.
toSingleSourcePath ::
     MonadIO m
  => (Core.CXFile, CUInt, CUInt, CUInt) -> m (SingleLoc SourcePath)
toSingleSourcePath (file, line, column, offset) = do
    path <- SourcePath <$> Core.clang_getFileName file
    return SingleLoc{
        singleLocPath   = path
      , singleLocLine   = fromIntegral line
      , singleLocColumn = fromIntegral column
      , singleLocOffset = fromIntegral offset
      }

toPresumed :: (Text, CUInt, CUInt) -> PresumedLoc
toPresumed (path, line, column) = PresumedLoc{
      presumedLocPath   = SourcePath path
    , presumedLocLine   = fromIntegral line
    , presumedLocColumn = fromIntegral column
    }

toRangeWith ::
     MonadIO m
  => (Core.CXSourceLocation -> m a)
  -> Core.CXSourceRange -> m (Range a)
toRangeWith f range =
    Range
      <$> (f =<< Core.clang_getRangeStart range)
      <*> (f =<< Core.clang_getRangeEnd   range)

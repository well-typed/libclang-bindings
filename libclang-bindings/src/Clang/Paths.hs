module Clang.Paths (
    -- * Source paths
    SourcePath(..)
  , getSourcePath
  , getSourcePathText

    -- * Real paths
  , RealPath(..)
  , getRealPath
  , getRealPathText
  , sourcePathToRealPath
  , realPathToSourcePath

    -- * C include directories
  , CIncludeDir(..)
  ) where

import Data.String
import Data.Text (Text)
import Data.Text qualified as Text

{-------------------------------------------------------------------------------
  Source paths
-------------------------------------------------------------------------------}

-- | Filesystem path of a source file, typically a C header
--
-- Wraps whatever path clang reports: for files on disk this is the canonical
-- path (from @clang_File_tryGetRealPathName@), for virtual files (unsaved
-- buffers, @#line@ directives) it is the clang-assigned name.
--
-- The format of the path is platform-dependent.
newtype SourcePath = SourcePath Text
  deriving newtype (Eq, IsString, Ord, Show)

-- | Get the 'FilePath' representation of a 'SourcePath'
getSourcePath :: SourcePath -> FilePath
getSourcePath = Text.unpack . getSourcePathText

-- | Get the 'Text' representation of a 'SourcePath'
getSourcePathText :: SourcePath -> Text
getSourcePathText (SourcePath path) = path

{-------------------------------------------------------------------------------
  Real paths
-------------------------------------------------------------------------------}

-- | Canonical absolute path of an on-disk source file
--
-- Obtained through @clang_File_tryGetRealPathName@.  Two 'RealPath' values
-- that refer to the same physical file are guaranteed to be equal, regardless
-- of the @#include@ spelling that reached the file.
--
-- The format of the path is platform-dependent.
newtype RealPath = RealPath Text
  deriving stock (Eq, Ord, Show)

-- | Get the 'FilePath' representation of a 'RealPath'
getRealPath :: RealPath -> FilePath
getRealPath = Text.unpack . getRealPathText

-- | Get the 'Text' representation of a 'RealPath'
getRealPathText :: RealPath -> Text
getRealPathText (RealPath path) = path

-- | Treat a 'SourcePath' as a 'RealPath'
--
-- This is a pure coercion. Only call it when the 'SourcePath' is known to
-- contain a canonical path (i.e. it originated from a real file, not a
-- virtual one).
sourcePathToRealPath :: SourcePath -> RealPath
sourcePathToRealPath (SourcePath t) = RealPath t

-- | Embed a 'RealPath' as a 'SourcePath'
realPathToSourcePath :: RealPath -> SourcePath
realPathToSourcePath (RealPath t) = SourcePath t

{-------------------------------------------------------------------------------
  C include directories
-------------------------------------------------------------------------------}

-- | C include directory
--
-- A /C include directory/ is a directory that contains C header files, and a
-- /C include search path/ is a list of C include directories that is used to
-- resolve headers.
--
-- The wrapped 'FilePath' may be absolute or relative to the current working
-- directory.  When an include directive is resolved using a relative
-- 'CIncludeDir', the resulting 'SourcePath' is also relative.
--
-- Examples:
--
-- * When using a C include search path that contains 'CIncludeDir'
--   @/usr/include@, @#include <stdint.h>@ may resolve to 'SourcePath'
--   @/usr/include/stdint.h@.
--
-- * When using a C include search path that contains 'CIncludeDir' @include@ (a
--   directory in the current working directory), @#include <foo.h>@ may resolve
--   to 'SourcePath' @include/foo.h@ (also relative to the current working
--   directory).
newtype CIncludeDir = CIncludeDir { getCIncludeDir :: FilePath }
  -- 'Show' instance valid due to 'IsString' instance
  deriving newtype (Eq, IsString, Ord, Show)

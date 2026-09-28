module Clang.Paths (
    -- * Source paths
    SourcePath(..)
  , getSourcePath
  , getSourcePathText

    -- * Real paths
  , RealPath(..)
  , getRealPath
  , getRealPathText
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

-- | Path of a source file as reported by @clang_getFileName@
--
-- For on-disk files this is typically the path used in the @#include@
-- directive. For virtual files (unsaved buffers, @#line@ directives)
-- it is the clang-assigned name. Platform-dependent format.
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

-- | Canonical absolute path of an on-disk file
--
-- Obtained via @clang_File_tryGetRealPathName@. Two 'RealPath' values
-- for the same physical file compare equal regardless of include spelling.
-- Platform-dependent format.
newtype RealPath = RealPath Text
  deriving stock (Eq, Ord, Show)

-- | Get the 'FilePath' representation of a 'RealPath'
getRealPath :: RealPath -> FilePath
getRealPath = Text.unpack . getRealPathText

-- | Get the 'Text' representation of a 'RealPath'
getRealPathText :: RealPath -> Text
getRealPathText (RealPath path) = path

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

{-# OPTIONS_GHC -Wno-orphans #-}

-- | Dealing with @CXString@
--
-- This has no exports: the Haskell representation of @CXString@ is 'Text'.
module Clang.Internal.CXString () where

import Control.Exception
import Data.Text (Text)
import Data.Text qualified as Text
import Foreign
import Foreign.C
import GHC.Ptr (Ptr (..))

import Clang.Internal.ByValue
import Clang.Internal.ConstPtr (ConstPtr (unConstPtr))
import Clang.LowLevel.Core.Instances ()
import Clang.LowLevel.Core.Structs
import Clang.LowLevel.FFI

{-------------------------------------------------------------------------------
  Translation to bytestrings

  TODO <https://github.com/well-typed/libclang-bindings/issues/70>

  We could consider trying to deduplicate.
-------------------------------------------------------------------------------}

-- | @libclang@ uses UTF-8 internally
instance Preallocate Text where
  type Writing Text = W CXString_

  preallocate :: (W CXString_ -> IO b) -> IO (Text, b)
  preallocate allocStr =
      bracket
          (preallocate allocStr)
          (clang_disposeString . fst) $ \(str, b) -> do
        cstr@(Ptr addr) <- clang_getCString str
        if cstr == nullPtr then
          return (Text.empty, b)
        else do
          let !t = Text.unpackCString# addr
          return (t, b)

{-------------------------------------------------------------------------------
  Low-level bindings

  <https://clang.llvm.org/doxygen/group__CINDEX__STRING.html>
-------------------------------------------------------------------------------}

-- | A character string.
--
-- The 'CXString' type is used to return strings from the interface when the
-- ownership of that string might differ from one call to the next. Use
-- 'clang_getCString' to retrieve the string data and, once finished with the
-- string data, call 'clang_disposeString' to free the string.
--
-- <https://clang.llvm.org/doxygen/structCXString.html>
newtype CXString = CXString (OnHaskellHeap CXString_)
  deriving newtype (LivesOnHaskellHeap, Preallocate)

-- | Retrieve the character data associated with the given string.
--
-- We use @capi@ together with 'ConstPtr' here to avoid a compiler warning
-- about qualifying the @const@-ness of @const char *@ (see "Clang.Internal.ConstPtr").
--
-- <https://clang.llvm.org/doxygen/group__CINDEX__STRING.html#gabe1284209a3cd35c92e61a31e9459fe7>
clang_getCString :: CXString -> IO CString
clang_getCString str = unConstPtr <$> onHaskellHeap str wrap_getCString

-- | Free the given string.
--
-- <https://clang.llvm.org/doxygen/group__CINDEX__STRING.html#gaeff715b329ded18188959fab3066048f>
clang_disposeString :: CXString -> IO ()
clang_disposeString str = onHaskellHeap str $ wrap_disposeString

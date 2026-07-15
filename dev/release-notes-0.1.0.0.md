## libclang-bindings 0.1.0.0

First non-alpha release of Haskell bindings to the LLVM/Clang `libclang` C API.

### Breaking changes
- Removed the `LLVM_CONFIG` configure variable — set `PATH` so the desired `llvm-config` is found instead.

### New features
- New `Clang.Discover` module with `getPaths` to locate the `clang` executable and builtin include directory.
- Compile-time `CLANG_VERSION` check to catch version mismatches (see `Clang.Version`).
- New `--with-so` configure option to work around Cabal linking issues on Linux.
- `foldTry` (and the `FoldException` type) returning a caught exception as a value, like `Control.Exception.try` (#47).
- New bindings: `clang_isBeforeInTranslationUnit` (Clang 20.1+, #53), `clang_Type_getOffsetOf` (#37), and `clang_disposeToken` (#42).

### Bug fixes
- Silence `-Wdeprecated-declarations` from `<clang-c/Index.h>` on Clang 21 at the system-header include sites, so deprecation warnings for APIs we call stay visible (#58).

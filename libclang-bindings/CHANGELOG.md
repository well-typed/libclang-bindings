# Revision history for libclang-bindings

## 0.1.0.0 -- 2026-07-14

### Breaking changes

* Removed `LLVM_CONFIG` configuration variable. Configure `PATH` so that the
  desired `llvm-config` is found instead.

### New features

* Add a binding for `clang_isBeforeInTranslationUnit`. This function is only
  available for Clang versions 20.1 and newer; see [PR-53][pr-53].
* Add a binding for the `clang_Type_getOffsetOf` function. See [PR #37][pr-37].
* Add a new `clang_disposeToken` function to free a single `CXToken`. This is a
  helper function alongside the existing `clang_disposeTokens` functions, which
  frees arrays of `CXToken`s. See [PR#42][pr-42].
* Add a new `foldTry` function that behaves like `foldWitHandler`, but it
  returns the caught exception as a value like `Control.Exception.try` would.
  The caught exception is represented using a new type called `FoldException`.
  See [PR #47][pr-47]
* Add a compile-time check of the `CLANG_VERSION` macro. See the
  `Clang.Version.checkUserClangVersion` documentation for details.
* Add `--with-so` option to the `configure` script, used to work around Cabal
  linking issues.
* Add the `Clang.Discover` module, providing `getPaths` to discover the `clang`
  executable and the builtin include directory.

### Minor changes

### Bug fixes

* Silence `-Wdeprecated-declarations` warnings emitted by `<clang-c/Index.h>`
  on Clang 21 at the system-header include sites only, so that deprecation
  warnings for libclang APIs we actually call remain visible. See
  [issue #58][issue-58].

[pr-37]: https://github.com/well-typed/libclang/pull/37
[pr-42]: https://github.com/well-typed/libclang/pull/42
[pr-47]: https://github.com/well-typed/libclang/pull/47
[pr-53]: https://github.com/well-typed/libclang/pull/53
[issue-58]: https://github.com/well-typed/libclang/issues/58

## 0.1.0-alpha -- 2026-02-06

* Release candidate.

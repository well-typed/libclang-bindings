# Revision history for libclang-bindings

## ?.?.?.? -- YYYY-mm-dd

### Breaking changes

* Add `CXType_PredefinedSugar` to `CXTypeKind`. LLVM/Clang 23 reports this kind
  for the predefined types `__size_t`, `__signed_size_t` and `__ptrdiff_t`;
  see [llvm/llvm-project#202209][llvm-202209].
* `SingleLoc`, `MultiLoc`, and `Token` are parameterized by path type
  (`SingleLoc path`, `MultiLoc path`, `Token path a`).
* `toMulti`/`toRange` renamed to `toMultiRealPath`/`toRangeRealPath`;
  new `toMultiSourcePath`/`toRangeSourcePath` for virtual files.
* Pretty-printing functions take `(path -> String)`.
* `clang_tokenize` takes a `CXSourceRange` instead of a `Range SingleLoc`, and
  passes it to `libclang` unchanged. Thereby we avoid usage of source ranges
  referring to in-memory files such as the Clang predefine buffer used by
  macros defined with `-D`, for which it used to throw. A range that starts
  inside a macro expansion is tokenized from the macro definition; see the
  documentation of `clang_tokenize`.
* Remove `fromSingle` and `fromRange`. They looked up the `CXFile` by path,
  which fails for locations in buffers without one.
* `RealPath`-producing functions carry `HasCallStack`.
* High-level location functions such as `clang_getCursorLocation` now throw
  `ClangRealPathException` for locations in virtual files, where 0.1.0.0
  returned a location. Use `toMultiSourcePath`/`toRangeSourcePath` for those.
  See [issue #84][issue-84].
* `Clang.HighLevel.Types` re-exports `RealPath` and `SourcePath`.

### New features

* Bind `clang_File_tryGetRealPathName` and `clang_File_isEqual`.
* Add `RealPath` newtype, `clang_getRealPath`/`clang_tryGetRealPath`,
  `getSourcePathText`, and `realPathToSourcePath`.
* Add `toMultiCXFile`: builds `MultiLoc CXFile`.
* `SingleLoc` and `MultiLoc` derive `Foldable` and `Traversable`.
* Bind `clang_hashCursor`. See [PR #81][pr-81].

### Minor changes

### Bug fixes

* `MultiLoc` no longer drops a presumed, spelling or file location that differs
  from the expansion location in only some of file, line and column. It used
  to drop, for example, the spelling location of a macro defined in the same
  file, and every presumed location set by a `#line` directive. See
  [issue #85][issue-85].

[pr-81]: https://github.com/well-typed/libclang-bindings/pull/81
[issue-84]: https://github.com/well-typed/libclang-bindings/issues/84
[issue-85]: https://github.com/well-typed/libclang-bindings/issues/85

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
[pr-81]: https://github.com/well-typed/libclang-bindings/pull/81
[llvm-202209]: https://github.com/llvm/llvm-project/pull/202209
[issue-58]: https://github.com/well-typed/libclang/issues/58
[hs-bindgen-2236]: https://github.com/well-typed/hs-bindgen/issues/2236

## 0.1.0-alpha -- 2026-02-06

* Release candidate.

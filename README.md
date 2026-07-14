# `libclang-bindings`

[![Build Status](https://github.com/well-typed/libclang-bindings/actions/workflows/haskell.yml/badge.svg)](https://github.com/well-typed/libclang-bindings/actions)
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-lightgray.svg)](https://github.com/well-typed/libclang-bindings/blob/main/LICENSE)

`libclang-bindings` is a [Haskell][] library that provides bindings for the
[LLVM/Clang][] `libclang` C API. It supports the [`hs-bindgen`][] project but
can be used independently.

> [!NOTE]
> This is an early release. C (and C preprocessor) code varies widely, so we
> welcome feedback. If something breaks, please check the [issues][] to see if
> it is already known, and open an issue if not.

[Haskell]: https://www.haskell.org/
[issues]: https://github.com/well-typed/libclang-bindings/issues
[LLVM/Clang]: https://github.com/llvm/llvm-project
[`hs-bindgen`]: https://github.com/well-typed/hs-bindgen

## Documentation

* [`libclang-bindings` manual](manual/README.md)

## Packages in this repository

* [`libclang-bootstrap`](libclang-bootstrap), a program used to generate C
  wrapper functions and Haskell foreign import declarations for a subset of the
  `libclang` C API
* [`libclang-bindings`](libclang-bindings), a library that provides bindings for
  the LLVM/Clang `libclang` C API

## Contribution

Our thanks go to those who have contributed to this project with development,
bug reports, feature requests, blog posts, etc. We list
[contributors](https://github.com/well-typed/hs-bindgen#contributors)
in the `hs-bindgen` README.

Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for information about
contributing to this project.

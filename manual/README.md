# `libclang-bindings` manual

`libclang-bindings` is a [Haskell][] library that provides bindings for the
[LLVM/Clang][] `libclang` C API. It supports the [`hs-bindgen`][] project but
can be used independently.

* [Requirements][t:requirements]
    * [LLVM/Clang][t:llvm-clang]
    * [Autoconf][t:autoconf]
* [Configuration][t:configuration]
    * [Using `llvm-config`][t:using-llvm-config]
    * [Using `LLVM_PATH`][t:using-llvm-path]
    * [Linking overview][t:linking-overview]
    * [Cabal store cache issue][t:cabal-store-cache-issue]
    * [Cabal dependency linking issue][t:cabal-dependency-linking-issue]
* [Usage][t:usage]
* [Development][t:development]
    * [Bootstrapping][t:bootstrapping]
    * [Regenerating the configure script][t:regenerating-the-configure-script]
    * [Building][t:building]
    * [Testing][t:testing]

## Requirements
[t:requirements]: #requirements

This library works with [GHC][] and [Cabal][], on Linux, Nix, macOS, and
Windows.

### LLVM/Clang
[t:llvm-clang]: #llvmclang

[LLVM/Clang][] headers, libraries, and executables are required.

* **Linux**: Install LLVM/Clang using your distribution package manager or from
  an official [LLVM/Clang release][]. Ubuntu example:

    ```
    $ sudo apt install clang
    ```

* **Nix**: See the [`libclang-bindings.nix`][] derivation in the
  [`hs-bindgen`][] project as an example of how to configure the LLVM/Clang
  dependency.

* **macOS**: Install LLVM/Clang from an official [LLVM/Clang release][].

  LLVM/Clang installed using [Homebrew][] *may* work, but we have not tested it.

  The LLVM/Clang installed with Xcode *may* work, but we have not tested it.

* **Windows**: LLVM/Clang is installed with recent versions of GHC.

  LLVM/Clang installed using [MSYS2][] *may* work, but we have not tested it.

  LLVM/Clang versions installed from official releases or with Visual Studio
  target MSVC, which is not supported by GHC, and are therefore not suitable.

### Autoconf
[t:autoconf]: #autoconf

[Autoconf][] is only needed if you are developing `libclang-bindings` itself and
need to change something in the configure script.

* **Linux**: Install Autoconf using your distribution package manager. Ubuntu
  example:

    ```
    $ sudo apt install autoconf
    ```

* **Nix**: Use the `autoconf` package from `nixpkgs`.

* **macOS**: Install Autoconf using [Homebrew][]. Example:

    ```
    $ brew install autoconf
    ```

* **Windows**: Install Autoconf into your [MSYS2][] environment. Example:

    ```
    $ pacman -S autoconf-wrapper
    ```

## Configuration
[t:configuration]: #configuration

The `libclang-bindings` library is configured using an Autoconf configure
script, which determines which `libclang` shared library is linked.

### Using `llvm-config`
[t:using-llvm-config]: #using-llvm-config

The `llvm-config` program, generally included in LLVM/Clang installations, is
used to configure software builds to use a specific LLVM/Clang installation.
The `libclang-bindings` configure script uses it to determine the include and
library directories. If you have more than one version of LLVM/Clang installed,
you can configure your `PATH` to ensure that the `llvm-config` for the version
that you want to use is found.

> [!NOTE]
> Some platforms provide versioned executables of `llvm-config` (e.g., Fedora
> with `clangNN-devel` provides `llvm-config-NN`). Ensure an unversioned
> executable is available (e.g., by installing `clang-devel`, or by linking
> `llvm-config-NN` to `llvm-config` on Fedora).

### Using `LLVM_PATH`
[t:using-llvm-path]: #using-llvm_path

If `llvm-config` is not available, you can instead configure the `LLVM_PATH`
environment variable to determine the include (`$LLVM_PATH/include`), library
(`$LLVM_PATH/lib`), and executable (`$LLVM_PATH/bin`) directories. If you use
this environment variable, it should remain set while using `libclang-bindings`,
not just during configuration.

> [!NOTE]
> `llvm-config` is available in all development environments that we test with.

### Linking overview
[t:linking-overview]: #linking-overview

There are a few issues related to linking, described below, so it is worthwhile
to describe how linking is done. The configure script determines the library
name and library directory to use when linking. The library name, passed to the
linker using a `-l` option, is `clang` by default. The library directory,
passed to the linker using a `-L` option, is determined using `llvm-config` or
`LLVM_PATH` as described above.

#### Linux/macOS

The linker finds the `clang` library by searching its library path for the
shared library: `libclang.so` on Linux or `libclang.dylib` on macOS. When there
are multiple versions of LLVM/Clang available, the order of directories in the
library path determines which one is found and linked.

Typically, this file is a symbolic link to the actual shared library file with a
name that specifies the full version. The shared library has an embedded string
(`SONAME` on Linux, "install name" on macOS) that instructs the linker to link
against a *different* file instead. Current versions of LLVM/Clang are
configured so that the major/minor version is specified, omitting the patch
version.

| File                                      | Link To              | `SONAME`           |
| :---                                      | :---                 | :---               |
| `/usr/lib/llvm-21/lib/libclang.so`        | `libclang.so.21.1.8` |                    |
| `/usr/lib/llvm-21/lib/libclang.so.21.1.8` |                      | `libclang.so.21.1` |
| `/usr/lib/llvm-21/lib/libclang.so.21.1`   | `libclang.so.21.1.8` |                    |

In this example, shared library `libclang.so.21.1` is linked. If
LLVM/Clang 21.1 is upgraded to a new patch version (such as `21.1.9`),
`libclang-bindings` would continue to work, taking advantages of any
bug/security fixes in the patch release.

Just the filename is linked, *not* the absolute path. At runtime, the loader
must find the shared library (`libclang.so.21.1`) in the loader library path.
Since the major/minor version is specified, it should always load a compatible
version.

#### Windows

The `clang` shared library on Windows is named `LIBCLANG.DLL`. The filename
does not specify a version.

At runtime, the loader must find `LIBCLANG.DLL`, and this is generally done by
searching the `PATH`. (This is the same `PATH` used to search for executables.)
Since no version is specified, it may load an incompatible version if `PATH` is
not configured correctly.

### Cabal store cache issue
[t:cabal-store-cache-issue]: #cabal-store-cache-issue

When the `libclang-bindings` library is built, it is linked to a `libclang`
shared library as described above. The built library is cached in the Cabal
store, so that it can be used by any number of projects. Cabal does not
consider such system dependencies to determine which cached package should be
used or if a new build is needed, however, which can lead to problems.

#### LLVM/Clang upgrade issue

On Linux and macOS, links to a `libclang` shared library generally specify the
major and minor version. If an upgrade replaces an older installation with a
new installation that has the same major and minor version, but a different
patch version, then the link in the cached `libclang-bindings` build is
generally not broken. The new version should still work without having to
rebuild.

If an upgrade installs a new version that has a different major/minor version
and removes the previous installation, however, then the link in the cached
`libclang-bindings` build is broken. In this case, the loader fails at runtime
with an error like the following, preventing the executable from running at all.

```
libclang.so.21.1: cannot open shared object file: No such file or directory
```

Cabal does not detect such issues. Attempting to rebuild the package using the
new version of LLVM/Clang does not succeed because a build is already cached in
the Cabal store.

#### Version mismatch issue

On Windows, links to a `libclang` shared library do not specify the version at
all. If LLVM/Clang is upgraded to a new version that has a different
major/minor version, or even if `PATH` is just reconfigured to point to a
LLVM/Clang installation with a different major/minor version, the loaded
`libclang` shared library does not match the version that `libclang-bindings`
was built with.

The `Clang.Version` module of `libclang-bindings` provides an API for querying
and comparing the compile-time and runtime versions. It can be used to check
for version mismatches. For example, `hs-bindgen` does this and displays a
warning with the major/minor versions do not match.

Cabal cannot use the LLVM/Clang version to determine which cached package should
be used or if a new build is needed.

#### Workarounds

Cabal does not provide an easy way to resolve this issue. Note that this is an
issue for any Haskell package that links to system libraries that do not have
`pkg-config` support (in which case Cabal can track dependency versions). It is
particularly problematic with LLVM/Clang, however, because LLVM/Clang has
frequent releases.

One way to force Cabal to rebuild a package to match your current environment is
to clear the cache. You can determine your Cabal store directory by running
`cabal path --store-dir`. The Cabal store has separate caches for each version
of GHC. Recursively remove a GHC directory to clear the cache for that version.
Note that deleting just a package directory is not advised because it can break
the package database. The downside to clearing your cache is that doing so may
result in time-consuming recompilation of many other packages.

Since we understand that clearing the cache might not be desirable, we offer a
bespoke workaround, in the form of a compile-time setting specifying the
LLVM/Clang version. This forces Cabal to distinguish `libclang-bindings` builds
that link to different versions, forcing a new build if one for the specified
version is not already in the Cabal store. Do this by adding the following to a
`cabal.project.local` file for your project, with the desired version.

```
package libclang-bindings
  ghc-options: -optc=-DCLANG_VERSION=22.1
```

When configured like this, `libclang-bindings` confirms that the version matches
the version of LLVM/Clang used at compile time. The following checks are
supported:

* `MAJOR` to just check the major version (example: `22`)
* `MAJOR.MINOR` to check the major and minor versions (example: `22.1`)
* `MAJOR.MINOR.PATCH` to check the major, minor, and patch versions
  (example: `22.1.3`)

Note that `ghc-options` specifying an `-optc` option must be used, as
`cc-options` is *not* sufficient.

This issue affects any project that uses `libclang-bindings`, even if it is used
as a transitive dependency.

### Cabal dependency linking issue
[t:cabal-dependency-linking-issue]: #cabal-dependency-linking-issue

When building a library or executable, Cabal links libraries needed by
transitive dependencies. A library or executable that (directly or indirectly)
depends on `libclang-bindings` is therefore also linked to `libclang`. There
are cases where Cabal links to the wrong `libclang` shared library when multiple
versions are available.

#### Cabal issue

The linking options configured for `libclang-bindings` are stored in the package
database, and they are used again when building a library or executable that
depends on `libclang-bindings`. The linker options for other dependencies are
also used, however, and the ordering of those options may result in a shared
library for a *different* version of LLVM/Clang being linked. The order of
those options is determined by Cabal and cannot be configured. This results in
*multiple* versions of `libclang` being linked: the desired version via
`libclang-bindings` and an incorrect version that is linked directly.

For example, consider the case where the `PATH` environment variable is
configured to use LLVM/Clang 21.1 on a system where LLVM/Clang 22.1 is the
default. The configure script uses `llvm-config` to determine that library
directory `/usr/lib/llvm-21/lib` should be used. The `libclang-bindings`
library is linked with options `-lclang` and `-L/usr/lib/llvm-21/lib`, and the
linker resolves `libclang.so` to shared library `libclang.so.21.1` as described
above.

A separate executable that depends on `libclang-bindings` may also have a
dependency with library directory `/usr/lib`. If the `-L/usr/lib` option is
passed before the `-L/usr/lib/llvm-21/lib` option, then `libclang.so` is
resolved differently:

| File                          | Link To              | `SONAME`           |
| :---                          | :---                 | :---               |
| `/usr/lib/libclang.so`        | `libclang.so.22.1.4` |                    |
| `/usr/lib/libclang.so.22.1.4` |                      | `libclang.so.22.1` |
| `/usr/lib/libclang.so.22.1`   | `libclang.so.22.1.4` |                    |

The executable is linked to `libclang.so.22.1` directly as well as
`libclang.so.21.1` via `libclang-bindings`.

#### Workaround (Linux)

The workaround is to use a symbolic link that has a unique name so that it can
be unambiguously resolved, independent of any other linker flags. To support
this workflow on Linux, the `libclang-bindings` configure script has a
`--with-so` option to specify the absolute path to such a symbolic link. The
directory part is used as the library directory, and the filename is used to
determine the library name (by stripping the `lib` prefix and `.so` suffix).

For example, you could create a symbolic link in directory `~/.cabal/sys-libs`:

| File                                                   | Link To                                 |
| :---                                                   | :---                                    |
| `/home/me/.cabal/sys-libs/libclang_workaround_21_1.so` | `/usr/lib/llvm-21/lib/libclang.so.21.1` |

Use of this symbolic link is configured in a `cabal.project.local` file as
follows:

```
package libclang-bindings
  configure-options: --with-so=/home/me/.cabal/sys-libs/libclang_workaround_21_1.so
```

The configure script sets library name `clang_workaround_21_1` and library
directory `/home/me/.cabal/sys-libs`. The shared library for the correct
version of LLVM/Clang is always linked because `clang_workaround_21_1` always
resolves via the configured symbolic link due to the unique name. A preceding
`-L/usr/lib` option is no longer problematic.

> [!NOTE]
> Such symbolic links must be persistent. The library directory is cached in
> the package database and used whenever a package that (transitively) depends
> on `libclang-bindings` is (re)built.

##### Upgrading LLVM/Clang

If you upgrade LLVM/Clang (other than patch releases), you must reconfigure and
rebuild all packages that depend on it. When using the `--with-so` option, you
must also create a new symbolic link to the new shared library.

> [!NOTE]
> `configure-options` are included in the Cabal store hash for the package, so
> changing the `--with-so` configuration is sufficient to let Cabal know that a
> new build is needed.

#### Other OSes

This issue is theoretically possible on macOS, but perhaps it will never happen
in practice because macOS does not use a package manager to manage system
dependencies. If you run into this in macOS, please [open an issue][]. We can
implement a `--with-dylib` option to work around the issue on macOS in a similar
way that we work around it on Linux.

This issue should never happen on Windows since `LIBCLANG.DLL` does not specify
a version at all.

## Usage
[t:usage]: #usage

Using `libclang-bindings` as a library should be straightforward as long as
[configuration][t:configuration] is done correctly. Simply configure the
library as a dependency and use it.

The environment when using `libclang-bindings` must be consistent with the
environment used for building the package.

* The `PATH` must resolve the same LLVM/Clang executables (and `.DLL` files on
  Windows) as when the library was built, modulo patch upgrades.
* If `LLVM_PATH` is used when building, it must also be set when using the
  library.

`cabal.project.local` configuration used to work around Cabal issues is required
for any project that (directly or indirectly) uses `libclang-bindings`.

## Development
[t:development]: #development

### Bootstrapping
[t:bootstrapping]: #bootstrapping

The `libclang-bootstrap` package is used to generate C wrapper functions and
Haskell foreign import declarations for a subset of the `libclang` C API. The
generated bindings are committed to the repository, so you do *not* need to
bootstrap unless you make changes to those bindings. If you do make such
changes, simply run the bootstrap program as follows.

```
$ cabal run libclang-bootstrap
```

### Regenerating the configure script
[t:regenerating-the-configure-script]: #regenerating-the-configure-script

The `libclang-bindings` package is configured using an [Autoconf][t:autoconf]
configure script. This script is committed to the repository, so you do *not*
need to regenerate it unless you make changes to the configuration logic. If
you do make such changes, regenerate the configure script as follows.

```
$ autoreconf -i libclang-bindings
```

### Building
[t:building]: #building

You can build `libclang-bindings` as follows. This runs the configure script
and builds the library.

```
$ cabal build all
```

### Testing
[t:testing]: #testing

You can test `libclang-bindings` as follows.

```
$ cabal test all
```

<!-- sources and references -->

[Autoconf]: https://www.gnu.org/software/autoconf/
[Cabal]: https://www.haskell.org/cabal/
[GHC]: https://www.haskell.org/ghc/
[Haskell]: https://www.haskell.org/
[Homebrew]: https://brew.sh/
[`hs-bindgen`]: https://github.com/well-typed/hs-bindgen
[`libclang-bindings.nix`]: https://github.com/well-typed/hs-bindgen/blob/main/nix/libclang-bindings.nix
[LLVM/Clang]: https://github.com/llvm/llvm-project
[LLVM/Clang release]: https://github.com/llvm/llvm-project/releases
[MSYS2]: https://www.msys2.org/
[open an issue]: https://github.com/well-typed/libclang-bindings/issues/new

# `libclang-bindings` Release Process

## Prerequisites

* [ ] Changelog checks (`CHANGELOG.md`):
  * Check that all user-facing changes have been recorded.
  * Check that each changelog entry is in the correct category.
  * Check that each changelog entry links to a PR, if applicable.
  * Add or update the changelog's section header with the package version that
    is going to be released, and the date of the release. The version should be
    picked based on our package versioning policy.

* [ ] Cabal project file checks (`cabal.project*`):
  * Update the `index-state` in the `cabal.project` file to the current
    date-time, or the closest valid date-time to the current date-time, so that
    CI builds and tests the libraries with the newest versions of dependencies.

* [ ] Decide on new version number (`MAJOR.MAJOR.MINOR.PATCH`): Releases follow
  the [Haskell Package Versioning Policy](https://pvp.haskell.org/). We use
  version numbers consisting of 3 parts, like `A.B.C.D`.
  * `A.B` is the *major* version number. A bump indicates a breaking change.
  * `C` is the *minor* version number. A bump indicates a non-breaking change.
  * `D` is the *patch* version number. A bump indicating small changes or minor
    fixes not affecting users directly.

* Tag name: `release-${VERSION}`

## Preparation

* [ ] Set the version in `libclang-bindings.cabal`

* [ ] Set the `source-repository this` tag in `libclang-bindings.cabal`

* [ ] Set the version in `libclang-bindings/configure.ac`

* [ ] Set the version in `libclang-bootstrap.cabal`

* [ ] Reconfigure

    ```
    $ path/to/autoconf-2.71/bin/autoreconf -i
    ```

* [ ] Update the `CHANGELOG`
    * [ ] Set the version number
    * [ ] Set the release date (UTC)

* [ ] Prepare release notes

## GitHub

* [ ] Ensure the changes above land on `main`

* [ ] Tag the release

    ```
    $ git tag "${TAG}" -m "Release ${VERSION}"
    ```

* [ ] Push the tag

    ```
    $ git push origin "${TAG}"
    ```

* [ ] [Create a new GitHub release](https://github.com/well-typed/libclang-bindings/releases/new)
    * [ ] Select tag
    * [ ] Target: `main`
    * [ ] Release title: `Release ${VERSION}`
    * [ ] Release notes: (paste release notes, formatted for GitHub Markdown)
    * [ ] Publish release

## Hackage

* [ ] Run `cabal check`

TBD

## Preparation for next release

* [ ] Update the `CHANGELOG`, adding a new section at top

        ```markdown
        ## ?.?.?.? -- YYYY-mm-dd

        ### Breaking changes

        ### New features

        ### Minor changes

        ### Bug fixes
        ```

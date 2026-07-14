# Contributing

## Code style

There is no strict code style, but try to keep the code style consistent
throughout the repository and favour readability. Code should be well-documented
and well-tested.

## Formatting

We use `stylish-haskell` to format Haskell files, and we use `cabal-fmt` to
format `*.cabal` files. See the helpful scripts in the [scripts
folder](./scripts/), and the [`stylish-haskell` configuration
file](./.stylish-haskell.yaml).

To perform a pre-commit code formatting pass, run one of the following:

```
./scripts/ci/run-cabal-fmt.sh
./scripts/ci/run-stylish-haskell.sh
```

## Pull requests

The following are requirements for merging a PR into `main`:
* Each commit should be small and should preferably address one thing. Commit
  messages should be useful.
* Document and test your changes.
* The PR should have a useful description, and it should link issues that it
  resolves (if any).
* Changes introduced by the PR should be recorded in the relevant changelog
  files. Ideally, each changelog entry should link to the PR that introduced the
  changes, and it should be placed in the relevant category (e.g., breaking
  changes, new features).
* PRs should not bundle many unrelated changes.
* The PR should pass all CI checks.

## Releases

To publish a release, follow [the release process](./dev/release-process.md).

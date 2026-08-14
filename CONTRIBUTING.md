# Contributing

Thanks for your interest in improving `gmrtd-ios`.

## Getting set up

- Xcode 16+ (Swift 5.9 toolchain)
- A physical iPhone with NFC to exercise real reads — the Simulator has no NFC hardware, so `MRTDReader`'s NFC path can't be tested there. Everything else (MRZ locate/validate, sample-document round-trip, verification from CBOR) runs fine in Simulator/CI.

```sh
git clone git@github.com:gmrtd/gmrtd-ios.git
cd gmrtd-ios
xcodebuild test -scheme GmrtdKit -destination 'platform=iOS Simulator,name=iPhone 16'
```

This is the same command CI runs (`.github/workflows/ci.yml`). Plain `swift build`/`swift test` won't work — `GmrtdKit`'s binary target (`Gmrtd.xcframework`) is iOS-only, so the package has to be built against an iOS Simulator destination via `xcodebuild`, not the host Mac.

## Making changes

- Keep `GmrtdKit` a thin, well-documented Swift wrapper around the `Gmrtd` binary target — logic that belongs in the underlying MRTD-reading library should go in [gmrtd](https://github.com/gmrtd/gmrtd) itself, not be reimplemented here.
- Every call into `Gmrtd` must go through `GmrtdGoRuntime.serialized` (see its doc comment in `Sources/GmrtdKit/GmrtdGoRuntime.swift`) — the bundled Go runtime isn't safe for concurrent entry from independent call sites, even ones that share no Swift-level state.
- Add or update tests in `Tests/GmrtdKitTests` for any behavior change. `sustainedConcurrentLoadAcrossEntryPointsDoesNotCrashTheGoRuntime` exists specifically to catch a regression of the point above — if you add a new entry point into `Gmrtd`, consider whether it needs coverage there too.
- Don't hand-edit the version literals in `Package.swift` (`gmrtdCoreVersion`/`gmrtdCoreChecksum`) or `Sources/GmrtdKit/VersionInfo.swift` (`gmrtdKitVersionLiteral`) — both are bumped automatically (by the gmrtd-release-tracking job and release-please, respectively) and rely on their exact `let name = "value"` shape to be located by regex.

## Commits and pull requests

- PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `fix: ...`, `feat: ...`, `chore: ...`) — this is enforced by CI (`.github/workflows/pr-title.yml`) and drives automated release notes/versioning via [release-please](https://github.com/googleapis/release-please).
- Keep PRs focused; a bug fix doesn't need to carry along unrelated refactors.
- Make sure `xcodebuild test` passes locally before opening a PR.

## Reporting bugs / requesting features

Open a GitHub issue. For anything that reads like a security vulnerability rather than a regular bug, please follow [SECURITY.md](SECURITY.md) instead of filing a public issue.

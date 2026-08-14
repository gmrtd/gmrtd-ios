# Security Policy

`gmrtd-ios` reads and verifies electronic travel documents (ePassports, eID cards), so vulnerabilities here can have real privacy/security impact for end users. Please report them responsibly.

## Reporting a vulnerability

Use GitHub's private reporting for this repository: **Security → Report a vulnerability** (or go directly to [github.com/gmrtd/gmrtd-ios/security/advisories/new](https://github.com/gmrtd/gmrtd-ios/security/advisories/new)). This opens a private advisory visible only to maintainers until a fix is ready — please don't open a public issue for a suspected vulnerability.

Include, as applicable:

- A description of the issue and its potential impact (e.g. data exposure, authentication bypass, relay-attack exposure)
- Steps to reproduce, or a minimal proof of concept
- The `GmrtdKit` version (`GmrtdKitVersionInfo.kit`) and `GmrtdCore` version (`GmrtdKitVersionInfo.core`) you tested against
- Whether the issue is in this Swift wrapper or in the underlying [gmrtd](https://github.com/gmrtd/gmrtd) Go library it bundles — if you're not sure, report here and we'll help route it

## Scope

This repository covers the Swift/CoreNFC integration layer: NFC session handling, the `MRTDReader`/`DocumentJsonRegenerator` APIs, MRZ locating/validation, and how this package drives the bundled `Gmrtd.xcframework`. Issues in the underlying cryptographic/protocol implementation (PACE, BAC, chip/passive/active authentication, ASN.1/CBOR parsing, CSCA trust chain validation) may belong to [gmrtd](https://github.com/gmrtd/gmrtd) instead — you're welcome to report those there directly, or here if you'd rather we triage and forward.

## Note on Active Authentication challenges

If you're reporting a relay-attack-style issue, please check first whether it's about the caller-supplied `aaChallenge` path (`MRTDReadOptions.aaChallenge` / `DocumentJsonRegenerator.regenerate(aaChallenge:)`) or the locally-generated fallback used when no challenge is supplied — the latter is documented as providing no protection against replay to an independent verifier by design (see the README's Security notes section), not as a bug.

## Supported versions

This package tracks a single `main` branch with automated releases via release-please; security fixes are released against the latest version rather than backported to older tags. Please upgrade to the latest release before reporting, if practical.

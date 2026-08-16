# gmrtd-ios

[![CI](https://github.com/gmrtd/gmrtd-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/gmrtd/gmrtd-ios/actions/workflows/ci.yml)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Official Swift Package for [GMRTD](https://github.com/gmrtd/gmrtd), providing a native iOS SDK for reading and verifying ICAO 9303 electronic travel documents (ePassports and eID cards) over NFC.

`GmrtdKit` drives a `CoreNFC` session end-to-end — polling, PACE/BAC access control, chip/passive/active authentication, and data group extraction — via a bundled `Gmrtd.xcframework` built from the [gmrtd](https://github.com/gmrtd/gmrtd) Go library.

## Requirements

- iOS 16+
- Xcode 16+ (Swift 5.9 toolchain)
- A physical iPhone with NFC (Simulator has no NFC hardware, so reads can't be tested there)
- An Apple Developer account with the NFC Tag Reading capability enabled for your App ID

## Installation

Add the package via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/gmrtd/gmrtd-ios.git", from: "0.1.0")
]
```

Or in Xcode: **File → Add Package Dependencies…** and enter `https://github.com/gmrtd/gmrtd-ios.git`.

## Host app setup

GmrtdKit starts an `NFCTagReaderSession`, but the entitlement and Info.plist keys that make that possible have to live in *your* app target — a package can't supply them for you:

1. Enable the **Near Field Communication Tag Reading** capability under **Signing & Capabilities**.
2. Add `NFCReaderUsageDescription` to your `Info.plist` (the reason shown to the user before the NFC sheet appears).
3. Add the ISO 7816 select identifiers your app needs to your `Info.plist`, e.g.:

```xml
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
</array>
```

Skipping any of these results in `NFCTagReaderSession.readingAvailable` being `false`, or the session failing to detect the chip.

## Quick start

```swift
import GmrtdKit

let reader = MRTDReader()

reader.onStatus = { status in
    print(status.defaultMessage) // e.g. "Authenticating (PACE)…"
}
reader.onChipConnected = { aid in
    // fire haptics / start a progress indicator
}

let credential = MRTDCredential.mrz(mrzString) // or .can("123456") for eID cards

reader.read(credential: credential) { result in
    switch result {
    case .success(let readResult):
        // readResult.summary, readResult.cborData
        break
    case .failure(let error):
        // MRTDReadError: .notDetected, .interrupted, .unsupported, .invalidAAChallenge
        print(error.underlying ?? error)
    }
}
```

`read(credential:options:completion:)` must be called from the main thread; `reader.cancel()` is safe to call from any thread (e.g. a caller-side watchdog timer).

`MRTDReadOptions` lets you skip PACE or image data groups, raise the max APDU length for extended-length-capable chips, and supply an Active Authentication challenge (see [Security notes](#security-notes) below).

### Locating and validating an MRZ (e.g. from OCR)

```swift
let result = locateMRZ(in: ocrLines) // tries TD3, TD1, then TD2
if let mrz = result.mrz {
    reader.read(credential: .mrz(mrz)) { ... }
}

isValidMRZ(candidateString) // character + check-digit validation, no chip access
```

### Re-verifying a previously read document

`MRTDReadResult.cborData` is a self-contained, verifiable snapshot of the read. Persist it, and later reconstruct the summary/technical JSON without a fresh NFC read:

```swift
let result = DocumentJsonRegenerator.regenerate(fromCbor: savedCborData)
switch result {
case .success(let doc):
    print(doc.summary, doc.technicalJson)
case .failure(let error):
    // .missingCbor, .verifierUnavailable, .verificationFailed, .invalidUtf8, .summaryDecodingFailed
    break
}
```

### Preloading the CSCA trust anchor pool

Verifying document signatures needs the CSCA certificate pool, which is loaded lazily on first use. To keep that cost off the critical path of a live NFC read, preload it once at app startup, off the main thread:

```swift
DispatchQueue.global(qos: .utility).async {
    try? CscaCertPool.preload()
}
```

## Security notes

`MRTDReadOptions.aaChallenge` / `DocumentJsonRegenerator.regenerate(aaChallenge:)` let you bind a read to an Active Authentication challenge (RND.IFD). **For real relay-attack protection, that challenge must be issued by whoever will verify the evidence** — typically your backend, freshly generated per verification request — not generated on the reading device. If you leave `aaChallenge` unset, GmrtdKit generates its own random challenge locally; that's enough to bind a read to its own later on-device re-verification, but a self-generated challenge proves nothing to an independent third-party verifier, since nothing stops the same app from choosing a challenge to match evidence it already captured.

## Apps using GmrtdKit

Projects using GmrtdKit to read and verify MRTDs in production:

| App | App Store |
|---|---|
| **[Inspekt.ID](https://apps.apple.com/us/app/inspekt-id/id6794529798)** | <a href="https://apps.apple.com/us/app/inspekt-id/id6794529798"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/c5/0b/24/c50b2463-5306-b7b1-c3fe-af1bf9ce11bb/AppIcon-1x_U007ephone-0-1-85-220-0.png/540x540bb.jpg" alt="Inspekt.ID" width="100" height="100" /></a> |

Using GmrtdKit in your app? Open a PR to add it here.

## Contributors

<a href="https://github.com/gmrtd/gmrtd-ios/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=gmrtd/gmrtd-ios" alt="Contributors to gmrtd-ios" />
</a>

See [CONTRIBUTING.md](CONTRIBUTING.md) to get involved.

## License

MIT — see [LICENSE](LICENSE).

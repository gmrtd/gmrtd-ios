# Changelog

## [1.4.5](https://github.com/gmrtd/gmrtd-ios/compare/v1.4.4...v1.4.5) (2026-11-27)


### Bug Fixes

* bump gmrtd core to v1.11.1 ([#72](https://github.com/gmrtd/gmrtd-ios/issues/72)) ([0afd4de](https://github.com/gmrtd/gmrtd-ios/commit/0afd4dee8ff23319422e633fb27e094a50435c5c))

## [1.4.4](https://github.com/gmrtd/gmrtd-ios/compare/v1.4.3...v1.4.4) (2026-11-26)


### Bug Fixes

* bump gmrtd core to v1.11.0 ([#70](https://github.com/gmrtd/gmrtd-ios/issues/70)) ([bffce21](https://github.com/gmrtd/gmrtd-ios/commit/bffce217745c3dc82b8a186f5d7119b64b6a1e33))

## [1.4.3](https://github.com/gmrtd/gmrtd-ios/compare/v1.4.2...v1.4.3) (2026-11-26)


### Bug Fixes

* bump gmrtd core to v1.10.3 ([#67](https://github.com/gmrtd/gmrtd-ios/issues/67)) ([cf68cc7](https://github.com/gmrtd/gmrtd-ios/commit/cf68cc719839ae7754c9d6f1828f16e5c833b41a))

## [1.4.2](https://github.com/gmrtd/gmrtd-ios/compare/v1.4.1...v1.4.2) (2026-11-26)


### Bug Fixes

* bump gmrtd core to v1.10.2 ([#63](https://github.com/gmrtd/gmrtd-ios/issues/63)) ([5c0d88f](https://github.com/gmrtd/gmrtd-ios/commit/5c0d88f065c54fb038493980ffd7439f3f8ebb55))

## [1.4.1](https://github.com/gmrtd/gmrtd-ios/compare/v1.4.0...v1.4.1) (2026-11-25)


### Bug Fixes

* bump gmrtd core to v1.10.1 ([#61](https://github.com/gmrtd/gmrtd-ios/issues/61)) ([fbe6626](https://github.com/gmrtd/gmrtd-ios/commit/fbe6626127cfc3a057eb898f3f82e66bd4a9060c))

## [1.4.0](https://github.com/gmrtd/gmrtd-ios/compare/v1.3.1...v1.4.0) (2026-11-21)


### ⚠ Behaviour change

* With gmrtd 1.10.0, a read with a wrong MRZ or CAN now fails with `.accessDenied` instead of succeeding with no data read. Apps that `switch` exhaustively over `MRTDReadError` need to handle the new `.accessDenied` and `.credentialNotUsable` cases.

### Features

* allow localizing NFC sheet messages ([#57](https://github.com/gmrtd/gmrtd-ios/issues/57)) ([cdabdd3](https://github.com/gmrtd/gmrtd-ios/commit/cdabdd345b29d8f9bbe6b80a338a66fc6a046eff))
* classify wrong MRZ/CAN and unusable credentials via gmrtd's LastReadError ([#60](https://github.com/gmrtd/gmrtd-ios/issues/60)) ([cc31de2](https://github.com/gmrtd/gmrtd-ios/commit/cc31de27a56e8e1a573cabf06ca83b260f6e2c9b))
* make read-failure and cancel NFC sheet messages localizable ([#59](https://github.com/gmrtd/gmrtd-ios/issues/59)) ([5996d7a](https://github.com/gmrtd/gmrtd-ios/commit/5996d7a7409f50f20b2da2f58bd3e4556b6446d3))


### Bug Fixes

* bump gmrtd core to v1.10.0 ([#56](https://github.com/gmrtd/gmrtd-ios/issues/56)) ([607f8be](https://github.com/gmrtd/gmrtd-ios/commit/607f8becfbcc22e523e62c119f81c1263a5e7534))
* bump gmrtd core to v1.9.0 ([#53](https://github.com/gmrtd/gmrtd-ios/issues/53)) ([295fdb5](https://github.com/gmrtd/gmrtd-ios/commit/295fdb50824848fe0e5f6bdb75180781d93996f2))
* bump gmrtd core to v1.9.1 ([#55](https://github.com/gmrtd/gmrtd-ios/issues/55)) ([ea2211b](https://github.com/gmrtd/gmrtd-ios/commit/ea2211b6e2c7c7bd219ff6605302901ab3db6049))
* show error state on NFC sheet when a read fails ([#58](https://github.com/gmrtd/gmrtd-ios/issues/58)) ([8eeef93](https://github.com/gmrtd/gmrtd-ios/commit/8eeef9396d8b56a7ca347b4ee31b85d4f5a7d963))

## [1.3.1](https://github.com/gmrtd/gmrtd-ios/compare/v1.3.0...v1.3.1) (2026-11-01)


### Bug Fixes

* bump gmrtd core to v1.7.0 ([#48](https://github.com/gmrtd/gmrtd-ios/issues/48)) ([530589e](https://github.com/gmrtd/gmrtd-ios/commit/530589ec0d2685f64ff97d1195e019d8ac1e714b))
* bump gmrtd core to v1.7.1 ([#50](https://github.com/gmrtd/gmrtd-ios/issues/50)) ([5b47c17](https://github.com/gmrtd/gmrtd-ios/commit/5b47c177f4b8761e75ff7eb0c9e859839b10aaf7))
* bump gmrtd core to v1.8.0 ([#52](https://github.com/gmrtd/gmrtd-ios/issues/52)) ([7e1860e](https://github.com/gmrtd/gmrtd-ios/commit/7e1860e120ba57aa5f30cc50e62d8498786a1307))

## [1.3.0](https://github.com/gmrtd/gmrtd-ios/compare/v1.2.2...v1.3.0) (2026-10-17)


### Features

* expose IdentityAttributes.dateOfBirthSource (gmrtd 1.6.0) ([#45](https://github.com/gmrtd/gmrtd-ios/issues/45)) ([733c21f](https://github.com/gmrtd/gmrtd-ios/commit/733c21fbb3ed0e8ce131ff2cba9754e6a329a2cd))


### Bug Fixes

* bump gmrtd core to v1.6.0 ([#46](https://github.com/gmrtd/gmrtd-ios/issues/46)) ([009c766](https://github.com/gmrtd/gmrtd-ios/commit/009c7660afe1c4bad6f3a3b33a446c958f06dab3))

## [1.2.2](https://github.com/gmrtd/gmrtd-ios/compare/v1.2.1...v1.2.2) (2026-10-17)


### Bug Fixes

* bump gmrtd core to v1.5.2 ([#43](https://github.com/gmrtd/gmrtd-ios/issues/43)) ([54306a9](https://github.com/gmrtd/gmrtd-ios/commit/54306a97b74711ff00a7324e1982e59164d5d021))

## [1.2.1](https://github.com/gmrtd/gmrtd-ios/compare/v1.2.0...v1.2.1) (2026-10-17)


### Bug Fixes

* bump gmrtd core to v1.5.1 ([#41](https://github.com/gmrtd/gmrtd-ios/issues/41)) ([8e59bf2](https://github.com/gmrtd/gmrtd-ios/commit/8e59bf23cc86fe1cd4e7c2084752b412aac87fb9))

## [1.2.0](https://github.com/gmrtd/gmrtd-ios/compare/v1.1.0...v1.2.0) (2026-10-17)


### Features

* attach the rejected document's summary to MRTDReadError.notAuthentic ([#40](https://github.com/gmrtd/gmrtd-ios/issues/40)) ([ab57469](https://github.com/gmrtd/gmrtd-ios/commit/ab57469098a807a084bb0332dcbcff17b7e26d81))
* support gmrtd 1.4.0 trust chain, RequireAuthenticDocument and trusted-source re-verification ([#38](https://github.com/gmrtd/gmrtd-ios/issues/38)) ([6b64e81](https://github.com/gmrtd/gmrtd-ios/commit/6b64e816171607dca7c459325d9b209ab655d1cf))


### Bug Fixes

* bump gmrtd core to v1.3.2 ([#34](https://github.com/gmrtd/gmrtd-ios/issues/34)) ([886e879](https://github.com/gmrtd/gmrtd-ios/commit/886e879b474371332be32c78a66d80b2a47ca8c0))
* bump gmrtd core to v1.4.0 ([#37](https://github.com/gmrtd/gmrtd-ios/issues/37)) ([18bacd2](https://github.com/gmrtd/gmrtd-ios/commit/18bacd204ac1e3c9635d1cdfd4c13db8298a3089))
* bump gmrtd core to v1.5.0 ([#39](https://github.com/gmrtd/gmrtd-ios/issues/39)) ([d5f5a7d](https://github.com/gmrtd/gmrtd-ios/commit/d5f5a7dff98ca92766e708f1eb21afd70368e55e))

## [1.1.0](https://github.com/gmrtd/gmrtd-ios/compare/v1.0.2...v1.1.0) (2026-09-28)


### Features

* expose IdentityAttributes.expired from gmrtd core 1.3.0 ([#31](https://github.com/gmrtd/gmrtd-ios/issues/31)) ([1837229](https://github.com/gmrtd/gmrtd-ios/commit/183722915a5ce3a14fd94057a414420fcadf01b0))

## [1.0.2](https://github.com/gmrtd/gmrtd-ios/compare/v1.0.1...v1.0.2) (2026-09-28)


### Bug Fixes

* bump gmrtd core to v1.3.0 ([#29](https://github.com/gmrtd/gmrtd-ios/issues/29)) ([3b75759](https://github.com/gmrtd/gmrtd-ios/commit/3b75759024a43885f4e7c3841c2e5f8e9e43cd7a))

## [1.0.1](https://github.com/gmrtd/gmrtd-ios/compare/v1.0.0...v1.0.1) (2026-08-25)


### Bug Fixes

* bump gmrtd core to v1.1.4 ([#25](https://github.com/gmrtd/gmrtd-ios/issues/25)) ([3f9abf8](https://github.com/gmrtd/gmrtd-ios/commit/3f9abf88448da5d271d14d5e61a57f1da6518101))

## [1.0.0](https://github.com/gmrtd/gmrtd-ios/compare/v0.6.0...v1.0.0) (2026-08-25)


### ⚠ BREAKING CHANGES

* declare GmrtdKit API stable at 1.0.0 ([#23](https://github.com/gmrtd/gmrtd-ios/issues/23))

### Features

* declare GmrtdKit API stable at 1.0.0 ([#23](https://github.com/gmrtd/gmrtd-ios/issues/23)) ([a6f7026](https://github.com/gmrtd/gmrtd-ios/commit/a6f7026fa8bbbad5feffed9b1953a5c26e403dc7))

## [0.6.0](https://github.com/gmrtd/gmrtd-ios/compare/v0.5.0...v0.6.0) (2026-08-24)


### Features

* add MRZi credential (document number + DOB + DOE) ([#21](https://github.com/gmrtd/gmrtd-ios/issues/21)) ([393d2eb](https://github.com/gmrtd/gmrtd-ios/commit/393d2eb8a6014b2595d770d283d974ca16f649f1))

## [0.5.0](https://github.com/gmrtd/gmrtd-ios/compare/v0.4.3...v0.5.0) (2026-08-24)


### Features

* expose AllowBacFallbackOnPaceError via MRTDReadOptions ([#19](https://github.com/gmrtd/gmrtd-ios/issues/19)) ([6175a37](https://github.com/gmrtd/gmrtd-ios/commit/6175a37adc8a1512c40e2ed08e2b75bb3f7c66c5))

## [0.4.3](https://github.com/gmrtd/gmrtd-ios/compare/v0.4.2...v0.4.3) (2026-08-24)


### Bug Fixes

* select an available iOS Simulator dynamically in CI ([#17](https://github.com/gmrtd/gmrtd-ios/issues/17)) ([b073b69](https://github.com/gmrtd/gmrtd-ios/commit/b073b69a6aba8cfba4622be880167cf92bad0e96))

## [0.4.2](https://github.com/gmrtd/gmrtd-ios/compare/v0.4.1...v0.4.2) (2026-08-24)


### Bug Fixes

* bump gmrtd core to v1.1.3 ([#15](https://github.com/gmrtd/gmrtd-ios/issues/15)) ([cb0fa80](https://github.com/gmrtd/gmrtd-ios/commit/cb0fa80cc210c4992453338d50df6bc4655440f9))

## [0.4.1](https://github.com/gmrtd/gmrtd-ios/compare/v0.4.0...v0.4.1) (2026-08-21)


### Bug Fixes

* bump gmrtd core to v1.1.2 ([#13](https://github.com/gmrtd/gmrtd-ios/issues/13)) ([f056fff](https://github.com/gmrtd/gmrtd-ios/commit/f056fffa5a29e2d78a33fe17876c5c552a1f6970))

## [0.4.0](https://github.com/gmrtd/gmrtd-ios/compare/v0.3.0...v0.4.0) (2026-08-16)


### Features

* Replace summaryJson with a native DocumentSummary Swift type ([#11](https://github.com/gmrtd/gmrtd-ios/issues/11)) ([6e30a4a](https://github.com/gmrtd/gmrtd-ios/commit/6e30a4ab0704cb66fec3547df47cb431c366768c))

## [0.3.0](https://github.com/gmrtd/gmrtd-ios/compare/v0.2.0...v0.3.0) (2026-08-14)


### Features

* add gmrtd-release-tracking workflow ([#4](https://github.com/gmrtd/gmrtd-ios/issues/4)) ([0b00a6e](https://github.com/gmrtd/gmrtd-ios/commit/0b00a6ee6a37887a37c13c3be118ba6579ab0bf5))


### Bug Fixes

* pin CI to Xcode 16.4 to fix missing simulator destination ([#8](https://github.com/gmrtd/gmrtd-ios/issues/8)) ([85402e0](https://github.com/gmrtd/gmrtd-ios/commit/85402e0e510373bb5481620c18544bfb197f23d6))
* use base version tags for SPM ([#6](https://github.com/gmrtd/gmrtd-ios/issues/6)) ([c37f3e5](https://github.com/gmrtd/gmrtd-ios/commit/c37f3e51d6073a6d54b4c9c26b7eb8cc53e78aad))

## [0.2.0](https://github.com/gmrtd/gmrtd-ios/compare/GmrtdKit-v0.1.0...GmrtdKit-v0.2.0) (2026-08-14)


### Features

* add gmrtd-release-tracking workflow ([#4](https://github.com/gmrtd/gmrtd-ios/issues/4)) ([0b00a6e](https://github.com/gmrtd/gmrtd-ios/commit/0b00a6ee6a37887a37c13c3be118ba6579ab0bf5))

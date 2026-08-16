//
//  VersionInfo.swift
//  GmrtdKit
//

import Gmrtd

// Bumped by release-please — keep this exact `let name = "value"` shape so it
// can be located/replaced by regex.
let gmrtdKitVersionLiteral = "0.4.0" // x-release-please-version

/// Version information for GmrtdKit (this Swift package) and GmrtdCore (the
/// vendored gmrtd Go library it wraps).
public enum GmrtdKitVersionInfo {
    /// This package's own version.
    public static let kit = gmrtdKitVersionLiteral

    /// GmrtdCore's version, read live from the library itself rather than a
    /// pinned literal — see `libraryVersionMatchesThePinnedPackageVersion` in
    /// GmrtdKitTests for the cross-check against Package.swift's pin.
    public static var core: String {
        GmrtdGoRuntime.serialized {
            GmrtdMobileVersion()
        }
    }
}

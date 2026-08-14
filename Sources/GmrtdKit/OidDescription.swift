//
//  OidDescription.swift
//  GmrtdKit
//

import Gmrtd

/// Human-readable description for a known ICAO/PKI OID, or an empty string if unrecognised.
public func oidDescription(_ oid: String) -> String {
    GmrtdGoRuntime.serialized {
        GmrtdMobileOidDesc(oid)
    }
}

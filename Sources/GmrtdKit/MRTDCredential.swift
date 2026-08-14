//
//  MRTDCredential.swift
//  GmrtdKit
//

/// The credential used to authenticate with an MRTD chip.
/// Both cases produce a `GmrtdMobileMrtdPassword` but differ in password
/// creation and in the NFC polling option required.
public enum MRTDCredential: Sendable {
    /// Full MRZ string from the data strip (TD1 / TD2 / TD3 formats).
    case mrz(String)
    /// 6-digit Card Access Number printed on the identity card face.
    case can(String)
}

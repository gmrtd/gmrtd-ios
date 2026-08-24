//
//  MRTDCredential.swift
//  GmrtdKit
//

/// The credential used to authenticate with an MRTD chip.
/// All cases produce a `GmrtdMobileMrtdPassword` but differ in password
/// creation and in the NFC polling option required.
public enum MRTDCredential: Sendable {
    /// Full MRZ string from the data strip (TD1 / TD2 / TD3 formats).
    case mrz(String)
    /// 6-digit Card Access Number printed on the identity card face.
    case can(String)
    /// The composite "MRZi" key: document number, date of birth, and date
    /// of expiry, for when the full MRZ string isn't available but these
    /// individual fields are (e.g. read from a different data source than
    /// OCR of the data strip). Dates are `YYMMDD`; the document number is
    /// padded/truncated to 9 characters the same way the full MRZ encodes
    /// it. Check digits are computed internally — pass the raw values.
    case mrzi(documentNo: String, dateOfBirth: String, dateOfExpiry: String)
}

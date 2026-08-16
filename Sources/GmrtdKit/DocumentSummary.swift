//
//  DocumentSummary.swift
//  GmrtdKit
//

import Foundation

/// A document's overall trust/authenticity state, decoded from gmrtd's `SummaryJson()`
/// output (see gmrtd's `document.DocumentSummary`). Field names/optionality mirror the Go
/// struct's `json` tags directly, so this type has to be kept in sync by hand whenever
/// gmrtd's `document/document_summary.go` changes shape — gomobile can't bind nested
/// structs/slices directly, which is why the JSON round-trip exists at all.
public struct DocumentSummary: Decodable, Sendable {
    public let dataTrusted: Bool
    public let chipAuthenticity: ChipAuthStatus
    public let ldsVersion: String?
    public let unicodeVersion: String?

    /// Reflects whatever DG data is present, regardless of `dataTrusted` — e.g. a failed
    /// Passive Authentication still surfaces the (unverified) MRZ/DG11/DG12 data, since
    /// callers may want to inspect it for manual review. `dataTrusted` is the sole signal
    /// for whether this data has been cryptographically verified.
    public let identityAttributes: IdentityAttributes?
}

extension DocumentSummary {
    /// Decodes gmrtd's `summaryJson()`/`SummaryJson()` output into this type.
    public init(jsonData: Data) throws {
        self = try JSONDecoder().decode(DocumentSummary.self, from: jsonData)
    }
}

/// Mirrors gmrtd's `document.ChipAuthStatus` (see `CHIP_AUTH_STATUS_*` in
/// gmrtd's document/document_ex.go).
public enum ChipAuthStatus: Sendable, Equatable {
    case none
    case paceCam
    case chipAuthentication
    case activeAuthentication
    /// Forward-compat: a future gmrtd release adds a status value this build doesn't
    /// know about yet.
    case other(Int)
}

extension ChipAuthStatus: Decodable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        switch raw {
        case 0: self = .none
        case 1: self = .paceCam
        case 2: self = .chipAuthentication
        case 3: self = .activeAuthentication
        default: self = .other(raw)
        }
    }
}

/// Resolves an MRZ alpha-3 country code to its alpha-2 code and full name. Mirrors gmrtd's
/// `document.CountryInfo`.
public struct CountryInfo: Decodable, Sendable {
    public let alpha3: String?
    public let alpha2: String?
    public let name: String?
}

/// Mirrors gmrtd's `mrz.MrzName`.
public struct MrzName: Decodable, Sendable {
    public let primary: String?
    public let secondary: String?
}

/// A raw image (e.g. face photo, signature) together with its detected format. Mirrors
/// gmrtd's `document.ImageData`.
public struct ImageData: Decodable, Sendable {
    public let data: Data?
    public let format: ImageFormat?
}

/// Mirrors gmrtd's `utils.ImageFormat`.
public enum ImageFormat: Sendable, Equatable {
    case jpeg
    case jpeg2000
    /// Forward-compat / undetected: a format string this build doesn't recognize, or
    /// gmrtd couldn't classify the image bytes.
    case other(String)
}

extension ImageFormat: Decodable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "image/jpeg": self = .jpeg
        case "image/jp2": self = .jpeg2000
        default: self = .other(raw)
        }
    }
}

/// Mirrors gmrtd's `document.PersonToNotify` (DG16).
public struct PersonToNotify: Decodable, Sendable {
    public let dateRecorded: String?
    public let name: MrzName?
    public let telephone: String?
    public let address: [String]?
}

/// A flattened, client-friendly view of the data spread across a document's Data Groups
/// (DG1 MRZ, DG2, DG7, DG11, DG12, DG16). Where multiple DGs carry the same field, the
/// higher-fidelity source wins — see gmrtd's `buildIdentityAttributes` for the precedence
/// rules. Mirrors gmrtd's `document.IdentityAttributes`.
public struct IdentityAttributes: Decodable, Sendable {
    public let documentCode: String?
    public let issuingState: CountryInfo?
    public let documentNumber: String?
    public let nationality: CountryInfo?
    public let sex: String?

    /// Resolved from DG11 if present, else DG1 MRZ. `nameMrzRaw` is always the DG1 MRZ
    /// value (regardless of which source `name` resolved to).
    public let name: MrzName?
    public let nameMrzRaw: MrzName?
    public let otherNames: [MrzName]?

    /// DG11's `FullDateOfBirth` (YYYYMMDD) if present, else the raw DG1 MRZ value (YYMMDD,
    /// no century). The raw, per-source values are also surfaced below.
    public let dateOfBirth: String?
    public let dateOfBirthMrzRaw: String?
    public let dateOfBirthDg11Raw: String?

    /// Set only when `dateOfBirth` has an explicit century (DG11's 8-digit
    /// `FullDateOfBirth`). See `possibleAges` for the ambiguous DG1-MRZ-only case.
    public let age: Int?
    /// Candidate ages when `dateOfBirth`'s century is ambiguous (DG1-MRZ-only, 6-digit
    /// YYMMDD), ordered youngest to oldest. Empty whenever `age` is set.
    public let possibleAges: [Int]?

    public let dateOfExpiry: String?
    public let dateOfExpiryMrzRaw: String?

    public let placeOfBirth: [String]?
    public let address: [String]?
    public let telephone: String?
    public let profession: String?
    public let title: String?

    /// DG11 only.
    public let personalNumber: String?
    /// Raw MRZ, unresolved.
    public let mrzOptionalData: String?
    /// TD1 only.
    public let mrzOptionalData2: String?

    public let issuingAuthority: String?

    public let dateOfIssue: String?
    public let dateOfIssueRaw: String?

    public let faceImages: [ImageData]?
    public let signatureImages: [ImageData]?
    public let documentImageFront: ImageData?
    public let documentImageRear: ImageData?

    public let personsToNotify: [PersonToNotify]?
}

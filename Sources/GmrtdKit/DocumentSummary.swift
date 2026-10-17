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
public struct DocumentSummary: Decodable, Sendable, Equatable {
    public let dataTrusted: Bool
    public let chipAuthenticity: ChipAuthStatus
    public let ldsVersion: String?
    public let unicodeVersion: String?

    /// Reflects whatever DG data is present, regardless of `dataTrusted` — e.g. a failed
    /// Passive Authentication still surfaces the (unverified) MRZ/DG11/DG12 data, since
    /// callers may want to inspect it for manual review. `dataTrusted` is the sole signal
    /// for whether this data has been cryptographically verified.
    public let identityAttributes: IdentityAttributes?

    /// The Passive Authentication outcome and the certificate trust chains behind
    /// `dataTrusted`, for display. Optional so summaries from gmrtd releases before
    /// 1.4.0 still decode.
    public let passiveAuth: PassiveAuthSummary?
}

extension DocumentSummary {
    /// Decodes gmrtd's `summaryJson()`/`SummaryJson()` output into this type.
    public init(jsonData: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(decodeRFC3339Date)
        self = try decoder.decode(DocumentSummary.self, from: jsonData)
    }
}

/// Decodes a Go `time.Time` (RFC 3339, with optional fractional seconds).
private func decodeRFC3339Date(_ decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(String.self)
    for options: ISO8601DateFormatter.Options in [[.withInternetDateTime], [.withInternetDateTime, .withFractionalSeconds]] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = options
        if let date = formatter.date(from: raw) {
            return date
        }
    }
    throw DecodingError.dataCorruptedError(in: container, debugDescription: "invalid RFC 3339 date: \(raw)")
}

/// The Passive Authentication outcome and certificate trust chains. Mirrors gmrtd's
/// `document.PassiveAuthSummary`.
public struct PassiveAuthSummary: Decodable, Sendable, Equatable {
    public let status: PassiveAuthStatus
    public let error: String?

    public let sod: SignedObjectTrust?
    /// `nil` when the document has no EF.CardSecurity.
    public let cardSecurity: SignedObjectTrust?
}

/// Mirrors gmrtd's `document.PassiveAuthStatus` (`PASSIVE_AUTH_STATUS_*`).
public enum PassiveAuthStatus: Sendable, Equatable {
    case verified
    case failed
    case notPerformed
    /// Forward-compat: a status value this build doesn't know about yet.
    case other(String)
}

extension PassiveAuthStatus: Decodable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "VERIFIED": self = .verified
        case "FAILED": self = .failed
        case "NOT_PERFORMED": self = .notPerformed
        default: self = .other(raw)
        }
    }
}

/// Where `IdentityAttributes.dateOfBirth` came from. Mirrors gmrtd's
/// `document.DateOfBirthSource` (`DOB_SOURCE_*`).
public enum DateOfBirthSource: Sendable, Equatable {
    /// DG11's `FullDateOfBirth` (YYYYMMDD).
    case dg11
    /// The DG1 MRZ, raw YYMMDD (no century).
    case dg1Mrz
    /// The DG1 MRZ YYMMDD, expanded to YYYYMMDD using the century encoded by the Singapore
    /// NRIC in the MRZ optional data ('S' = 19xx, 'T' = 20xx).
    case dg1MrzSgNric
    /// Forward-compat: a source value this build doesn't know about yet.
    case other(String)
}

extension DateOfBirthSource: Decodable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "DG11": self = .dg11
        case "DG1_MRZ": self = .dg1Mrz
        case "DG1_MRZ_SG_NRIC": self = .dg1MrzSgNric
        default: self = .other(raw)
        }
    }
}

/// The trust chain of one signed object (EF.SOD or EF.CardSecurity). Mirrors gmrtd's
/// `document.SignedObjectTrust`.
///
/// When `verified`, `chain` is the verified chain: each document signer certificate
/// followed by the trusted CSCA (or CSCA link) certificate that issued it. Otherwise
/// `chain` only holds the document signer certificate(s) embedded in the document,
/// if they can be identified. These are chip-supplied and **unverified**: they show
/// who claims to have signed the data, never that it is trustworthy.
public struct SignedObjectTrust: Decodable, Sendable, Equatable {
    public let verified: Bool
    public let chain: [TrustChainCertificate]?
}

/// Mirrors gmrtd's `document.CertificateRole` (`CERTIFICATE_ROLE_*`).
public enum CertificateRole: Sendable, Equatable {
    case documentSigner
    case csca
    case cscaLink
    /// Forward-compat: a role value this build doesn't know about yet.
    case other(String)
}

extension CertificateRole: Decodable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "DOCUMENT_SIGNER": self = .documentSigner
        case "CSCA": self = .csca
        case "CSCA_LINK": self = .cscaLink
        default: self = .other(raw)
        }
    }
}

/// A display-oriented summary of one certificate in a trust chain. Mirrors gmrtd's
/// `document.TrustChainCertificate` (and the embedded `cms.CertificateInfo`). Fields
/// gmrtd couldn't determine from a malformed certificate are `nil`.
public struct TrustChainCertificate: Decodable, Sendable, Equatable {
    public let role: CertificateRole

    /// Whether the certificate has expired as of when the summary was built. Informational
    /// only: verification is at the time of signing, so an expired certificate is expected
    /// for older documents and does not mean the chain is untrusted. `nil` when the
    /// validity period can't be parsed.
    public let expired: Bool?

    public let subject: String?
    public let issuer: String?
    /// The subject's countryName, as encoded in the certificate (case varies by issuer).
    public let country: String?
    /// Hex.
    public let serialNumber: String?
    public let notBefore: Date?
    public let notAfter: Date?
    /// e.g. "EC(BrainpoolP256r1)", "RSA(3072)".
    public let keyType: String?
    public let signatureAlgorithm: String?
    /// Hex.
    public let subjectKeyId: String?
    /// Hex.
    public let authorityKeyId: String?
    /// Hex SHA-256 of the DER certificate.
    public let fingerprintSha256: String?
    public let ca: Bool?
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
public struct CountryInfo: Decodable, Sendable, Equatable {
    public let alpha3: String?
    public let alpha2: String?
    public let name: String?
}

/// Mirrors gmrtd's `mrz.MrzName`.
public struct MrzName: Decodable, Sendable, Equatable {
    public let primary: String?
    public let secondary: String?
}

/// A raw image (e.g. face photo, signature) together with its detected format. Mirrors
/// gmrtd's `document.ImageData`.
public struct ImageData: Decodable, Sendable, Equatable {
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
public struct PersonToNotify: Decodable, Sendable, Equatable {
    public let dateRecorded: String?
    public let name: MrzName?
    public let telephone: String?
    public let address: [String]?
}

/// A flattened, client-friendly view of the data spread across a document's Data Groups
/// (DG1 MRZ, DG2, DG7, DG11, DG12, DG16). Where multiple DGs carry the same field, the
/// higher-fidelity source wins — see gmrtd's `buildIdentityAttributes` for the precedence
/// rules. Mirrors gmrtd's `document.IdentityAttributes`.
public struct IdentityAttributes: Decodable, Sendable, Equatable {
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

    /// DG11's `FullDateOfBirth` (YYYYMMDD) if present, else the DG1 MRZ value: raw YYMMDD
    /// (no century), except where the issuer's own MRZ data determines the century
    /// (currently Singapore passports, from the NRIC), when it is YYYYMMDD.
    /// `dateOfBirthSource` says which applies. The raw, per-source values are also
    /// surfaced below.
    public let dateOfBirth: String?
    /// Where `dateOfBirth` came from. `nil` when there's no `dateOfBirth`, or for summaries
    /// from gmrtd releases before 1.6.0.
    public let dateOfBirthSource: DateOfBirthSource?
    public let dateOfBirthMrzRaw: String?
    public let dateOfBirthDg11Raw: String?

    /// Set only when `dateOfBirth` has an explicit century (8-digit YYYYMMDD: DG11's
    /// `FullDateOfBirth`, or an MRZ date of birth whose century the issuer's data determines
    /// - see `dateOfBirthSource`). See `possibleAges` for the ambiguous DG1-MRZ-only case.
    public let age: Int?
    /// Candidate ages when `dateOfBirth`'s century is ambiguous (DG1-MRZ-only, 6-digit
    /// YYMMDD), ordered youngest to oldest. Empty whenever `age` is set.
    public let possibleAges: [Int]?

    public let dateOfExpiry: String?
    public let dateOfExpiryMrzRaw: String?

    /// Whether `dateOfExpiry` is before today's date in the device's local time zone (a
    /// document is valid through its expiry date, inclusive), evaluated by gmrtd when the
    /// summary is built. `nil` when it can't be determined: no DG1, or an expiry that isn't
    /// a real date (e.g. the non-standard "999999" some issuers use for non-expiring
    /// documents). Deliberately not a factor in `DocumentSummary.dataTrusted`: an expired
    /// document is still authentic, and whether expiry matters is the caller's policy.
    public let expired: Bool?

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

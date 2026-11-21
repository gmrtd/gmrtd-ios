//
//  MRTDReadError.swift
//  GmrtdKit
//

import Foundation
import Gmrtd

/// Typed NFC/MRTD read errors. notDetected = chip not detected (positioning),
/// interrupted = read cut short (motion/signal/timeout), unsupported = chip type not
/// recognised, accessDenied = wrong MRZ/CAN, credentialNotUsable = the credential
/// can't be used with this document or these options.
///
/// gmrtd's own read failures are classified from its typed `lastReadError()` code.
/// Everything else (CoreNFC session errors, and gmrtd failures it doesn't type) is a
/// best-effort text match, as those only surface a plain message, so a wording change
/// on either side could shift a case's classification. Each case below (other than
/// `invalidAAChallenge`, which is raised directly by this package) carries that original
/// message via `underlying`, so a misclassification is still diagnosable from
/// logs/analytics rather than losing the detail behind a generic case name.
public enum MRTDReadError: Error, Equatable, Sendable {
    case notDetected(underlying: String)
    case interrupted(underlying: String)
    case unsupported(underlying: String)
    /// PACE or BAC was attempted and the chip refused it, most often because the MRZ or
    /// CAN doesn't match the document. Retrying with the same credential won't help.
    case accessDenied(underlying: String)
    /// No access control could run with this credential, so nothing was read: BAC needs
    /// the MRZ, so a `.can` credential fails when PACE is skipped (`skipPace`), not
    /// supported by the chip or GmrtdKit, or fails under `allowBacFallbackOnPaceError`.
    case credentialNotUsable(underlying: String)
    /// `MRTDReadOptions.requireAuthenticDocument` was set and the document isn't
    /// verifiably authentic: Passive Authentication failed, or chip authentication was
    /// attempted and none verifiably succeeded. The chip was read; it just can't be
    /// trusted, so retrying won't help.
    ///
    /// `summary` is the rejected document's summary, e.g. to show the user why via
    /// `summary.passiveAuth`. It is **not** authentic: present it only as a rejected
    /// document, never as an accepted one. `nil` if it couldn't be retrieved or decoded.
    case notAuthentic(underlying: String, summary: DocumentSummary?)
    /// `MRTDReadOptions.aaChallenge` was provided but isn't exactly 8 bytes.
    /// Caught before the NFC session starts — a caller/integration error, not a
    /// chip/session failure.
    case invalidAAChallenge
    /// Decoding gmrtd's summary JSON into `DocumentSummary` failed — a schema mismatch
    /// between this package's native type and the gmrtd version it's bundled against,
    /// not a chip/session failure. Shouldn't happen in a correctly matched release; if
    /// it does, it's a GmrtdKit bug rather than a caller error.
    case summaryDecodingFailed(underlying: String)

    /// The original `error.localizedDescription` this case was classified from, e.g.
    /// for logging/support diagnosis. `nil` for `invalidAAChallenge`, which isn't
    /// classified from an underlying error. UI code should switch on the case, not
    /// this text — it isn't a stable API and both its source (CoreNFC, gmrtd) may
    /// change wording across OS/library versions.
    public var underlying: String? {
        switch self {
        case .notDetected(let underlying), .interrupted(let underlying), .unsupported(let underlying),
             .accessDenied(let underlying), .credentialNotUsable(let underlying),
             .notAuthentic(let underlying, _), .summaryDecodingFailed(let underlying):
            return underlying
        case .invalidAAChallenge:
            return nil
        }
    }

    /// Classifies a failed `readDocument` from gmrtd's `lastReadError()` code, falling
    /// back to the text match for codes that don't name a specific cause.
    static func classify(_ error: Error, readError: Int) -> MRTDReadError {
        let msg = error.localizedDescription
        switch readError {
        case GmrtdMobileREAD_ERROR_ACCESS_CONTROL_FAILED: return .accessDenied(underlying: msg)
        case GmrtdMobileREAD_ERROR_NO_SECURE_MESSAGING: return .credentialNotUsable(underlying: msg)
        case GmrtdMobileREAD_ERROR_DOCUMENT_NOT_AUTHENTIC: return .notAuthentic(underlying: msg, summary: nil)
        default: return classify(error)
        }
    }

    static func classify(_ error: Error) -> MRTDReadError {
        let msg = error.localizedDescription
        if msg.contains("No NFC tag") || msg.contains("not detected") {
            return .notDetected(underlying: msg)
        }
        if msg.contains("Unsupported NFC tag") {
            return .unsupported(underlying: msg)
        }
        // gmrtd's reader.ErrDocumentNotAuthentic (RequireAuthenticDocument)
        if msg.contains("document is not authentic") {
            return .notAuthentic(underlying: msg, summary: nil)
        }
        // Catches: "Connection error:", "Error reading document",
        // semaphore/watchdog timeout, and any other mid-read failure.
        return .interrupted(underlying: msg)
    }

    /// Attaches the rejected document's summary to `.notAuthentic`, from gmrtd's
    /// `Reader.RejectedDocument()` (gomobile drops the document `ReadDocument` returns
    /// with its error). Other cases are returned unchanged.
    func withRejectedSummary(_ summaryJson: () throws -> Data?) -> MRTDReadError {
        guard case .notAuthentic(let underlying, nil) = self, let json = try? summaryJson() else {
            return self
        }
        return .notAuthentic(underlying: underlying, summary: try? DocumentSummary(jsonData: json))
    }
}

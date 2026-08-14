//
//  MRTDReadError.swift
//  GmrtdKit
//

import Foundation

/// Typed NFC/MRTD read errors, classified from raw library/session error strings.
/// notDetected = chip not detected (positioning), interrupted = read cut short
/// (motion/signal/timeout), unsupported = chip type not recognised.
///
/// Classification itself is necessarily a best-effort text match — CoreNFC session
/// errors and the underlying gmrtd/Go library both only ever surface a plain message,
/// not a typed code, so a wording change on either side could shift a case's
/// classification. Each case below (other than `invalidAAChallenge`, which is raised
/// directly by this package) carries that original message via `underlying`, so a
/// misclassification is still diagnosable from logs/analytics rather than losing the
/// detail behind a generic case name.
public enum MRTDReadError: Error, Equatable, Sendable {
    case notDetected(underlying: String)
    case interrupted(underlying: String)
    case unsupported(underlying: String)
    /// `MRTDReadOptions.aaChallenge` was provided but isn't exactly 8 bytes.
    /// Caught before the NFC session starts — a caller/integration error, not a
    /// chip/session failure.
    case invalidAAChallenge

    /// The original `error.localizedDescription` this case was classified from, e.g.
    /// for logging/support diagnosis. `nil` for `invalidAAChallenge`, which isn't
    /// classified from an underlying error. UI code should switch on the case, not
    /// this text — it isn't a stable API and both its source (CoreNFC, gmrtd) may
    /// change wording across OS/library versions.
    public var underlying: String? {
        switch self {
        case .notDetected(let underlying), .interrupted(let underlying), .unsupported(let underlying):
            return underlying
        case .invalidAAChallenge:
            return nil
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
        // Catches: "Connection error:", "Error reading document",
        // semaphore/watchdog timeout, and any other mid-read failure.
        return .interrupted(underlying: msg)
    }
}

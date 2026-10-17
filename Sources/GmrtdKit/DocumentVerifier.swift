//
//  DocumentVerifier.swift
//  GmrtdKit
//

import Foundation
import Gmrtd

public enum DocumentJsonRegenerationError: Error {
    case missingCbor
    case verifierUnavailable
    case verificationFailed(underlying: Error)
    case invalidUtf8
    /// Decoding gmrtd's summary JSON into `DocumentSummary` failed — a schema mismatch
    /// between this package's native type and the gmrtd version it's bundled against,
    /// not a verification failure.
    case summaryDecodingFailed(underlying: Error)
}

public struct RegeneratedDocument {
    public let summary: DocumentSummary
    public let technicalJson: String
}

public enum DocumentJsonRegenerator {
    /// Reconstructs a document's native summary and technical JSON representation from
    /// its saved CBOR ("verifiable document") bytes via the gmrtd Verifier, from a
    /// single verification pass.
    ///
    /// - Parameter aaChallenge: The same Active Authentication challenge that was used
    ///   when the document was originally read (see `MRTDReadOptions.aaChallenge` /
    ///   `MRTDReadResult.aaChallenge`), if available. Binding it here lets the verifier
    ///   hard-error on a nonce mismatch rather than accepting an AA response regardless
    ///   of session — see the `withAAChallenge` doc comment on the Gmrtd side. As with
    ///   the read side, real relay-attack protection requires this to be a challenge
    ///   the verifying party itself issued, not one generated on the reading device.
    /// - Parameter trustedSource: Whether the CBOR was captured by a reader you trust —
    ///   typically this app itself, with the CBOR stored where nothing else could have
    ///   altered or substituted it. Replayed Chip Authentication and PACE-CAM evidence
    ///   can be produced by anyone holding the capturing reader's ephemeral keys, so it
    ///   can't prove the chip was present; by default (`false`) the summary's
    ///   `chipAuthenticity` therefore only reports Active Authentication bound to
    ///   `aaChallenge`. Set `true` only for evidence from a trusted reader, e.g. when
    ///   redisplaying this app's own saved scan; never for CBOR received from elsewhere.
    public static func regenerate(fromCbor cborData: Data?, aaChallenge: Data? = nil, trustedSource: Bool = false) -> Result<RegeneratedDocument, DocumentJsonRegenerationError> {
        guard let cborData else { return .failure(.missingCbor) }
        return GmrtdGoRuntime.serialized {
            guard var verifier = GmrtdMobileNewVerifier() else {
                return .failure(.verifierUnavailable)
            }
            do {
                if let aaChallenge {
                    verifier = try verifier.withAAChallenge(aaChallenge) ?? verifier
                }
                if trustedSource {
                    verifier = verifier.withTrustedSource() ?? verifier
                }
                let doc = try verifier.verify(cborData)
                let technicalData = try doc.documentExJson()
                let summaryData = try doc.summaryJson()
                guard let technicalStr = String(data: technicalData, encoding: .utf8) else {
                    return .failure(.invalidUtf8)
                }
                let summary: DocumentSummary
                do {
                    summary = try DocumentSummary(jsonData: summaryData)
                } catch {
                    return .failure(.summaryDecodingFailed(underlying: error))
                }
                return .success(RegeneratedDocument(summary: summary, technicalJson: technicalStr))
            } catch {
                return .failure(.verificationFailed(underlying: error))
            }
        }
    }
}

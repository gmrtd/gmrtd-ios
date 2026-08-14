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
}

public struct RegeneratedDocument {
    public let summaryJson: String
    public let technicalJson: String
}

public enum DocumentJsonRegenerator {
    /// Reconstructs a document's summary and technical JSON representations from its
    /// saved CBOR ("verifiable document") bytes via the gmrtd Verifier, from a single
    /// verification pass.
    ///
    /// - Parameter aaChallenge: The same Active Authentication challenge that was used
    ///   when the document was originally read (see `MRTDReadOptions.aaChallenge` /
    ///   `MRTDReadResult.aaChallenge`), if available. Binding it here lets the verifier
    ///   hard-error on a nonce mismatch rather than accepting an AA response regardless
    ///   of session — see the `withAAChallenge` doc comment on the Gmrtd side. As with
    ///   the read side, real relay-attack protection requires this to be a challenge
    ///   the verifying party itself issued, not one generated on the reading device.
    public static func regenerate(fromCbor cborData: Data?, aaChallenge: Data? = nil) -> Result<RegeneratedDocument, DocumentJsonRegenerationError> {
        guard let cborData else { return .failure(.missingCbor) }
        return GmrtdGoRuntime.serialized {
            guard var verifier = GmrtdMobileNewVerifier() else {
                return .failure(.verifierUnavailable)
            }
            do {
                if let aaChallenge {
                    verifier = try verifier.withAAChallenge(aaChallenge) ?? verifier
                }
                let doc = try verifier.verify(cborData)
                let technicalData = try doc.documentExJson()
                let summaryData = try doc.summaryJson()
                guard let technicalStr = String(data: technicalData, encoding: .utf8),
                      let summaryStr = String(data: summaryData, encoding: .utf8) else {
                    return .failure(.invalidUtf8)
                }
                return .success(RegeneratedDocument(summaryJson: summaryStr, technicalJson: technicalStr))
            } catch {
                return .failure(.verificationFailed(underlying: error))
            }
        }
    }
}

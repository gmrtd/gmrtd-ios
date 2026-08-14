//
//  SampleDocument.swift
//  GmrtdKit
//

import Foundation
import Gmrtd

public enum SampleDocument {
    /// Loads gmrtd's built-in sample document (used for demo/onboarding flows).
    public static func load() throws -> MRTDReadResult {
        try GmrtdGoRuntime.serialized {
            var err: NSError?
            guard let doc = GmrtdMobileNewSampleDocument(&err) else {
                throw err ?? NSError(domain: "GmrtdKit", code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "Sample document unavailable"])
            }
            let summaryJson = try doc.summaryJson()
            let cbor = try? doc.documentExCbor()
            return MRTDReadResult(cborData: cbor, summaryJson: summaryJson)
        }
    }
}

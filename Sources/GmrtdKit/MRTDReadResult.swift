//
//  MRTDReadResult.swift
//  GmrtdKit
//

import Foundation

/// The data extracted from a successfully read MRTD chip.
public struct MRTDReadResult: Sendable {
    public let cborData: Data?
    public let summaryJson: Data?
    /// The caller-supplied Active Authentication challenge used during this read, if any.
    /// Persist alongside `cborData` and pass it back into
    /// `DocumentJsonRegenerator.regenerate` so re-verification can bind to the same
    /// nonce (see `GmrtdGoRuntime` / `MRTDReader.withAAChallenge` for why this matters).
    public let aaChallenge: Data?

    public init(cborData: Data?, summaryJson: Data?, aaChallenge: Data? = nil) {
        self.cborData = cborData
        self.summaryJson = summaryJson
        self.aaChallenge = aaChallenge
    }
}

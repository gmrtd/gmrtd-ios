//
//  MRZLocator.swift
//  GmrtdKit
//

import Foundation

private enum MRZLineLength {
    static let td1 = 30
    static let td2 = 36
    static let td3 = 44
    static let valid: Set<Int> = [td1, td2, td3]
}

private enum MRZLineCount {
    static let td1 = 3
    static let td2 = 2
    static let td3 = 2
}

public struct MRZLocateResult {
    public let mrz: String?
    public let potentialIndices: [Int]
    public let matchedIndices: [Int]
    public let candidatesTried: Int
}

// NB this doesn't guarantee the MRZ is 100% valid.. it just appears valid (i.e. length + check-digits)
//   - it is possible for some characters to be wrong (e.g. name characters which don't come under checkdigit)

/// Scans an array of text lines (e.g. OCR output) for a structurally valid MRZ (TD1/TD2/TD3).
/// Tries TD3 first since it's the most common (passport) format.
public func locateMRZ(in lines: [String]) -> MRZLocateResult {
    let potentialIdx: [Int] = lines.enumerated()
        .filter { MRZLineLength.valid.contains($0.element.count) }
        .map { $0.offset }

    var candidatesTried = 0

    // TD3 (2*44)
    if let match = locateMRZEx(lineLength: MRZLineLength.td3, numLines: MRZLineCount.td3, lines: lines, potentialIdx: potentialIdx, candidatesTried: &candidatesTried) {
        return MRZLocateResult(mrz: match.mrz, potentialIndices: potentialIdx, matchedIndices: match.lineIdx, candidatesTried: candidatesTried)
    }

    // TD1 (3*30)
    if let match = locateMRZEx(lineLength: MRZLineLength.td1, numLines: MRZLineCount.td1, lines: lines, potentialIdx: potentialIdx, candidatesTried: &candidatesTried) {
        return MRZLocateResult(mrz: match.mrz, potentialIndices: potentialIdx, matchedIndices: match.lineIdx, candidatesTried: candidatesTried)
    }

    // TD2 (2*36)
    if let match = locateMRZEx(lineLength: MRZLineLength.td2, numLines: MRZLineCount.td2, lines: lines, potentialIdx: potentialIdx, candidatesTried: &candidatesTried) {
        return MRZLocateResult(mrz: match.mrz, potentialIndices: potentialIdx, matchedIndices: match.lineIdx, candidatesTried: candidatesTried)
    }

    return MRZLocateResult(mrz: nil, potentialIndices: potentialIdx, matchedIndices: [], candidatesTried: candidatesTried)
}

// attempts to locate a specific MRZ based on the criteria (numLines & lineLength)
// implements a simple sliding window to evaluate adjacent lines (e.g. if 5 lines then could match idx:2-3)
// returns: valid MRZ and associated indices (mapping to `lines`) or nil
private func locateMRZEx(lineLength: Int, numLines: Int, lines: [String], potentialIdx: [Int], candidatesTried: inout Int) -> (mrz: String, lineIdx: [Int])? {
    let matchingLineIdx = potentialIdx.filter { i in
        lines.indices.contains(i) && lines[i].count == lineLength
    }

    guard matchingLineIdx.count >= numLines else { return nil }

    for idx in 0...(matchingLineIdx.count - numLines) {
        let lineIdx = Array(matchingLineIdx[idx..<idx + numLines])

        // construct the MRZ from the lines
        let mrz = lineIdx.compactMap { (i: Int) in
            lines.indices.contains(i) ? lines[i] : nil
        }.joined()

        // Guard against non-ASCII OCR noise: Go's len() counts UTF-8 bytes, not characters,
        // so a single multi-byte character (e.g. Å from OCR noise) shifts the byte count and
        // causes GMRTD to reject the string as an unsupported MRZ length.
        guard mrz.utf8.count == numLines * lineLength else { continue }

        candidatesTried += 1
        // test whether this is a valid MRZ (characters + checkdigits)
        if isValidMRZ(mrz) {
            return (mrz, lineIdx)
        }
    }

    return nil
}

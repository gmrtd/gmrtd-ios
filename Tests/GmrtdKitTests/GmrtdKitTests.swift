//
//  GmrtdKitTests.swift
//  GmrtdKitTests
//

import Foundation
import Testing
@testable import GmrtdKit

// Serialized: concurrent calls into the gmrtd Go library from multiple threads
// crash the Go runtime, which Swift Testing's default parallel execution triggers.
// GmrtdGoRuntime.serialized protects production call sites; this protects the
// test run itself.
@Suite(.serialized)
struct GmrtdKitTests {

    // Canonical ICAO Doc 9303 TD3 example (Anna Maria Eriksson) — real, valid
    // check digits throughout, including the composite.
    static let validTD3Line1 = "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<"
    static let validTD3Line2 = "L898902C36UTO7408122F1204159ZE184226B<<<<<10"

    // MARK: - locateMRZ

    @Test func locatesTD3MRZAmongNoisyOCRLines() {
        let lines = [
            "PASSPORT",
            "some ocr noise line",
            Self.validTD3Line1,
            Self.validTD3Line2,
            "trailing noise",
        ]
        let result = locateMRZ(in: lines)
        #expect(result.mrz == Self.validTD3Line1 + Self.validTD3Line2)
        #expect(result.matchedIndices == [2, 3])
    }

    @Test func returnsNilWhenNoValidMRZPresent() {
        let lines = ["not an mrz", "still not an mrz"]
        let result = locateMRZ(in: lines)
        #expect(result.mrz == nil)
        #expect(result.matchedIndices.isEmpty)
    }

    @Test func ignoresLinesWithWrongLengthEvenIfAdjacent() {
        // 44-char candidate lines but only one of them — not enough for a TD3 pair.
        let lines = [Self.validTD3Line1, "too short"]
        let result = locateMRZ(in: lines)
        #expect(result.mrz == nil)
        #expect(result.potentialIndices == [0])
    }

    // MARK: - isValidMRZ

    @Test func validatesKnownGoodMRZ() {
        #expect(isValidMRZ(Self.validTD3Line1 + Self.validTD3Line2))
    }

    @Test func rejectsGarbageMRZ() {
        #expect(!isValidMRZ("not an mrz at all"))
    }

    // MARK: - SampleDocument / DocumentJsonRegenerator round-trip

    @Test func sampleDocumentRegeneratesJsonFromItsOwnCbor() throws {
        let sample = try SampleDocument.load()
        let cbor = try #require(sample.cborData)
        #expect(cbor.count > 0)

        let result = DocumentJsonRegenerator.regenerate(fromCbor: cbor)
        switch result {
        case let .success(regenerated):
            #expect(regenerated.technicalJson.contains("nameOfHolder"))
            #expect(regenerated.technicalJson.contains("documentNumber"))
            #expect(regenerated.summary.identityAttributes != nil)
        case let .failure(error):
            Issue.record("regeneration failed: \(error)")
        }
    }

    // Pins the native DocumentSummary decoding against the sample document's known
    // (TD2/DG11/DG16 worked-example) field values. If a future gmrtd release changes
    // DocumentSummary's JSON shape, this fails loudly instead of silently dropping
    // fields via a schema mismatch — see DocumentSummary's doc comment.
    @Test func sampleDocumentSummaryDecodesExpectedFields() throws {
        let sample = try SampleDocument.load()
        let summary = try #require(sample.summary)

        // Passive Authentication is expected to fail for the sample document (its DGs
        // are sourced from different worked examples than its EF.SOD) — see
        // gmrtd's document.SampleDocument doc comment.
        #expect(summary.dataTrusted == false)
        #expect(summary.chipAuthenticity == .none)

        let identity = try #require(summary.identityAttributes)
        #expect(identity.documentNumber == "D23145890")
        #expect(identity.sex == "F")
        #expect(identity.dateOfBirthMrzRaw == "740812")
        #expect(identity.dateOfExpiry == "20120415")
        #expect(identity.nationality?.alpha3 == "UTO")
        #expect((identity.faceImages?.count ?? 0) > 0)
        #expect((identity.personsToNotify?.count ?? 0) > 0)
    }

    @Test func missingCborProducesMissingCborError() {
        let result = DocumentJsonRegenerator.regenerate(fromCbor: nil)
        switch result {
        case .success:
            Issue.record("expected failure for nil cbor")
        case let .failure(error):
            guard case .missingCbor = error else {
                Issue.record("expected .missingCbor, got \(error)")
                return
            }
        }
    }

    // MARK: - AA challenge binding

    @Test func regenerationStillSucceedsWithAValidLengthChallengeSupplied() throws {
        // The sample document has no AA evidence, so supplying a challenge has
        // nothing to mismatch against — this just confirms threading a challenge
        // through doesn't break the ordinary (no-evidence) verification path.
        let sample = try SampleDocument.load()
        let cbor = try #require(sample.cborData)

        let result = DocumentJsonRegenerator.regenerate(fromCbor: cbor, aaChallenge: Data(repeating: 0x42, count: 8))
        switch result {
        case .success:
            break
        case let .failure(error):
            Issue.record("regeneration failed: \(error)")
        }
    }

    @Test func wrongLengthChallengeProducesVerificationFailedError() throws {
        let sample = try SampleDocument.load()
        let cbor = try #require(sample.cborData)

        let result = DocumentJsonRegenerator.regenerate(fromCbor: cbor, aaChallenge: Data([0x01, 0x02, 0x03]))
        switch result {
        case .success:
            Issue.record("expected failure for a non-8-byte challenge")
        case let .failure(error):
            guard case .verificationFailed = error else {
                Issue.record("expected .verificationFailed, got \(error)")
                return
            }
        }
    }

    @Test func readRejectsWrongLengthCallerSuppliedChallengeBeforeStartingASession() async {
        // No NFC hardware/entitlement in the test target — this only passes if
        // MRTDReader.read validates options.aaChallenge and fails immediately,
        // without ever reaching NFCTagReaderSession.
        let reader = MRTDReader()
        let options = MRTDReadOptions(aaChallenge: Data([0x01, 0x02, 0x03]))

        // `read` asserts it's called on the main thread (as documented) — Swift
        // Testing runs async tests on a background executor, so hop to main
        // explicitly to model a real call site rather than tripping that assertion.
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                reader.read(credential: .mrz(Self.validTD3Line1 + Self.validTD3Line2), options: options) { result in
                    switch result {
                    case .success:
                        Issue.record("expected failure for a non-8-byte aaChallenge")
                    case let .failure(error):
                        #expect(error == .invalidAAChallenge)
                    }
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Library version

    // Bumped by the automated gmrtd-release-tracking job alongside `gmrtdCoreVersion`
    // in Package.swift — keep this exact `let name = "value"` shape so the bot can
    // locate/replace by regex.
    static let expectedGmrtdCoreVersion = "1.1.2"

    // If this fails after a version/checksum bump, the release's xcframework zip
    // wasn't actually rebuilt at the tag it claims to be.
    @Test func libraryVersionMatchesThePinnedPackageVersion() {
        #expect(GmrtdKitVersionInfo.core == Self.expectedGmrtdCoreVersion)
    }

    // MARK: - Concurrency stress test

    // Reproduces the scenario that used to crash the Go scheduler: distinct gmrtd
    // entry points (MRZ validation, sample-document read, verify-from-CBOR, OID
    // lookup, version string) called simultaneously from many OS threads with no
    // shared Swift-level state between them. The real-world crash happened during
    // a multi-second NFC read session (many sequential Go calls spread over time)
    // racing a live isValidMRZ call from the UI thread — a fixed iteration count of
    // near-instant calls doesn't reliably create that overlap, so this instead runs
    // dedicated threads in tight loops for a fixed wall-clock duration, maximizing
    // the odds any two distinct entry points are inside the Go runtime at once.
    // If GmrtdGoRuntime's lock regresses (or a new call site forgets to route
    // through it), this should reproduce "fatal error: bulkBarrierPreWrite:
    // unaligned arguments" / SIGABRT.
    @Test func sustainedConcurrentLoadAcrossEntryPointsDoesNotCrashTheGoRuntime() throws {
        let sample = try SampleDocument.load()
        let cbor = try #require(sample.cborData)

        let duration: TimeInterval = 3.0
        let deadline = Date().addingTimeInterval(duration)
        let counter = Counter()

        let workers: [() -> Void] = [
            { while Date() < deadline {
                #expect(isValidMRZ(Self.validTD3Line1 + Self.validTD3Line2))
                counter.increment()
            } },
            { while Date() < deadline {
                if let loaded = try? SampleDocument.load() {
                    #expect(loaded.summary != nil)
                }
                counter.increment()
            } },
            { while Date() < deadline {
                let result = DocumentJsonRegenerator.regenerate(fromCbor: cbor)
                if case .failure(let error) = result {
                    Issue.record("regeneration failed under concurrency: \(error)")
                }
                counter.increment()
            } },
            { while Date() < deadline {
                #expect(!oidDescription("2.23.136.1.1.1").isEmpty)
                counter.increment()
            } },
            { while Date() < deadline {
                #expect(!GmrtdKitVersionInfo.core.isEmpty)
                counter.increment()
            } },
        ]

        // Run several instances of each worker concurrently (real Foundation Threads,
        // not GCD-queued blocks) so overlapping entry points is the common case, not
        // a rare one.
        let threadsPerWorker = 4
        let group = DispatchGroup()
        for worker in workers {
            for _ in 0..<threadsPerWorker {
                group.enter()
                let thread = Thread {
                    worker()
                    group.leave()
                }
                thread.stackSize = 1 << 20
                thread.start()
            }
        }
        group.wait()

        #expect(counter.value > 0)
    }
}

/// Thread-safe counter for tallying completions from `DispatchQueue.concurrentPerform`.
private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
    }
}

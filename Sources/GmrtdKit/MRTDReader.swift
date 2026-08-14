//
//  MRTDReader.swift
//  GmrtdKit
//

import Foundation
import CoreNFC
import Security
import Gmrtd

/// Drives an NFC session end-to-end to read an MRTD (passport/ID card) chip via gmrtd:
/// polling, APDU transport, PACE/BAC negotiation, and data group extraction.
///
/// `@unchecked Sendable`: every stored property is either behind `stateLock` (all of
/// `State`, including `onStatus`/`onChipConnected` below) or `gmrtdReader`, which is
/// covered by `GmrtdGoRuntime`'s own lock instead (see its doc comment). Nothing on
/// this type is unsynchronized plain mutable state.
public final class MRTDReader: NSObject, @unchecked Sendable {
    /// Structured progress updates, fired on the main thread.
    public var onStatus: (@Sendable (MRTDReadStatus) -> Void)? {
        get { withState { $0.onStatus } }
        set { withState { $0.onStatus = newValue } }
    }
    /// Fired on the main thread the moment the ISO7816 chip connection is established.
    /// Use this to start progress / haptic feedback in the UI. The parameter is the
    /// AID iOS auto-selected during polling (`NFCISO7816Tag.initialSelectedAID`),
    /// handed up for callers who want to record it (e.g. in analytics).
    public var onChipConnected: (@Sendable (String) -> Void)? {
        get { withState { $0.onChipConnected } }
        set { withState { $0.onChipConnected = newValue } }
    }

    /// Per-read state touched from both the main thread (`read`, delegate callbacks)
    /// and the background queue `readMrtd` dispatches the Go work onto. `cancel()` in
    /// particular is documented as callable from any thread, so e.g. `session` can be
    /// written on main while read concurrently from a caller's watchdog timer. Bundled
    /// into one struct behind one lock so every access site is guarded the same way,
    /// rather than relying on GCD happens-before ordering to reason about each
    /// property individually. `gmrtdReader` is deliberately excluded — see its own
    /// doc comment below.
    private struct State {
        var onStatus: (@Sendable (MRTDReadStatus) -> Void)?
        var onChipConnected: (@Sendable (String) -> Void)?
        var credential: MRTDCredential?
        var options = MRTDReadOptions()
        var completionHandler: (@Sendable (Result<MRTDReadResult, MRTDReadError>) -> Void)?
        var isFinished = false
        var session: NFCTagReaderSession?
        var nfcTag: NFCISO7816Tag?
    }

    private let stateLock = NSLock()
    private var state = State()

    private func withState<T>(_ body: (inout State) -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body(&state)
    }

    /// Deliberately not part of `State`/`stateLock` — every touch of `gmrtdReader` is
    /// already confined to a single `GmrtdGoRuntime.serialized` closure (see
    /// `readMrtd`), so it never needs a second, independent lock. It's also cleared
    /// from *inside* that closure specifically to avoid the ARC dealloc race described
    /// on `GmrtdGoRuntime` — folding it into `withState` would risk dropping the last
    /// reference outside that lock's scope.
    private var gmrtdReader: GmrtdMobileReader?

    public override init() {
        super.init()
    }

    /// Starts an NFC session and reads the document. Must be called from the main thread.
    ///
    /// See `MRTDReadOptions.aaChallenge` — for real relay-attack protection, supply a
    /// challenge sourced from your relying party (server) via `options`, rather than
    /// relying on the locally-generated fallback.
    public func read(credential: MRTDCredential,
                      options: MRTDReadOptions = MRTDReadOptions(),
                      completion: @escaping @Sendable (Result<MRTDReadResult, MRTDReadError>) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        if let challenge = options.aaChallenge, challenge.count != 8 {
            completion(.failure(.invalidAAChallenge))
            return
        }
        withState {
            $0.credential = credential
            $0.options = options
            $0.completionHandler = completion
            $0.isFinished = false
        }
        startNFCSession()
    }

    /// Cancels an in-flight read, e.g. from a caller-side watchdog timeout. Safe to
    /// call from any thread. The completion handler passed to `read` is still called,
    /// with `.failure(.interrupted)`, once the session finishes invalidating.
    public func cancel() {
        withState { $0.session }?.invalidate()
    }

    /// Calls `completionHandler` exactly once and clears it, `credential` (which may
    /// hold a raw MRZ/CAN), and `nfcTag` so they don't linger on this instance after
    /// the read is done. Safe to call redundantly — e.g. from both `readMrtd`'s own
    /// outcome and the `didInvalidateWithError` delegate callback that follows the
    /// `session.invalidate()` it triggers.
    private func claimCompletionHandler() -> (@Sendable (Result<MRTDReadResult, MRTDReadError>) -> Void)? {
        withState { state in
            guard !state.isFinished else { return nil }
            state.isFinished = true
            let handler = state.completionHandler
            state.completionHandler = nil
            state.credential = nil
            state.nfcTag = nil
            return handler
        }
    }

    // NB must be called from main thread — enforced by `read`'s dispatchPrecondition,
    // since this is only ever reached via `read`.
    private func startNFCSession() {
        guard NFCTagReaderSession.readingAvailable else {
            claimCompletionHandler()?(.failure(.interrupted(underlying: "NFCTagReaderSession.readingAvailable is false")))
            return
        }

        // Include .pace so PACE-capable chips (ID cards, modern passports) can negotiate PACE;
        // .iso14443 ensures BAC-only chips are still discovered. Pre-iOS 16 has no .pace option.
        // options.includePaceInPolling forces .iso14443-only polling for connectivity testing.
        let includePaceInPolling = withState { $0.options.includePaceInPolling }
        let pollingOption: NFCTagReaderSession.PollingOption = if #available(iOS 16, *), includePaceInPolling {
            [.pace, .iso14443]
        } else {
            .iso14443
        }

        let newSession = NFCTagReaderSession(pollingOption: [pollingOption], delegate: self, queue: nil)
        newSession?.alertMessage = "Hold your document near the NFC reader."
        withState { $0.session = newSession }
        newSession?.begin()
    }

    private func readMrtd(to tag: NFCISO7816Tag, in session: NFCTagReaderSession) {
        // record the tag - for transceiver to use during callback from library
        withState { $0.nfcTag = tag }

        DispatchQueue.global().async {
            // Snapshot once under the lock rather than re-acquiring it for every
            // field — both are value types (Sendable), so a copy is all this needs,
            // and it keeps the lock held for microseconds instead of the whole
            // (potentially multi-second) Go call below.
            let (credential, options) = self.withState { ($0.credential!, $0.options) }

            let result = GmrtdGoRuntime.serialized { () -> Result<MRTDReadResult, MRTDReadError> in
                // Drop our reference to the gomobile reader wrapper before releasing
                // the lock, whichever path out of this closure is taken. Letting ARC
                // free it later, on whatever thread happens to hold the last
                // reference, is the dealloc race described on `GmrtdGoRuntime`.
                defer { self.gmrtdReader = nil }

                var gmrtdPassword: GmrtdMobileMrtdPassword?

                var err: NSError?
                switch credential {
                case .mrz(let s): gmrtdPassword = GmrtdMobileNewPasswordMrz(s, &err)
                case .can(let c): gmrtdPassword = GmrtdMobileNewPasswordCan(c, &err)
                }
                if let err {
                    #if DEBUG
                    print("credential password error: \(err)")
                    #endif
                    return .failure(MRTDReadError.classify(err))
                }

                self.gmrtdReader = GmrtdMobileNewReader(self, self)

                if options.skipPace {
                    self.gmrtdReader?.skipPace()
                }

                if options.skipImages {
                    self.gmrtdReader?.skipImages()
                }

                // Bind an AA challenge rather than relying on the library's internally
                // generated one, so the same nonce can be passed back in at verification
                // time. `options.aaChallenge` (already length-checked in `read`) is used
                // when the caller supplied one — see MRTDReadOptions.aaChallenge's doc
                // comment: only a challenge sourced from the verifying party gives real
                // relay-attack protection. Otherwise fall back to a locally-generated one,
                // which still binds this read to its own later on-device re-verification.
                var aaChallenge: Data?
                var challengeToUse: Data? = options.aaChallenge
                if challengeToUse == nil {
                    var randomBytes = [UInt8](repeating: 0, count: 8)
                    if SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes) == errSecSuccess {
                        challengeToUse = Data(randomBytes)
                    }
                }
                if let challengeToUse {
                    do {
                        _ = try self.gmrtdReader?.withAAChallenge(challengeToUse)
                        aaChallenge = challengeToUse
                    } catch {
                        #if DEBUG
                        print("gmrtd.withAAChallenge error: \(error)")
                        #endif
                    }
                }

                if options.extendedLength {
                    do {
                        try self.gmrtdReader?.setApduMaxLe(65536)
                    } catch {
                        #if DEBUG
                        print("gmrtd.setApduMaxLe error: \(error)")
                        #endif
                    }
                }

                var gmrtdDocument: GmrtdMobileDocument?

                do {
                    try gmrtdDocument = self.gmrtdReader?.readDocument(gmrtdPassword, atr: Data(), ats: Data())
                } catch {
                    #if DEBUG
                    print("gmrtd.readDocument error: \(error)")
                    #endif
                    return .failure(MRTDReadError.classify(error))
                }

                var gmrtdSummaryJson: Data?

                do {
                    gmrtdSummaryJson = try gmrtdDocument?.summaryJson()
                } catch {
                    #if DEBUG
                    print("gmrtd.summaryJson error: \(error)")
                    #endif
                    return .failure(MRTDReadError.classify(error))
                }

                var gmrtdCbor: Data?
                do {
                    gmrtdCbor = try gmrtdDocument?.documentExCbor()
                } catch {
                    #if DEBUG
                    print("gmrtd.documentExCbor error: \(error)")
                    #endif
                }

                return .success(MRTDReadResult(cborData: gmrtdCbor, summaryJson: gmrtdSummaryJson, aaChallenge: aaChallenge))
            }

            switch result {
            case .success(let readResult):
                DispatchQueue.main.async {
                    let handler = self.claimCompletionHandler()
                    session.invalidate()

                    // Delay before the NFC screen disappears — completion runs slightly after invalidate.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        handler?(.success(readResult))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.withState { $0.session }?.invalidate()
                    self.claimCompletionHandler()?(.failure(error))
                }
            }
        }
    }
}

// MARK: - GmrtdMobileTransceiverProtocol

extension MRTDReader: GmrtdMobileTransceiverProtocol {
    public func transceive(_ cla: Int, ins: Int, p2: Int, p3: Int, data: Data?, le: Int, encodedData: Data?) -> Data? {
        // looks like apple wants -1 for zero length, so map 0 -> -1
        var tmpLe = le
        if tmpLe == 0 {
            tmpLe = -1
        }

        // NB - p1/p2 arguments here are actually p2/p3 on the wire (gomobile parameter naming)
        let cApdu = NFCISO7816APDU(
            instructionClass: UInt8(cla),
            instructionCode: UInt8(ins),
            p1Parameter: UInt8(p2),
            p2Parameter: UInt8(p3),
            data: data ?? Data(),
            expectedResponseLength: tmpLe
        )

        var rApduResponse: Data = Data()
        var rApduSw1: UInt8 = 0
        var rApduSw2: UInt8 = 0

        let semaphore = DispatchSemaphore(value: 0)

        let tag = withState { $0.nfcTag }
        tag?.sendCommand(apdu: cApdu) { (response, sw1, sw2, error) in
            if error != nil {
                // 6F00: Command aborted – more exact diagnosis not possible.
                rApduSw1 = 0x6F
                rApduSw2 = 0x00
            } else {
                rApduResponse = response
                rApduSw1 = sw1
                rApduSw2 = sw2
            }
            semaphore.signal()
        }

        let waitResult = semaphore.wait(timeout: .now() + 10.0)
        if waitResult == .timedOut {
            // Tag lost mid-APDU — return a general error status word so the
            // GMRTD library surfaces a failure rather than blocking forever.
            rApduSw1 = 0x6F
            rApduSw2 = 0x00
        }

        var tmpData = Data()
        tmpData.append(rApduResponse)
        tmpData.append(rApduSw1)
        tmpData.append(rApduSw2)

        return Data(tmpData)
    }
}

// MARK: - GmrtdMobileReaderStatusProtocol

extension MRTDReader: GmrtdMobileReaderStatusProtocol {
    public func status(_ phase: Int, dataGroup: Int) {
        let status = MRTDReadStatus.classify(phase: phase, dataGroup: dataGroup)
        DispatchQueue.main.async {
            self.withState { $0.session }?.alertMessage = status.defaultMessage
            self.onStatus?(status) // getter locks internally; closure itself runs unlocked
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension MRTDReader: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            DispatchQueue.main.async {
                session.invalidate(errorMessage: "No NFC tag found.")
            }
            return
        }
        session.connect(to: tag) { (error) in
            if let error = error {
                DispatchQueue.main.async {
                    session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                }
                return
            }

            switch tag {
            case .iso7816(let isoTag):
                let selectedAID = isoTag.initialSelectedAID
                DispatchQueue.main.async { self.onChipConnected?(selectedAID) }
                self.readMrtd(to: isoTag, in: session)
            default:
                DispatchQueue.main.async {
                    session.invalidate(errorMessage: "Unsupported NFC tag type.")
                }
            }
        }
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        #if DEBUG
        if let error = error as? NFCReaderError {
            print("NFC session invalidated: \(error.localizedDescription)")
        } else {
            print("NFC session invalidated: \(error)")
        }
        #endif

        // Fires for every invalidation, including ones `readMrtd` never gets to run
        // for (no tag detected, a `session.connect` failure, an unsupported tag type,
        // the user cancelling the system NFC sheet, or a caller-side `cancel()`).
        // `claimCompletionHandler` is a no-op if `readMrtd` already resolved the read
        // itself, so this only fires the completion handler for those early-exit paths.
        DispatchQueue.main.async {
            self.withState { $0.session = nil }
            self.claimCompletionHandler()?(.failure(MRTDReadError.classify(error)))
        }
    }
}

//
//  MRTDAlertMessage.swift
//  GmrtdKit
//

/// Every message GmrtdKit shows on the system NFC sheet, i.e. everything it sets as
/// `NFCTagReaderSession.alertMessage` or passes to `invalidate(errorMessage:)`.
///
/// Set `MRTDReader.alertMessageProvider` to supply your own (e.g. localized) text for
/// any of these; `defaultMessage` is used for whatever the provider leaves `nil`.
public enum MRTDAlertMessage: Sendable, Equatable {
    /// Shown when the NFC sheet first appears, before a chip is detected.
    case holdNearReader
    /// Progress update while the chip is being read.
    case status(MRTDReadStatus)
    /// The session detected no tag.
    case noTagFound
    /// Connecting to the detected tag failed. `underlying` is the (system-localized)
    /// `localizedDescription` of the CoreNFC error.
    case connectionError(underlying: String)
    /// The detected tag isn't an ISO 7816 tag, so it can't be an MRTD chip.
    case unsupportedTag

    /// GmrtdKit's built-in English text for this message.
    public var defaultMessage: String {
        switch self {
        case .holdNearReader: return "Hold your document near the NFC reader."
        case .status(let status): return status.defaultMessage
        case .noTagFound: return "No NFC tag found."
        case .connectionError(let underlying): return "Connection error: \(underlying)"
        case .unsupportedTag: return "Unsupported NFC tag type."
        }
    }
}

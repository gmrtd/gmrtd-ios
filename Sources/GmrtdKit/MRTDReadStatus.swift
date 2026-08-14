//
//  MRTDReadStatus.swift
//  GmrtdKit
//

import Gmrtd

/// Structured progress status for an in-flight MRTD read, classified from the
/// phase/data-group ints the gmrtd library reports. Cases mirror gmrtd's own
/// `STATUS_PHASE_*` stages (see reader/status.go) rather than a coarser
/// UI-level grouping, so callers with their own UI can distinguish every
/// stage the reader actually reports.
public enum MRTDReadStatus: Sendable {
    case connecting
    case readingCardAccess
    case pace
    case bac
    case readingDir
    case readingSecurityObject
    case readingCommonData
    case readingDataGroup(Int)
    case activeAuthentication
    case chipAuthentication
    case verifyingDocument
    case passiveAuthentication
    case finished
    case other(phase: Int)

    /// Plain-language default, used for the system NFC sheet's alert message.
    /// Callers with their own UI should switch on the case instead.
    public var defaultMessage: String {
        switch self {
        case .connecting: return "Connecting…"
        case .readingCardAccess: return "Reading card access settings…"
        case .pace: return "Authenticating (PACE)…"
        case .bac: return "Authenticating (BAC)…"
        case .readingDir: return "Reading document directory…"
        case .readingSecurityObject: return "Reading security object…"
        case .readingCommonData: return "Reading document details…"
        case .readingDataGroup(let dataGroup):
            switch dataGroup {
            case 1: return "Reading identity data…"
            case 2: return "Reading photo…"
            default: return "Reading data group \(dataGroup)…"
            }
        case .activeAuthentication: return "Active authentication…"
        case .chipAuthentication: return "Chip authentication…"
        case .verifyingDocument: return "Verifying document…"
        case .passiveAuthentication: return "Verifying passive authentication…"
        case .finished: return "Finished."
        case .other: return "Reading chip…"
        }
    }

    /// Maps a gmrtd `STATUS_PHASE_*` value (and, for
    /// `STATUS_PHASE_READING_DATA_GROUP`, the data-group number) to a structured
    /// status. `dataGroup` is 0 (and ignored) for every phase other than
    /// `STATUS_PHASE_READING_DATA_GROUP`.
    static func classify(phase: Int, dataGroup: Int) -> MRTDReadStatus {
        switch phase {
        case GmrtdMobileSTATUS_PHASE_CONNECTING: return .connecting
        case GmrtdMobileSTATUS_PHASE_READING_CARD_ACCESS: return .readingCardAccess
        case GmrtdMobileSTATUS_PHASE_ACCESS_CONTROL_PACE: return .pace
        case GmrtdMobileSTATUS_PHASE_ACCESS_CONTROL_BAC: return .bac
        case GmrtdMobileSTATUS_PHASE_READING_DIR: return .readingDir
        case GmrtdMobileSTATUS_PHASE_READING_SECURITY_OBJECT: return .readingSecurityObject
        case GmrtdMobileSTATUS_PHASE_READING_COMMON_DATA: return .readingCommonData
        case GmrtdMobileSTATUS_PHASE_READING_DATA_GROUP: return .readingDataGroup(dataGroup)
        case GmrtdMobileSTATUS_PHASE_ACTIVE_AUTHENTICATION: return .activeAuthentication
        case GmrtdMobileSTATUS_PHASE_CHIP_AUTHENTICATION: return .chipAuthentication
        case GmrtdMobileSTATUS_PHASE_VERIFYING_DOCUMENT: return .verifyingDocument
        case GmrtdMobileSTATUS_PHASE_PASSIVE_AUTHENTICATION: return .passiveAuthentication
        case GmrtdMobileSTATUS_PHASE_FINISHED: return .finished
        default:
            // Forward-compat: a future gmrtd release adds a phase this build
            // doesn't know about yet.
            return .other(phase: phase)
        }
    }
}

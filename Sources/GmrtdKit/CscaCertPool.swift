//
//  CscaCertPool.swift
//  GmrtdKit
//

import Foundation
import Gmrtd

public enum CscaCertPool {
    /// Preloads the CSCA trust anchor pool used to verify document signatures.
    /// This is a heavier one-time operation — call it off the main thread, once, at startup.
    ///
    /// Calling this ahead of time is not just an optimization: `MRTDReader.read` and
    /// `DocumentJsonRegenerator.regenerate` load the pool themselves (gmrtd's
    /// `getCscaCertPool` calls the same preload internally, gated by a `sync.Once`) if
    /// it isn't already loaded, so skipping this call doesn't skip the cost — it just
    /// defers it, silently, to whichever call happens to go first. Since every gmrtd
    /// entry point is serialized through `GmrtdGoRuntime.serialized`, that deferred
    /// load also blocks every other in-flight `Gmrtd` call (e.g. `isValidMRZ`) for its
    /// duration. Calling `preload()` once at startup keeps that cost off the critical
    /// path of a live NFC read. Safe to call more than once — later calls are cheap
    /// no-ops (the `sync.Once` gate).
    public static func preload() throws {
        try GmrtdGoRuntime.serialized {
            var error: NSError?
            GmrtdMobilePreloadCscaCertPool(&error)
            if let error {
                throw error
            }
        }
    }
}

//
//  GmrtdGoRuntime.swift
//  GmrtdKit
//

import Foundation

/// The bundled gmrtd Go runtime is not safe for concurrent entry. Distinct entry
/// points that share no state at the Swift level — e.g. `GmrtdMobileNewPasswordMrz`
/// (MRZ validation) running while `GmrtdMobileNewReader`/`GmrtdMobileNewVerifier`
/// (a document read/verify) is in flight on another thread — have been observed to
/// crash the Go scheduler (fatal error, SIGABRT), because both ultimately drive the
/// same Go runtime/GC. The per-instance mutex gmrtd added to Reader/Verifier only
/// serializes calls into that one instance; it does not stop two different entry
/// points from racing each other. Every call into `Gmrtd` from this package must go
/// through `GmrtdGoRuntime.serialized`.
///
/// That lock alone is not sufficient, though: gomobile's generated factory
/// functions (`GmrtdMobileNewSampleDocument`, `GmrtdMobileNewReader`,
/// `GmrtdMobileNewVerifier`, etc.) are not annotated `NS_RETURNS_RETAINED`, and
/// their names don't match ARC's `new*`/`alloc*` ownership convention (the capital
/// "New" is mid-identifier, not a leading lowercase "new"), so ARC treats their
/// return values as autoreleased rather than owned — confirmed by disassembling
/// Gmrtd.xcframework, where e.g. `GmrtdMobileNewSampleDocument` ends with a call to
/// `objc_autoreleaseReturnValue`. That means the actual release of these wrapper
/// objects (and the Go-side cgo call it triggers) can be deferred to whenever the
/// *ambient* autorelease pool next drains, which is not necessarily inside this
/// lock's scope — e.g. a raw `Thread` or a `DispatchQueue.global().async` block
/// drains its pool at the whole-block/whole-closure boundary, which can be after
/// `serialized` has already unlocked. Wrapping `body` in an explicit
/// `autoreleasepool` forces any such objects created during the call to actually
/// deallocate before the lock is released, regardless of that ambient boundary.
enum GmrtdGoRuntime {
    private static let lock = NSLock()

    static func serialized<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try autoreleasepool {
            try body()
        }
    }
}

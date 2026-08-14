//
//  MRZValidation.swift
//  GmrtdKit
//

import Foundation
import Gmrtd

/// Validates an MRZ string (characters + check digits) by attempting to construct a
/// gmrtd password from it, without performing an actual chip read.
public func isValidMRZ(_ mrz: String) -> Bool {
    GmrtdGoRuntime.serialized {
        var err: NSError?
        _ = GmrtdMobileNewPasswordMrz(mrz, &err)
        return err == nil
    }
}

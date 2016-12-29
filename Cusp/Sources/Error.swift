//
//  CuspError.swift
//  Cusp
//
//  Created by keyOfVv on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation

public enum CuspError: Error {
	case unknown
	
	case resetting
	case unsupported
	case unauthorized
	case poweredOff
	case timedOut

	case scanningCanceled

	case serviceNotFound
	case characteristicNotFound

	case invalidValueLength		// CBATTErrorDomain Code=13, The value's length is invalid.
	case connectionTimedOut		// CBErrorDomain Code=6, The connection has timed out unexpectedly.

	init(err: Error?) {
		guard let err = err else {
			self = CuspError.unknown
			return
		}
		switch (err as NSError).code {
		case 6:
			self = CuspError.connectionTimedOut
		case 13:
			self = CuspError.invalidValueLength
		default:
			self = CuspError.unknown
		}
	}
}

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
}

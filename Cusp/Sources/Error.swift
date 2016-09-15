//
//  CuspError.swift
//  Cusp
//
//  Created by keyOfVv on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation
import KEYExtension

extension Cusp {

	public enum Error: Error {
		case unknown
		case resetting
		case unsupported
		case unauthorized
		case poweredOff
//		case BusyScanning
		case timedOut

//		static var count: Int = {
//			var max: Int = 1
//			while let _ = Error(rawValue: max) {
//				max += 1
//			}
//			return max
//		}()
	}
}

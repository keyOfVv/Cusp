//
//  CuspError.swift
//  Cusp
//
//  Created by keyOfVv on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation

extension Cusp {

	public enum Error: Int {
		case Unknown
		case Resetting
		case Unsupported
		case Unauthorized
		case PoweredOff
		case BusyScanning
		case TimedOut

		static var count: Int = {
			var max: Int = 0
			while let _ = Error(rawValue: ++max) {}
			return max
		}()
	}
}
//
//  CuspPeripheral.swift
//  Cusp
//
//  Created by keyOfVv on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation
import CoreBluetooth

public typealias Peripheral = CBPeripheral

// MARK: - Cusp Peripheral

extension Peripheral {

	override public var hash: Int {
		return self.identifier.hashValue
	}

	override public func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? Peripheral {
			return self.identifier == other.identifier
		}
		return false
	}

}

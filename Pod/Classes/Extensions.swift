//
//  Extensions.swift
//  Pods
//
//  Created by Ke Yang on 2/20/16.
//
//

import Foundation
import CoreBluetooth

public typealias UUID           = CBUUID
public typealias CentralManager = CBCentralManager
//public typealias Peripheral     = CBPeripheral
public typealias Service        = CBService
public typealias Characteristic = CBCharacteristic
public typealias CharacteristicWriteType = CBCharacteristicWriteType


// MARK: - CBUUID

extension CBUUID {

	public override var hash: Int {
		return self.UUIDString.hashValue
	}

	public override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CBUUID {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CBPeripheral

extension CBPeripheral {

	public override var hash: Int {
		return self.identifier.hashValue
	}

	public override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CBPeripheral {
			return self.hashValue == other.hashValue
		}
		return false
	}

	/// 根据UUID字符串获取对应的服务
	func serviceWith(UUIDString UUIDString: String) -> CBService? {

		if let services = self.services {
			for aService in services {
				if (aService.UUID.UUIDString == UUIDString) {
					return aService
				}
			}
		}
		return nil
	}

	/// 根据UUID字符串获取对应的特征
	func characteristicWith(UUIDString UUIDString: String) -> CBCharacteristic? {

		if let services = self.services {
			for aService in services {
				if let characteristics = aService.characteristics {
					for aCharacteristics in characteristics {
						if (aCharacteristics.UUID.UUIDString == UUIDString) {
							return aCharacteristics
						}
					}
				}
			}
		}
		return nil
	}

}

// MARK: - CBService

extension CBService {
	
	public override var hash: Int {
		return self.UUID.hashValue
	}

	public override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CBService {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CBCharacteristic

extension CBCharacteristic {

	public override var hash: Int {
		return self.UUID.hashValue
	}

	public override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CBCharacteristic {
			return self.hashValue == other.hashValue
		}
		return false
	}
}


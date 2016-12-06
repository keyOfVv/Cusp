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

extension Foundation.UUID {

	public var hash: Int {
		return uuidString.hashValue
	}

	public func isEqual(_ object: Any?) -> Bool {
		if let other = object as? Foundation.UUID {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CBUUID

extension CBUUID {

	open override var hash: Int {
		return uuidString.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? CBUUID {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CBPeripheral

extension CBPeripheral {

	open override var hash: Int {
		return identifier.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? CBPeripheral {
			return self.hashValue == other.hashValue
		}
		return false
	}

	/// 根据UUID字符串获取对应的服务
	@available(*, deprecated, message: "use Peripheral's -serviceWith(UUIDString:) method instead")
	public func serviceWith(UUIDString: String) -> CBService? {

		if let services = self.services {
			for aService in services {
				if (aService.uuid.uuidString == UUIDString) {
					return aService
				}
			}
		}
		return nil
	}

	/// 根据UUID字符串获取对应的特征
	@available(*, deprecated, message: "use Peripheral's -characteristicWith(UUIDString:) method instead")
	public func characteristicWith(UUIDString: String) -> CBCharacteristic? {

		if let services = self.services {
			for aService in services {
				if let characteristics = aService.characteristics {
					for aCharacteristics in characteristics {
						if (aCharacteristics.uuid.uuidString == UUIDString) {
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
	
	open override var hash: Int {
		return uuid.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? CBService {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CBCharacteristic

extension CBCharacteristic {

	open override var hash: Int {
		return uuid.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? CBCharacteristic {
			return self.hashValue == other.hashValue
		}
		return false
	}
}


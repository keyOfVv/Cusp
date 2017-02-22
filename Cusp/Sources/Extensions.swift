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
public typealias Descriptor = CBDescriptor
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
	private func serviceWith(UUIDString: String) -> CBService? {

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
	private func characteristicWith(UUIDString: String) -> CBCharacteristic? {

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

// MARK: - CBDescriptor
extension CBDescriptor {

	open override var hash: Int {
		return uuid.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? CBDescriptor {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - String
extension String {

	var isValidUUID: Bool {
		do {
			// check with short pattern
			let shortP = "^[A-F0-9]{4}$"
			let shortRegex = try NSRegularExpression(pattern: shortP, options: NSRegularExpression.Options.caseInsensitive)
			let shortMatchNum = shortRegex.matches(in: self, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, self.characters.count))
			if shortMatchNum.count == 1 {
				return true
			}
			// check with full pattern
			let fullP = "^[A-F0-9\\-]{36}$"
			let fullRegex = try NSRegularExpression(pattern: fullP, options: NSRegularExpression.Options.caseInsensitive)
			let fullMatchNum = fullRegex.matches(in: self, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, self.characters.count))
			if fullMatchNum.count == 1 {
				return true
			}
		} catch {

		}
		return false
	}
}


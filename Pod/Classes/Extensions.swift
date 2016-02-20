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
public typealias Peripheral     = CBPeripheral
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
			return self.hash == other.hash
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
			return self.hash == other.hash
		}
		return false
	}
}

// MARK: - CBService

extension CBService {
	
	public override var hash: Int {
		return self.UUID.hashValue
	}

	public override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CBService {
			return self.hash == other.hash
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
			return self.hash == other.hash
		}
		return false
	}
}
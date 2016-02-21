//
//  Write.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

/// request of write value to specific characteristic
internal class WriteRequest: OperationRequest {

	// MARK: Stored Properties

	/// a NSData object to be written
	internal var data: NSData?

	/// a CBCharacteristic object on which the data will be written
	internal var characteristic: Characteristic!

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter data:           a NSData object to be written
	- parameter characteristic: a CBCharacteristic object on which the data will be written
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs
	- parameter success:        a closure called when value written successfully
	- parameter failure:        a closure called when value written failed

	- returns: a WriteRequest instance
	*/
	convenience init(data: NSData?, characteristic: Characteristic, peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
        self.data           = data
        self.characteristic = characteristic
        self.peripheral     = peripheral
        self.success        = success
        self.failure        = failure
	}

	override internal var hash: Int {
		let string = self.peripheral.identifier.UUIDString + self.characteristic.UUID.UUIDString
		return string.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? WriteRequest {
			return self.hash == other.hash
		}
		return false
	}
}

// MARK: Communicate
extension Cusp {

	/**
	Write value to specific characteristic of specific peripheral.
	向指定从设备的指定特征写值.

	- parameter data:           a NSData object to be written. 待写入的值
	- parameter characteristic: a CBCharacteristic object on which the data will be written. 待写值的特征
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs. 待写值的从设备.
	- parameter success:        a closure called when value written successfully. 写值成功时执行的闭包.
	- parameter failure:        a closure called when value written failed. 写值失败时执行的闭包.
	*/
	public func write(data: NSData, forCharacteristic characteristic: Characteristic, inPeripheral peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}
		
		dispatch_async(self.mainQ) { () -> Void in
			let req = WriteRequest(data: data, characteristic: characteristic, peripheral: peripheral, success: success, failure: failure)
			self.writeRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.writeValue(data, forCharacteristic: characteristic, type: CharacteristicWriteType.WithResponse)
				})
			}
		}
	}
}















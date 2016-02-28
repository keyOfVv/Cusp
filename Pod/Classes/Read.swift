//
//  Read.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

/// request of read value from specific characteristic
internal class ReadRequest: OperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value to be read
	internal var characteristic: Characteristic!

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristic: a CBCharacteristic object of which the value to be read
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs
	- parameter success:        a closure called when value read successfully
	- parameter failure:        a closure called when value read failed

	- returns: a ReadRequest instance
	*/
	convenience init(characteristic: Characteristic, peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
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
		if let other = object as? ReadRequest {
			return self.hash == other.hash
		}
		return false
	}
}

// MARK: Communicate
extension Cusp {

	/**
	Read value from a characteristic
	读取某个特征的值

	- parameter characteristic: a CBCharacteristic object of which the value to be read. 待读值的特征对象.
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs. 待读值的从设备.
	- parameter success:        a closure called when value read successfully. 读值成功时执行的闭包.
	- parameter failure:        a closure called when value read failed. 读值失败时执行的闭包.
	*/
	public func read(characteristic: Characteristic, inPeripheral peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}

		if let session = self.sessionFor(peripheral) {

			let req = ReadRequest(characteristic: characteristic, peripheral: peripheral, success: success, failure: failure)
			dispatch_async(session.reqOpQ, { () -> Void in
				self.readRequests.insert(req)
			})

			dispatch_async(session.sessionQ, { () -> Void in
				peripheral.readValueForCharacteristic(characteristic)
			})

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), session.sessionQ) { () -> Void in
				if req.timedOut {
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						let error = NSError(domain: "connect operation timed out", code: Error.TimedOut.rawValue, userInfo: nil)
						failure?(error)
					})
					dispatch_async(session.reqOpQ, { () -> Void in
						self.readRequests.remove(req)
					})
				}
			}
		}
	}
}

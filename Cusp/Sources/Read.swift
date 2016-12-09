//
//  Read.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation


/// request of read value from specific characteristic
internal class ReadRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value to be read
	internal var characteristic: Characteristic!

	// MARK: Initializer

	fileprivate override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristic: a CBCharacteristic object of which the value to be read
	- parameter success:        a closure called when value read successfully
	- parameter failure:        a closure called when value read failed

	- returns: a ReadRequest instance
	*/
	convenience init(characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
		self.characteristic = characteristic
		self.success        = success
		self.failure        = failure
	}

	override internal var hash: Int {
		let string = self.characteristic.uuid.uuidString
		return string.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		if let other = object as? ReadRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: Communicate
extension Peripheral {

	/**
	Read value from a characteristic
	读取某个特征的值

	- parameter characteristic: a CBCharacteristic object of which the value to be read. 待读值的特征对象.
	- parameter success:        a closure called when value read successfully. 读值成功时执行的闭包.
	- parameter failure:        a closure called when value read failed. 读值失败时执行的闭包.
	*/
	public func read(_ characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create req object
		let req = ReadRequest(characteristic: characteristic, success: success, failure: failure)
		// 2. add read req
		self.requestQ.async(execute: { () -> Void in
			self.readRequests.insert(req)
		})
		// 3. start reading value
		self.operationQ.async(execute: { () -> Void in
			self.core.readValue(for: characteristic)
		})
		// 4. set time out closure
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.readRequests.remove(req)
				})
			}
		}
	}
}

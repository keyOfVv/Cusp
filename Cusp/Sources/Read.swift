//
//  Read.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation


/// request of read value from specific characteristic
class ReadRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value to be read
	var characteristic: Characteristic!

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

	override var hash: Int {
		let string = self.characteristic.uuid.uuidString
		return string.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? ReadRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

/// request of read value from specific characteristic
class ReadDescriptorRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value to be read
	var descriptor: Descriptor!

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
	convenience init(descriptor: Descriptor, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
		self.descriptor = descriptor
		self.success        = success
		self.failure        = failure
	}

	override var hash: Int {
		let string = descriptor.uuid.uuidString
		return string.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? ReadDescriptorRequest {
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
	func read(_ characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
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

	public func readDescriptor(_ desc: Descriptor, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create req object
		let req = ReadDescriptorRequest(descriptor: desc, success: success, failure: failure)
		// 2. add read req
		requestQ.async(execute: { () -> Void in
			self.readDescriptorRequests.insert(req)
		})
		// 3. start reading value
		operationQ.async(execute: { () -> Void in
			self.core.readValue(for: desc)
			dog("begin read value for descriptor \(desc.uuid.uuidString)")
		})
		// 4. set time out closure
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.readDescriptorRequests.remove(req)
				})
			}
		}
	}

	public func read(characteristic c: String, ofService s: String, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		if !s.isValidUUID {
			failure?(CuspError.invalidServiceUUID)
			return
		}
		if !c.isValidUUID {
			failure?(CuspError.invalidCharacteristicUUID)
			return
		}
		if let service = self[s] {
			if let char = service[c] {
				read(char, success: success, failure: failure)
			} else {
				discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
					if let char = service[c] {
						self.read(char, success: success, failure: failure)
					} else {
						failure?(CuspError.characteristicNotFound)
					}
				}, failure: { (error) in
					failure?(error)
				})
			}
		} else {
			discoverServices(UUIDStrings: [s], success: { (resp) in
				if let service = self[s] {
					self.discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
						if let char = service[c] {
							self.read(char, success: success, failure: failure)
						} else {
							failure?(CuspError.characteristicNotFound)
						}
					}, failure: { (error) in
						failure?(error)
					})
				} else {
					failure?(CuspError.serviceNotFound)
				}
			}, failure: { (error) in
				failure?(error)
			})
		}
	}
}

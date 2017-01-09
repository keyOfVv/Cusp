//
//  Write.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation


/// request of write value to specific characteristic
class WriteRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a NSData object to be written
	var data: Data?

	/// a CBCharacteristic object on which the data will be written
	var characteristic: Characteristic!

	// MARK: Initializer

	fileprivate override init() {
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
	convenience init(data: Data?, characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
        self.data           = data
        self.characteristic = characteristic
        self.success        = success
        self.failure        = failure
	}

	override var hash: Int {
		let string = self.characteristic.uuid.uuidString
		return string.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? WriteRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

/// request of write value to specific characteristic
class WriteDescriptorRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a NSData object to be written
	var data: Data?

	/// a CBCharacteristic object on which the data will be written
	var descriptor: Descriptor!

	// MARK: Initializer

	fileprivate override init() {
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
	convenience init(data: Data?, descriptor: Descriptor, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
		self.data           = data
		self.descriptor		= descriptor
		self.success        = success
		self.failure        = failure
	}

	override var hash: Int {
		let string = descriptor.uuid.uuidString
		return string.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? WriteDescriptorRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: Communicate
extension Peripheral {

	/**
	Write value to specific characteristic of specific peripheral.
	向指定从设备的指定特征写值.

	- parameter data:           a NSData object to be written. 待写入的值
	- parameter characteristic: a CBCharacteristic object on which the data will be written. 待写值的特征
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs. 待写值的从设备.
	- parameter success:        a closure called when value written successfully. 写值成功时执行的闭包.
	- parameter failure:        a closure called when value written failed. 写值失败时执行的闭包.
	*/
	func write(_ data: Data, forCharacteristic characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = CuspCentral.central.assertAvailability() {
			failure?(error)
			return
		}

		let req = WriteRequest(data: data, characteristic: characteristic, success: success, failure: failure)
		self.requestQ.async(execute: { () -> Void in
			self.writeRequests.insert(req)
		})

		self.operationQ.async(execute: { () -> Void in
			self.core.writeValue(data, for: characteristic, type: CharacteristicWriteType.withResponse)
		})

		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				self.requestQ.async(execute: { () -> Void in
					self.writeRequests.remove(req)
				})
			}
		}
	}

	public func write(_ data: Data, forDescriptor desc: Descriptor, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = CuspCentral.central.assertAvailability() {
			failure?(error)
			return
		}

		let req = WriteDescriptorRequest(data: data, descriptor: desc, success: success, failure: failure)
		self.requestQ.async(execute: { () -> Void in
			self.writeDescriptorRequests.insert(req)
		})
		self.operationQ.async(execute: { () -> Void in
			self.core.writeValue(data, for: desc)
			dog("begin write value for descriptor \(desc.uuid.uuidString)")
		})
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				self.requestQ.async(execute: { () -> Void in
					self.writeDescriptorRequests.remove(req)
				})
			}
		}
	}

	public func write(_ d: Data, toCharacteristic c: String, ofService s: String, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
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
				write(d, forCharacteristic: char, success: success, failure: failure)
			} else {
				discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
					if let char = service[c] {
						self.write(d, forCharacteristic: char, success: success, failure: failure)
					} else {
						failure?(CuspError.characteristicNotFound)
					}
				}, failure: { (err) in
					failure?(err)
				})
			}
		} else {
			discoverServices(UUIDStrings: [s], success: { (resp) in
				if let service = self[s] {
					self.discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
						if let char = service[c] {
							self.write(d, forCharacteristic: char, success: success, failure: failure)
						} else {
							failure?(CuspError.characteristicNotFound)
						}
					}, failure: { (err) in
						failure?(err)
					})
				} else {
					failure?(CuspError.serviceNotFound)
				}
			}, failure: { (err) in
				failure?(err)
			})
		}
	}
}

func dog(_ anyObject: Any?, function: String = #function, file: String = #file, line: Int = #line) {
	if !CuspCentral.showsDebugLog {
		return
	}

	let dateFormat		  = DateFormatter()
	dateFormat.dateFormat = "HH:mm:ss.SSS"

	let date = NSDate()
	let time = dateFormat.string(from: date as Date)

	print("[\(time)] <\((file as NSString).lastPathComponent)> \(function) LINE(\(line)): \(anyObject)")
}













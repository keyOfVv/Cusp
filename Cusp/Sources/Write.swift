//
//  Write.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation


/// request of write value to specific characteristic
internal class WriteRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a NSData object to be written
	internal var data: Data?

	/// a CBCharacteristic object on which the data will be written
	internal var characteristic: Characteristic!

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

	override internal var hash: Int {
		let string = self.characteristic.uuid.uuidString
		return string.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		if let other = object as? WriteRequest {
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
	public func write(_ data: Data, forCharacteristic characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
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
}

func dog(_ anyObject: Any?, function: String = #function, file: String = #file, line: Int = #line) {
	if !Cusp.showsDebugLog {
		return
	}

	let dateFormat		  = DateFormatter()
	dateFormat.dateFormat = "HH:mm:ss.SSS"

	let date = NSDate()
	let time = dateFormat.string(from: date as Date)

	print("[\(time)] <\((file as NSString).lastPathComponent)> \(function) LINE(\(line)): \(anyObject)")
}













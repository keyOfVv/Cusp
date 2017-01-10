//
//  Unsubscribe.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

// MARK: UnsubscribeRequest

/// request of unsubscribe value update of specific characteristic
class UnsubscribeRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value update to be unsubscribed
	var characteristic: Characteristic!

	// MARK: Initializer

	fileprivate override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristic: a CBCharacteristic object of which the value update to be unsubscribed
	- parameter success:        a closure called when unsubscription succeed
	- parameter failure:        a closure called when unsubscription failed

	- returns: a UnsubscribeRequest instance
	*/
	convenience init(characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
        self.characteristic = characteristic
        self.success        = success
        self.failure        = failure
	}

	override var hash: Int {
		return characteristic.uuid.uuidString.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? UnsubscribeRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: Communicate
extension Peripheral {

	/**
	Unsubscribe value update of specific characteristic on specific peripheral
	取消订阅指定从设备的指定特征的数值变化

	- parameter characteristic: a CBCharacteristic object of which the value update to be unsubscribed. 待取消订阅数值更新的特征.
	- parameter success:        a closure called when unsubscription succeed. 取消订阅成功时执行的闭包.
	- parameter failure:        a closure called when unsubscription failed. 取消订阅失败时执行的闭包.
	*/
	func unsubscribe(_ characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = CuspCentral.defaultCentral.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create req
		let req = UnsubscribeRequest(characteristic: characteristic, success: success, failure: failure)
		// 2. add req
		self.requestQ.async(execute: { () -> Void in
			self.unsubscribeRequests.insert(req)
		})
		// 3. unsubscribe characteristic
		self.operationQ.async(execute: { () -> Void in
			self.core.setNotifyValue(false, for: characteristic)
		})
		// 4. set time out closure
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.unsubscribeRequests.remove(req)
				})
			}
		}
	}

	public func unsubscribe(characteristic c: String, ofService s: String, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
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
				unsubscribe(char, success: success, failure: failure)
			} else {
				discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
					if let char = service[c] {
						self.unsubscribe(char, success: success, failure: failure)
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
							self.unsubscribe(char, success: success, failure: failure)
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






//
//  Unsubscribe.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import KEYExtension

// MARK: UnsubscribeRequest

/// request of unsubscribe value update of specific characteristic
internal class UnsubscribeRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value update to be unsubscribed
	internal var characteristic: Characteristic!

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
	internal convenience init(characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
        self.characteristic = characteristic
        self.success        = success
        self.failure        = failure
	}

	override internal var hash: Int {
		return characteristic.uuid.uuidString.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
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
	public func unsubscribe(_ characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
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
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					let error = NSError(domain: "connect operation timed out", code: Cusp.Error.timedOut.rawValue, userInfo: nil)
					failure?(error)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.unsubscribeRequests.remove(req)
				})
			}
		}
	}
}





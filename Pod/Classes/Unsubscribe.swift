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
internal class UnsubscribeRequest: OperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value update to be unsubscribed
	internal var characteristic: Characteristic!

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristic: a CBCharacteristic object of which the value update to be unsubscribed
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs
	- parameter success:        a closure called when unsubscription succeed
	- parameter failure:        a closure called when unsubscription failed

	- returns: a UnsubscribeRequest instance
	*/
	internal convenience init(characteristic: Characteristic, peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
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
		if let other = object as? UnsubscribeRequest {
			return self.hash == other.hash
		}
		return false
	}
}

// MARK: Communicate
extension Cusp {

	/**
	Unsubscribe value update of specific characteristic on specific peripheral
	取消订阅指定从设备的指定特征的数值变化

	- parameter characteristic: a CBCharacteristic object of which the value update to be unsubscribed. 待取消订阅数值更新的特征.
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs. 特征所属的从设备.
	- parameter success:        a closure called when unsubscription succeed. 取消订阅成功时执行的闭包.
	- parameter failure:        a closure called when unsubscription failed. 取消订阅失败时执行的闭包.
	*/
	public func unsubscribe(characteristic: Characteristic, inPeripheral peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}

		if let session = self.sessionFor(peripheral) {

			let req = UnsubscribeRequest(characteristic: characteristic, peripheral: peripheral, success: success, failure: failure)
			dispatch_barrier_async(session.sessionQ, { () -> Void in
				self.unsubscribeRequests.insert(req)
			})

			dispatch_async(session.sessionQ, { () -> Void in
				peripheral.setNotifyValue(false, forCharacteristic: characteristic)
			})

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), session.sessionQ) { () -> Void in
				if req.timedOut {
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						let error = NSError(domain: "connect operation timed out", code: Error.TimedOut.rawValue, userInfo: nil)
						failure?(error)
					})
					dispatch_barrier_async(session.sessionQ, { () -> Void in
						self.unsubscribeRequests.remove(req)
					})
				}
			}
		}
	}
}






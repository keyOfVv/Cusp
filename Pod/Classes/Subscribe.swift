//
//  Subscribe.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

// MARK: SubscribeRequest

/// request of subscribe value update of specific characteristic
internal class SubscribeRequest: OperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value update to be subscribed
	internal var characteristic: Characteristic!

	/// a closure called when characteristic's value updated
	internal var update: ((NSData?) -> Void)?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristic: a CBCharacteristic object of which the value update to be subscribed
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs
	- parameter success:        a closure called when subscription succeed
	- parameter failure:        a closure called when subscription failed
	- parameter update:         a closure called when characteristic's value updated

	- returns: a SubscribeRequest instance
	*/
	internal convenience init(characteristic: Characteristic, peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, update: ((NSData?) -> Void)?) {
		self.init()
        self.characteristic = characteristic
        self.peripheral     = peripheral
        self.success        = success
        self.failure        = failure
        self.update         = update
	}

	override internal var hash: Int {
		let string = self.peripheral.identifier.UUIDString + self.characteristic.UUID.UUIDString
		return string.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? SubscribeRequest {
			return self.hash == other.hash
		}
		return false
	}
	
}

// MARK: Communicate
extension Cusp {

	/**
	Subscribe value update of specific characteristic on specific peripheral
	订阅指定从设备的指定特征的数值变化

	- parameter characteristic: a CBCharacteristic object of which the value update to be subscribed. 待订阅数值更新的特征.
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs. 特征所属的从设备.
	- parameter success:        a closure called when subscription succeed. 订阅成功时执行的闭包.
	- parameter failure:        a closure called when subscription failed. 订阅失败时执行的闭包.
	- parameter update:         a closure called when characteristic's value updated. 数值更新时执行的闭包.
	*/
	public func subscribe(characteristic: Characteristic, inPeripheral peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, update: ((NSData?) -> Void)?) {
		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}

		if let session = self.sessionFor(peripheral) {

			let req = SubscribeRequest(characteristic: characteristic, peripheral: peripheral, success: success, failure: failure, update: update)
			dispatch_barrier_async(session.sessionQ, { () -> Void in
				self.subscribeRequests.insert(req)
			})

			dispatch_async(session.sessionQ, { () -> Void in
				peripheral.setNotifyValue(true, forCharacteristic: characteristic)
			})

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), session.sessionQ) { () -> Void in
				if req.timedOut {
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						let error = NSError(domain: "connect operation timed out", code: Error.TimedOut.rawValue, userInfo: nil)
						failure?(error)
					})
					dispatch_barrier_async(session.sessionQ, { () -> Void in
						self.subscribeRequests.remove(req)
					})
				}
			}
		}
	}
}
















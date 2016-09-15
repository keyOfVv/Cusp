//
//  Subscribe.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import KEYExtension

// MARK: SubscribeRequest

/// request of subscribe value update of specific characteristic
internal class SubscribeRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value update to be subscribed
	internal var characteristic: Characteristic!

	/// a closure called when characteristic's value updated
	internal var update: ((Response?) -> Void)?

	// MARK: Initializer

	fileprivate override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristic: a CBCharacteristic object of which the value update to be subscribed
	- parameter peripheral:     a CBPeripheral object to which the characteristic belongs
	- parameter success:        a closure called when subscription succeed
	- parameter failure:        a closure called when subscription failed
	- parameter update:         a closure called when characteristic's value updated, after successfully subscribed, the update closure will be wrapped in Subscription object

	- returns: a SubscribeRequest instance
	*/
	internal convenience init(characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, update: ((Response?) -> Void)?) {
		self.init()
        self.characteristic = characteristic
        self.success        = success
        self.failure        = failure
        self.update         = update
	}

	override internal var hash: Int {
		return characteristic.uuid.uuidString.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		if let other = object as? SubscribeRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
	
}

// MARK: Communicate
extension Peripheral {

	/**
	Subscribe value update of specific characteristic on specific peripheral

	- parameter characteristic: a CBCharacteristic object of which the value update to be subscribed.
	- parameter success:        a closure called when subscription succeed.
	- parameter failure:        a closure called when subscription failed.
	- parameter update:         a closure called when characteristic's value updated, after successfully subscribed, the update closure will be wrapped in Subscription object.
	*/
	public func subscribe(_ characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, update: ((Response?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create req object
		let req = SubscribeRequest(characteristic: characteristic, success: success, failure: failure, update: update)
		// 2. add req
		self.requestQ.async(execute: { () -> Void in
			self.subscribeRequests.insert(req)
		})
		// 3. subscribe characteristic
		self.operationQ.async(execute: { () -> Void in
			self.core.setNotifyValue(true, for: characteristic)
		})
		// 4. set time out closure
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					let error = NSError(domain: "subscription timed out", code: Cusp.Error.timedOut.rawValue, userInfo: nil)
					failure?(error)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.subscribeRequests.remove(req)
				})
			}
		}
	}
}
















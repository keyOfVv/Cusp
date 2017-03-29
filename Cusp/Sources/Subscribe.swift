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
class SubscribeRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// a CBCharacteristic object of which the value update to be subscribed
	var characteristic: Characteristic!

	/// a closure called when characteristic's value updated
	var update: ((Data?) -> Void)?

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
	convenience init(characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?, update: ((Data?) -> Void)?) {
		self.init()
        self.characteristic = characteristic
        self.success        = success
        self.failure        = failure
        self.update         = update
	}

	override var hash: Int {
		return characteristic.uuid.uuidString.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
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
	func subscribe(_ characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?, update: ((Data?) -> Void)?) {
		// 0. check if ble is available
		if let error = CuspCentral.default.assertAvailability() {
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
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.subscribeRequests.remove(req)
				})
			}
		}
	}

	public func subscribe(characteristic c: String, ofService s: String, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?, update: ((Data?) -> Void)?) {
		guard s.isValidUUID else { failure?(.invalidServiceUUID); return }
		guard c.isValidUUID else { failure?(.invalidCharacteristicUUID); return }
		discoverServices(UUIDStrings: [s], success: { (_) in
			guard let service = self[s] else { fatalError("Service not found after successfully discovering") }
			self.discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (_) in
				guard let char = service[c] else { fatalError("Characteristic not found after successfully discovering") }
				self.subscribe(char, success: success, failure: failure, update: update)
			}, failure: { failure?($0) })
		}) { failure?($0) }
//		if let service = self[s] {
//			if let char = service[c] {
//				subscribe(char, success: success, failure: failure, update: update)
//			} else {
//				discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
//					if let char = service[c] {
//						self.subscribe(char, success: success, failure: failure, update: update)
//					} else {
//						failure?(CuspError.characteristicNotFound)
//					}
//				}, failure: { (error) in
//					failure?(error)
//				})
//			}
//		} else {
//			discoverServices(UUIDStrings: [s], success: { (resp) in
//				if let service = self[s] {
//					self.discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
//						if let char = service[c] {
//							self.subscribe(char, success: success, failure: failure, update: update)
//						} else {
//							failure?(CuspError.characteristicNotFound)
//						}
//					}, failure: { (error) in
//						failure?(error)
//					})
//				} else {
//					failure?(CuspError.serviceNotFound)
//				}
//			}, failure: { (error) in
//				failure?(error)
//			})
//		}
	}
}
















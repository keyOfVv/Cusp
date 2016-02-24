//
//  Discover.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

// MARK: ServiceDiscoveringRequest

/// request of discovering services of specific peripheral
internal class ServiceDiscoveringRequest: OperationRequest {

	// MARK: Stored Properties

	/// UUID array of service to be discovered
	internal var serviceUUIDs: [UUID]?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter serviceUUIDs: UUID array of service to be discovered, all services will be discovered if passed nil
	- parameter peripheral:   a CBPeripheral instance of which the services to be discovered
	- parameter success:      a closure called when discovering succeed
	- parameter failure:      a closure called when discovering failed

	- returns: a ServiceDiscoveringRequest instance
	*/
	internal convenience init(serviceUUIDs: [UUID]?, peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
        self.serviceUUIDs = serviceUUIDs
        self.peripheral   = peripheral
        self.success      = success
        self.failure      = failure
	}

	override internal var hash: Int {
		return self.peripheral.hash
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? ServiceDiscoveringRequest {
			return self.hash == other.hash
		}
		return false
	}
}

// MARK: CharacteristicDiscoveringRequest

/// request of discovering characteristics of specific service
internal class CharacteristicDiscoveringRequest: OperationRequest {

	// MARK: Stored Properties

	/// UUID array of characteristic to be discovered
	internal var characteristicUUIDs: [UUID]?

	/// a CBService object of which the characteristics to be discovered
	internal var service: Service!

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristicUUIDs: UUID array of characteristic to be discovered
	- parameter service:             a CBService object of which the characteristics to be discovered
	- parameter peripheral:          a CBPeripheral instance of which the characteristics to be discovered
	- parameter success:             a closure called when discovering succeed
	- parameter failure:             a closure called when discovering failed

	- returns: a CharacteristicDiscoveringRequest instance
	*/
	internal convenience init(characteristicUUIDs: [UUID]?, service: Service, peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
        self.characteristicUUIDs = characteristicUUIDs
        self.service             = service
        self.peripheral          = peripheral
        self.success             = success
        self.failure             = failure
	}

	override internal var hash: Int {
		let string = self.peripheral.identifier.UUIDString + self.service.UUID.UUIDString
		return string.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CharacteristicDiscoveringRequest {
			return self.hash == other.hash
		}
		return false
	}
}

// MARK: Discover

extension Cusp {

	/**
	Discover specific or all services of a peripheral.
	发现从设备的部分或全部服务.

	- parameter serviceUUIDs: an UUID array of services to be discovered, all services will be discovered if passed nil. 服务UUID数组, 传nil则扫描所有服务.
	- parameter peripheral:   a CBPeripheral object of which the services to be discovered. 待发现服务的从设备对象.
	- parameter success:      a closure called when discovering succeed. 发现服务成功的闭包.
	- parameter failure:      a closure called when discovering failed. 发现服务失败的闭包.
	*/
	public func discover(serviceUUIDs: [UUID]?, inPeripheral peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}

		if let session = self.sessionFor(peripheral) {

			let req = ServiceDiscoveringRequest(serviceUUIDs: serviceUUIDs, peripheral: peripheral, success: success, failure: failure)
			dispatch_barrier_async(session.sessionQ, { () -> Void in
				self.serviceDiscoveringRequests.insert(req)
			})

			dispatch_async(session.sessionQ, { () -> Void in
				peripheral.discoverServices(serviceUUIDs)
			})

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), session.sessionQ) { () -> Void in
				if req.timedOut {
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						let error = NSError(domain: "connect operation timed out", code: Error.TimedOut.rawValue, userInfo: nil)
						failure?(error)
					})
					dispatch_barrier_async(session.sessionQ, { () -> Void in
						self.serviceDiscoveringRequests.remove(req)
					})
				}
			}
		}
	}

	/**
	Discover specific or all characteristics of a peripheral's specific service.
	发现从设备某项服务的部分或全部特征.

	- parameter characteristicUUIDs: an UUID array of characteristics to be discovered, all characteristics will be discovered if passed nil. 特征UUID数组, 传nil则扫描所有特征;
	- parameter service:             a CBService object of which the characteristics to be discovered. 待发现特征的服务.
	- parameter peripheral:          a CBPeripheral object of which the characteristics to be discovered. 待发现特征的从设备.
	- parameter success:             a closure called when discovering succeed. 发现特征成功的闭包.
	- parameter failure:             a closure called when discovering failed. 发现特征失败的闭包.
	*/
	public func discover(characteristicUUIDs: [UUID]?, ofService service: Service, inPeripheral peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}

		dispatch_async(self.mainQ) { () -> Void in
			let req = CharacteristicDiscoveringRequest(characteristicUUIDs: characteristicUUIDs, service: service, peripheral: peripheral, success: success, failure: failure)
			self.characteristicDiscoveringRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.discoverCharacteristics(characteristicUUIDs, forService: service)
				})

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), session.sessionQ) { () -> Void in
					if req.timedOut {
						dispatch_async(dispatch_get_main_queue(), { () -> Void in
							let error = NSError(domain: "connect operation timed out", code: Error.TimedOut.rawValue, userInfo: nil)
							failure?(error)
						})
						self.characteristicDiscoveringRequests.remove(req)
					}
				}
			}
		}
	}
}









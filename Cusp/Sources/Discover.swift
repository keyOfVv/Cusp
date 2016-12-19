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
internal class ServiceDiscoveringRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// UUID array of service to be discovered
	internal var serviceUUIDs: [UUID]?

	// MARK: Initializer

	fileprivate override init() {
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
	internal convenience init(serviceUUIDs: [UUID]?, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
        self.serviceUUIDs = serviceUUIDs
        self.success      = success
        self.failure      = failure
	}

	override internal var hash: Int {
		var joined = ""
		serviceUUIDs?.sorted(by: { (a, b) -> Bool in
			return a.uuidString <= b.uuidString
		}).forEach({ (uuid) in
			joined += uuid.uuidString
		})
		return joined.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? ServiceDiscoveringRequest else { return false }
		return hashValue == other.hashValue
	}
}

// MARK: CharacteristicDiscoveringRequest

/// request of discovering characteristics of specific service
internal class CharacteristicDiscoveringRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// UUID array of characteristic to be discovered
	internal var characteristicUUIDs: [UUID]?

	/// a CBService object of which the characteristics to be discovered
	internal var service: Service!

	// MARK: Initializer

	fileprivate override init() {
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
	internal convenience init(characteristicUUIDs: [UUID]?, service: Service, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
        self.characteristicUUIDs = characteristicUUIDs
        self.service             = service
        self.success             = success
        self.failure             = failure
	}

	override internal var hash: Int {
		// if characteristic uuid array is nil, return hash value of service uuid
		guard let uuids = characteristicUUIDs else {
			return service.uuid.hashValue
		}
		// sort the uuids
		let array = uuids.sorted { (a, b) -> Bool in
			return a.uuidString <= b.uuidString
		}
		// assemble uuid strings
		var string = service.uuid.uuidString
		for uuid in array {
			string += uuid.uuidString
		}
		return string.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		if let other = object as? CharacteristicDiscoveringRequest {
			return hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - Discovering service/characteristic
extension Peripheral {
	/**
	Discover specific or all services of a peripheral.

	- parameter serviceUUIDs: an UUID array of services to be discovered, all services will be discovered if passed nil.
	- parameter success:      a closure called when discovering succeed.
	- parameter failure:      a closure called when discovering failed.
	*/
	public func discoverService(UUIDs: [UUID]?, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create request object
		let req = ServiceDiscoveringRequest(serviceUUIDs: UUIDs, success: success, failure: failure)
		// 2. add request
		requestQ.async(execute: { () -> Void in
			self.serviceDiscoveringRequests.insert(req)
		})
		// 3. start discovering service(s)
		operationQ.async(execute: { () -> Void in
			self.core.discoverServices(UUIDs)
		})
		// 4. set time out closure
		operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more...
				self.requestQ.async(execute: { () -> Void in
					self.serviceDiscoveringRequests.remove(req)
				})
			}
		}
	}

	/**
	Discover specific or all services of a peripheral.

	- parameter serviceUUIDs: an UUID string literal array of services to be discovered, pass nil for all services.
	- parameter success:      a closure called when discovering succeed.
	- parameter failure:      a closure called when discovering failed.
	*/
	public func discoverService(UUIDStrings: [String]?, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		var uuids: [UUID] = []
		UUIDStrings?.forEach({ (uuidString) in
			let uuid = UUID(string: uuidString)
			uuids.append(uuid)
		})
		discoverService(UUIDs: uuids.count > 0 ? uuids : nil, success: success, failure: failure)
	}

	/**
	Discover specific or all characteristics of a peripheral's specific service.

	- parameter characteristicUUIDs: an UUID array of characteristics to be discovered, all characteristics will be discovered if passed nil.
	- parameter service:             a CBService object of which the characteristics to be discovered.
	- parameter success:             a closure called when discovering succeed.
	- parameter failure:             a closure called when discovering failed.
	*/
	public func discoverCharacteristic(UUIDs: [UUID]?, ofService service: Service, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create request object
		let req = CharacteristicDiscoveringRequest(characteristicUUIDs: UUIDs, service: service, success: success, failure: failure)
		// 2. add request
		requestQ.async(execute: { () -> Void in
			self.characteristicDiscoveringRequests.insert(req)
		})
		// 3. start discovering characteristic(s)
		operationQ.async(execute: { () -> Void in
			self.core.discoverCharacteristics(UUIDs, for: service)
		})
		// 4. set time out closure
		operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.characteristicDiscoveringRequests.remove(req)
				})
			}
		}
	}

	/**
	Discover specific or all characteristics of a peripheral's specific service.

	- parameter characteristicUUIDs: an UUID string literal array of characteristics to be discovered, pass nil for all characteristics.
	- parameter service:             a CBService object of which the characteristics to be discovered.
	- parameter success:             a closure called when discovering succeed.
	- parameter failure:             a closure called when discovering failed.
	*/
	public func discoverCharacteristic(UUIDStrings: [String]?, ofService service: Service, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		var uuids: [UUID] = []
		UUIDStrings?.forEach({ (uuidString) in
			let uuid = UUID(string: uuidString)
			uuids.append(uuid)
		})
		discoverCharacteristic(UUIDs: uuids.count > 0 ? uuids : nil, ofService: service, success: success, failure: failure)
	}

	/**
	check if services of specific UUID(s) discovered already

	- parameter uuids: an array of service UUID

	- returns: return true if every service of specific UUID(s) discovered already, otherwise false
	*/
	func areServicesAvailable(uuids: [UUID]) -> Bool {
		for uuid in uuids {
			if let _ = self.serviceWith(UUIDString: uuid.uuidString) {
				continue
			}
			return false
		}
		return true
	}

	/**
	check if services of specific UUID string(s) discovered

	- parameter uuidStrings: an array of service UUID string

	- returns: return true if every service of specific UUID string(s) discovered already, otherwise false
	*/
	func areServicesAvailable(uuidStrings: [String]) -> Bool {
		for string in uuidStrings {
			if let _ = self.serviceWith(UUIDString: string) {
				continue
			}
			return false
		}
		return true
	}

	/**
	check if characteristic of specific UUID(s) discovered already

	- parameter uuids: an array of characteristic UUID

	- returns: return true if every characteristic of specific UUID(s) discovered already, otherwise false
	*/
	func areCharacteristicsAvailable(uuids: [UUID], forService service: Service) -> Bool {
		for uuid in uuids {
			if let _ = service[uuid.uuidString] {
				continue
			}
			return false
		}
		return true
	}

	/**
	check if characteristic of specific UUID string(s) discovered already

	- parameter uuidStrings: an array of characteristic UUID string

	- returns: return true if every characteristic of specific UUID string(s) discovered already, otherwise false
	*/
	func areCharacteristicsAvailable(uuidStrings: [String]) -> Bool {
		guard let services = self.services else {
			return false
		}
		for uuidString in uuidStrings {
			for service in services {
				if let _ = service[uuidString] {
					continue
				}
			}
			return false
		}
		return true
	}

}






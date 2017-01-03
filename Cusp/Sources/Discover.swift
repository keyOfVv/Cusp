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
class ServiceDiscoveringRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// UUID array of service to be discovered
	var serviceUUIDs: [UUID]?

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
	convenience init(serviceUUIDs: [UUID]?, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
        self.serviceUUIDs = serviceUUIDs
        self.success      = success
        self.failure      = failure
	}

	override var hash: Int {
		var joined = ""
		serviceUUIDs?.sorted(by: { (a, b) -> Bool in
			return a.uuidString <= b.uuidString
		}).forEach({ (uuid) in
			joined += uuid.uuidString
		})
		return joined.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? ServiceDiscoveringRequest else { return false }
		return hashValue == other.hashValue
	}
}

// MARK: CharacteristicDiscoveringRequest

/// request of discovering characteristics of specific service
class CharacteristicDiscoveringRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// UUID array of characteristic to be discovered
	var characteristicUUIDs: [UUID]?

	/// a CBService object of which the characteristics to be discovered
	var service: Service!

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
	convenience init(characteristicUUIDs: [UUID]?, service: Service, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
        self.characteristicUUIDs = characteristicUUIDs
        self.service             = service
        self.success             = success
        self.failure             = failure
	}

	override var hash: Int {
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

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? CharacteristicDiscoveringRequest {
			return hashValue == other.hashValue
		}
		return false
	}
}

class DescriptorDiscoveringRequest: PeripheralOperationRequest {
	var characteristic: Characteristic!
	fileprivate override init() {
		super.init()
	}
	convenience init(characteristic: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
		self.characteristic = characteristic
		self.success        = success
		self.failure        = failure
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
	func discoverServices(UUIDs: [UUID]?, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 0.5 filter out discovered service(s)
		let undisServs = getUndiscoveredServicesFrom(uuids: UUIDs)
		if let uuids = undisServs, uuids.count == 0 {
			// all desired service(s) are discovered already, call back
			success?(nil)
			return
		}
		// 1. create request object
		let req = ServiceDiscoveringRequest(serviceUUIDs: undisServs, success: success, failure: failure)
		// 2. add request
		requestQ.async(execute: { () -> Void in
			self.serviceDiscoveringRequests.insert(req)
		})
		// 3. start discovering service(s)
		operationQ.async(execute: { () -> Void in
			self.core.discoverServices(UUIDs)
		})
		// 4. set time out closure
		operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { [weak self] () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more...
				self?.requestQ.async(execute: { () -> Void in
					_ = self?.serviceDiscoveringRequests.remove(req)
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
	func discoverServices(UUIDStrings: [String]?, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		discoverServices(UUIDs: uuidsFrom(uuidStrings: UUIDStrings), success: success, failure: failure)
	}

	/**
	Discover specific or all characteristics of a peripheral's specific service.

	- parameter characteristicUUIDs: an UUID array of characteristics to be discovered, all characteristics will be discovered if passed nil.
	- parameter service:             a CBService object of which the characteristics to be discovered.
	- parameter success:             a closure called when discovering succeed.
	- parameter failure:             a closure called when discovering failed.
	*/
	func discoverCharacteristics(UUIDs: [UUID]?, ofService service: Service, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 0.5 filter out discovered characteristic(s)
		let undisChars = service.getUndiscoveredCharsFrom(uuids: UUIDs)
		if let uuids = undisChars, uuids.count == 0 {
			// all desired characteristic(s) are discovered already, call back
			success?(nil)
			return
		}
		// 1. create request object
		let req = CharacteristicDiscoveringRequest(characteristicUUIDs: undisChars, service: service, success: success, failure: failure)
		// 2. add request
		requestQ.async(execute: { () -> Void in
			self.characteristicDiscoveringRequests.insert(req)
		})
		// 3. start discovering characteristic(s)
		operationQ.async(execute: { () -> Void in
			self.core.discoverCharacteristics(UUIDs, for: service)
		})
		// 4. set time out closure
		operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { [weak self] () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self?.requestQ.async(execute: { () -> Void in
					_ = self?.characteristicDiscoveringRequests.remove(req)
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
	func discoverCharacteristics(UUIDStrings: [String]?, ofService service: Service, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		discoverCharacteristics(UUIDs: uuidsFrom(uuidStrings: UUIDStrings), ofService: service, success: success, failure: failure)
	}

	func discoverDescriptors(forCharacteristic char: Characteristic, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create request object
		let req = DescriptorDiscoveringRequest(characteristic: char, success: success, failure: failure)
		// 2. add request
		requestQ.async(execute: { () -> Void in
			self.descriptorDiscoveringRequests.insert(req)
		})
		// 3. start discovering characteristic(s)
		operationQ.async(execute: { () -> Void in
			self.core.discoverDescriptors(for: char)
		})
		// 4. set time out closure
		operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { [weak self] () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self?.requestQ.async(execute: { () -> Void in
					_ = self?.descriptorDiscoveringRequests.remove(req)
				})
			}
		}
	}

	public func discoverDescriptors(forCharacteristic c: String, ofService s: String, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		discoverServices(UUIDStrings: [s], success: { (resp) in
			if let service = self[s] {
				self.discoverCharacteristics(UUIDStrings: [c], ofService: service, success: { (resp) in
					if let char = service[c] {
						self.discoverDescriptors(forCharacteristic: char, success: success, failure: failure)
					} else {
						failure?(CuspError.characteristicNotFound)
					}
				}, failure: { (err) in
					failure?(err)
				})
			} else {
				failure?(CuspError.serviceNotFound)
			}
		}) { (err) in
			failure?(err)
		}
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

	func getUndiscoveredServicesFrom(uuids: [UUID]?) -> [UUID]? {
		guard let uuids = uuids else {
			return nil
		}
		guard uuids.count > 0 else {
			return nil
		}
		var undisUUID = [UUID]()
		uuids.forEach { (uuid) in
			if let _ = self[uuid.uuidString] {
				// discovered
				return
			} else {
				// undiscovered
				undisUUID.append(uuid)
			}
		}
		return undisUUID
	}
}

// MARK: -
extension Service {

	func getUndiscoveredCharsFrom(uuids: [UUID]?) -> [UUID]? {
		guard let uuids = uuids else {
			return nil
		}
		guard uuids.count > 0 else {
			return nil
		}
		var undisUUID = [UUID]()
		uuids.forEach { (uuid) in
			if let _ = self[uuid.uuidString] {
				// discovered
				return
			} else {
				// undiscovered
				undisUUID.append(uuid)
			}
		}
		return undisUUID
	}

}

func uuidStringsFrom(uuids: [UUID]?) -> [String]? {
	guard let uuids = uuids else {
		return nil
	}
	guard uuids.count > 0 else {
		return nil
	}
	var uuidStrings = [String]()
	uuids.forEach { (uuid) in
		uuidStrings.append(uuid.uuidString)
	}
	return uuidStrings
}

func uuidsFrom(uuidStrings: [String]?) -> [UUID]? {
	guard let uuidStrings = uuidStrings else {
		return nil
	}
	guard uuidStrings.count > 0 else {
		return nil
	}
	var uuids = [UUID]()
	uuidStrings.forEach { (uuidString) in
		uuids.append(UUID(string: uuidString.uppercased()))
	}
	return uuids
}





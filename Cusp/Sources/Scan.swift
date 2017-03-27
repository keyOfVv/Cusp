//
//  CuspScan.swift
//  Aura
//
//  Created by keyOfVv on 10/26/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation

/// default scan duration
private let defaultDuration: TimeInterval = 3.0

/// scan request
class ScanRequest: NSObject {

	// MARK: Stored Properties

	/// advertising uuids to be scanned
	var advertisingUUIDs: [UUID]?

	/// scan duration in second, 3.0s by default
	var duration: TimeInterval = defaultDuration

	/// closure to be called when scan completed
	var completion: (([Advertisement]) -> Void)?

	/// closure to be called when scan abrupted
	var abruption: ((CuspError) -> Void)?

	/// scanned peripherals with miscellaneous info, all wrapped as Advertisement
	var available = Set<Advertisement>()

	// MARK: Initializer
	/// intendedly made private
	fileprivate override init() { super.init() }

	/**
	convenient initializer

	- parameter advertisingUUIDs: advertising uuids to be scanned
	- parameter duration:         scan duration in second, 3.0s by default
	- parameter completion:       closure to be called when scan completed
	- parameter abruption:        closure to be called when scan abrupted

	- returns: a ScanRequest instance
	*/
	convenience init(advertisingUUIDs: [UUID]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {
		self.init()
        self.advertisingUUIDs = advertisingUUIDs
        self.duration         = duration
        self.completion       = completion
        self.abruption        = abruption
	}

	/**
	convenient initializer

	- parameter advertisingUUIDs: advertising uuid strings to be scanned
	- parameter duration:         scan duration in second, 3.0s by default
	- parameter completion:       closure to be called when scan completed
	- parameter abruption:        closure to be called when scan abrupted

	- returns: a ScanRequest instance
	*/
	convenience init(advertisingUUIDStrings: [String]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {
		guard let uuidStrings = advertisingUUIDStrings else {
			self.init(advertisingUUIDs: nil, duration: duration, completion: completion, abruption: abruption)
			return
		}
		// convert uuid string array into UUID array
		let uuids = uuidStrings.map { UUID(string: $0) }
		self.init(advertisingUUIDs: uuids, duration: duration, completion: completion, abruption: abruption)
	}

	override var hash: Int {
		return advertisingUUIDs?.reduce("") { $0 + $1.uuidString }.hashValue ?? 0
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? ScanRequest else { return false }
		return self.hashValue == other.hashValue
	}

	deinit {
		dog("\(self.classForCoder) deinited")
	}
}

// MARK: - scan methods

extension CuspCentral {

	/**
	Scan for BLE peripherals of specific advertising service UUIDs. If pass nil, all peripheral will be scanned. A timed-out scan will call completion closure, or else the abruption one.

	- parameter advertisingServiceUUIDs: a specific UUID array or nil.
	- parameter duration:                scan duration in second, 3.0s by default.
	- parameter completion:              a closure called when scan timed out.
	- parameter abruption:               a closure called when scan is abrupted.
	*/
	public func scanForUUID(_ advertisingServiceUUIDs: [UUID]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {
		// 0. check if ble is available, if error is non-nil, call abruption closure
//		if let error = self.assertAvailability() {
//			abruption?(error)
//			return
//		}

		// 1. passed BLE availability check
		self.isScanning = true

		// 2. create a ScanRequest object and check it in
		let req = ScanRequest(advertisingUUIDs: advertisingServiceUUIDs, duration: duration, completion: completion, abruption: abruption)
		self.checkIn(req)

		// 3. dispatch completion closure
		self.mainQ.asyncAfter(deadline: DispatchTime.now() + Double(req.duration), execute: { () -> Void in
			DispatchQueue.main.async(execute: { () -> Void in
				let infoSet = req.available.sorted(by: { (a, b) -> Bool in
					return a.peripheral.core.identifier.uuidString <= b.peripheral.core.identifier.uuidString
				})
				// scan completed, check request out
				self.checkOut(req)
				// callback
				if self.isScanning {
					dog(infoSet)
					req.completion?(infoSet)
				} else {
					req.abruption?(CuspError.scanningCanceled)
				}
			})
		})
	}

	/**
	Scan for BLE peripherals of specific advertising service UUID Strings. If pass nil, all kinds of peripheral will be scanned. A timed-out scan will call completion closure, or else the abruption one.

	- parameter advertisingServiceUUIDs: a specific UUID string array or nil.
	- parameter duration:                scan duration in second, 3.0s by default.
	- parameter completion:              a closure called when scan timed out.
	- parameter abruption:               a closure called when scan is abrupted.
	*/
	public func scanForUUIDString(_ advertisingServiceUUIDStrings: [String]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {

		// 0. check if ble is available
//		if let error = self.assertAvailability() {
//			abruption?(error)
//			return
//		}

		if let uuidStrings = advertisingServiceUUIDStrings {
			let uuids = uuidStrings.map { UUID(string: $0) }
			self.scanForUUID(uuids, duration: duration, completion: completion, abruption: abruption)
		} else {
			self.scanForUUID(nil, duration: duration, completion: completion, abruption: abruption)
		}
	}

	/**
	stop scanning, it's an non-block method, and scanRequests will be emptied once called
	*/
	public func stopScan() {
		self.isScanning = false
		self.centralManager.stopScan()
		self.reqQ.async { () -> Void in
			self.scanReqs.removeAll()
		}
//		dog("CUSP STOPPED SCAN")
	}
}

// MARK: - Privates

extension CuspCentral {

	/**
	Check in a ScanRequest object. If no scanning is underway, start it immediately; otherwise, union the target UUID and apply a new scan.

	- parameter request: an instance of ScanRequest
	*/
	fileprivate func checkIn(_ request: ScanRequest) -> Void {
		reqQ.sync { () -> Void in
			self.scanReqs.insert(request)
			let targets = self.unionTarget()
			self.centralManager.scanForPeripherals(withServices: targets,
			                                       options: nil)
		}
	}

	/**
	Check out a ScanRequest object. The scanning operation would stopped if no scan request left after checking out, or else abstract the target UUID and apply a new scan.

	- parameter request: an instance of ScanRequest
	*/
	fileprivate func checkOut(_ request: ScanRequest) -> Void {
		reqQ.sync { () -> Void in
			self.scanReqs.remove(request)
			if scanReqs.isEmpty {
				self.centralManager.stopScan()
			} else {
				let targets = self.unionTarget()
				self.centralManager.scanForPeripherals(withServices: targets,
				                                       options: nil)
			}
		}
	}

	/**
	Extract target UUIDs from existed scan requests and union them. Nil array would be returned if any request's target UUID array were nil.

	- returns: a new UUID array after union
	*/
	fileprivate func unionTarget() -> [UUID]? {
		var targets = Set<UUID>()
		for req in self.scanReqs {
			// if any request targets at overall scan...
			if let uuids = req.advertisingUUIDs {
				targets.formUnion(uuids)
			} else {
				return nil
			}
		}

		return targets.sorted(by: { (a, b) -> Bool in
			a.uuidString <= b.uuidString
		})
	}

}




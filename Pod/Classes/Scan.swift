//
//  CuspScan.swift
//  Aura
//
//  Created by keyOfVv on 10/26/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation

/// default scan duration
private let defaultDuration: NSTimeInterval = 3.0

/// scan request
internal class ScanRequest: NSObject {

	// MARK: Stored Properties

	/// advertising uuids to be scanned
	var advertisingUUIDs: [UUID]?

	/// scan duration in second, 3.0s by default
	var duration: NSTimeInterval = defaultDuration

	/// closure to be called when scan completed
	var completion: (([Peripheral]) -> Void)?

	/// closure to be called when scan abrupted
	var abruption: ((NSError) -> Void)?

	/// peripherals scanned
	var available = Set<Peripheral>()

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	convenient initializer

	- parameter advertisingUUIDs: advertising uuids to be scanned
	- parameter duration:         scan duration in second, 3.0s by default
	- parameter completion:       closure to be called when scan completed
	- parameter abruption:        closure to be called when scan abrupted

	- returns: a ScanRequest instance
	*/
	internal convenience init(advertisingUUIDs: [UUID]?, duration: NSTimeInterval = defaultDuration, completion: (([Peripheral]) -> Void)?, abruption: ((NSError) -> Void)?) {
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
	internal convenience init(advertisingUUIDStrings: [String]?, duration: NSTimeInterval = defaultDuration, completion: (([Peripheral]) -> Void)?, abruption: ((NSError) -> Void)?) {
		if let uuidStrings = advertisingUUIDStrings {
			var uuids = [UUID]()
			for uuidString in uuidStrings {
				let uuid = UUID(string: uuidString)
				uuids.append(uuid)
			}
			self.init(advertisingUUIDs: uuids, duration: duration, completion: completion, abruption: abruption)
		} else {
			self.init(advertisingUUIDs: nil, duration: duration, completion: completion, abruption: abruption)
		}
	}

	internal override var hash: Int {
		if let UUIDs = self.advertisingUUIDs {
			var string = ""
			for UUID in UUIDs {
				string += UUID.UUIDString
			}
			return string.hashValue
		}
		return 0
	}

	internal override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? ScanRequest {
			return self.hash == other.hash
		}
		return false
	}

}

// MARK: - scan methods

public extension Cusp {

	/**
	scan for BLE peripherals(扫描从设备)

	- parameter advertisingServiceUUIDs: an array containing specific UUIDs, set nil to scan for all available peripherals(目标从设备的广播服务UUID数组, 如传nil则扫描所有从设备)
	- parameter duration:                scan duration, default is 3.0(扫描时长, 默认3.0秒)
	- parameter completion:              a closure called right after scan timed out(扫描完成后的回调, 返回从设备数组)
	- parameter abruption:               a closure called when scan is abrupted(扫描中断的回调, 返回错误原因)
	*/
	public func scanForUUID(advertisingServiceUUIDs: [UUID]?, duration: NSTimeInterval = defaultDuration, completion: (([Peripheral]) -> Void)?, abruption: ((NSError) -> Void)?) {

		// 0. check if ble is available
		if let error = self.assertAvailability() {
			abruption?(error)
			return
		}

		// 1. create a ScanRequest object and check it in
		let req = ScanRequest(advertisingUUIDs: advertisingServiceUUIDs, duration: duration, completion: completion, abruption: abruption)
		self.checkIn(req)

		// 2. dispatch completion closure
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.duration * Double(NSEC_PER_SEC))), self.mainQ, {[weak self] () -> Void in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				let peripherals = req.available.sort({ (a, b) -> Bool in
					return a.identifier.UUIDString <= b.identifier.UUIDString
				})
				completion?(peripherals)
			})
			self?.checkOut(req)
			})
	}

//	public func scan(advertisingServiceUUIDStrings: [String]?, duration: NSTimeInterval = defaultDuration, completion: (([Peripheral]) -> Void)?, abruption: ((NSError) -> Void)?) {
//
//
//	}

}

// MARK: - Privates

extension Cusp {

	private func checkIn(request: ScanRequest) -> Void {
		self.scanRequests.insert(request)

		let targets = self.restructureTarget()
		self.centralManager.scanForPeripheralsWithServices(targets, options: nil)
	}

	private func checkOut(request: ScanRequest) -> Void {
		self.scanRequests.remove(request)

		if self.scanRequests.isEmpty {
			self.centralManager.stopScan()
		} else {
			let targets = self.restructureTarget()
			self.centralManager.scanForPeripheralsWithServices(targets, options: nil)
		}
	}

	private func restructureTarget() -> [UUID]? {
		var targets = Set<UUID>()
		for req in self.scanRequests {
			// if any request targets at overall scan...
			if req.advertisingUUIDs == nil {
				return nil
			} else {
				targets.unionInPlace(req.advertisingUUIDs!)
			}
		}

		return targets.sort({ (a, b) -> Bool in
			a.UUIDString <= b.UUIDString
		})
	}

	internal func advServiceUUID(data: [String: AnyObject]) -> UUID? {
		if let array = data["kCBAdvDataServiceUUIDs"] as? NSMutableArray {
			if let uuid = array.firstObject as? UUID {
				return uuid
			}
		}
		return nil
	}

}




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
internal class ScanRequest: NSObject {

	// MARK: Stored Properties

	/// advertising uuids to be scanned
	internal var advertisingUUIDs: [UUID]?

	/// scan duration in second, 3.0s by default
	internal var duration: TimeInterval = defaultDuration

	/// closure to be called when scan completed
	internal var completion: (([Advertisement]) -> Void)?

	/// closure to be called when scan abrupted
	internal var abruption: ((CuspError) -> Void)?

	/// scanned peripherals with miscellaneous info, all wrapped as Advertisement
	internal var available = Set<Advertisement>()

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
	internal convenience init(advertisingUUIDs: [UUID]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {
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
	internal convenience init(advertisingUUIDStrings: [String]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {
		guard let uuidStrings = advertisingUUIDStrings else {
			self.init(advertisingUUIDs: nil, duration: duration, completion: completion, abruption: abruption)
			return
		}
		// convert uuid string array into UUID array
		var uuids = [UUID]()
		for uuidString in uuidStrings {
			uuids.append(UUID(string: uuidString))
		}
		self.init(advertisingUUIDs: uuids, duration: duration, completion: completion, abruption: abruption)
	}

	internal override var hash: Int {
		guard let UUIDs = self.advertisingUUIDs else { return 0 }
		var string = ""
		for UUID in UUIDs {
			string += UUID.uuidString
		}
		return string.hashValue
	}

	internal override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? ScanRequest else { return false }
		return self.hashValue == other.hashValue
	}

	deinit {
		dog("\(self.classForCoder) deinited")
	}
}

// MARK: - scan methods

public extension Cusp {

	/**
	Scan for BLE peripherals of specific advertising service UUIDs. If pass nil, all peripheral will be scanned. A timed-out scan will call completion closure, or else the abruption one.

	- parameter advertisingServiceUUIDs: a specific UUID array or nil.
	- parameter duration:                scan duration in second, 3.0s by default.
	- parameter completion:              a closure called when scan timed out.
	- parameter abruption:               a closure called when scan is abrupted.
	*/
	public func scanForUUID(_ advertisingServiceUUIDs: [UUID]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {
		// 0. check if ble is available, if error is non-nil, call abruption closure
		if let error = self.assertAvailability() {
			abruption?(error)
			return
		}

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
	根据UUID字符串数组扫描指定从设备, 如不指定UUID, 则扫描任意从设备. 扫描成功会执行completion闭包, 反之则执行abruption闭包;

	- parameter advertisingServiceUUIDs: a specific UUID string array or nil. 指定的广播服务UUID字符串数组或nil
	- parameter duration:                scan duration in second, 3.0s by default. 扫描时长, 默认3.0秒
	- parameter completion:              a closure called when scan timed out. 扫描完成后的回调, 返回从设备数组
	- parameter abruption:               a closure called when scan is abrupted. 扫描中断的回调, 返回错误原因
	*/
	public func scanForUUIDString(_ advertisingServiceUUIDStrings: [String]?, duration: TimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((CuspError) -> Void)?) {

		// 0. check if ble is available
		if let error = self.assertAvailability() {
			abruption?(error)
			return
		}

		if let uuidStrings = advertisingServiceUUIDStrings {
			var uuids = [UUID]()
			for uuidString in uuidStrings {
				let uuid = UUID(string: uuidString)
				uuids.append(uuid)
			}
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

extension Cusp {

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




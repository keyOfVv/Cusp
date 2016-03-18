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
	internal var advertisingUUIDs: [UUID]?

	/// scan duration in second, 3.0s by default
	internal var duration: NSTimeInterval = defaultDuration

	/// closure to be called when scan completed
	internal var completion: (([Advertisement]) -> Void)?

	/// closure to be called when scan abrupted
	internal var abruption: ((NSError) -> Void)?

	/// peripherals scanned
	internal var available = Set<Advertisement>()

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
	internal convenience init(advertisingUUIDs: [UUID]?, duration: NSTimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((NSError) -> Void)?) {
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
	internal convenience init(advertisingUUIDStrings: [String]?, duration: NSTimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((NSError) -> Void)?) {
		guard let uuidStrings = advertisingUUIDStrings else {
			self.init(advertisingUUIDs: nil, duration: duration, completion: completion, abruption: abruption)
			return
		}
		// convert uuid string array into UUID array
		var uuids = [UUID]()
		for uuidString in uuidStrings {
			let uuid = UUID(string: uuidString)
			uuids.append(uuid)
		}
		self.init(advertisingUUIDs: uuids, duration: duration, completion: completion, abruption: abruption)
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
			return self.hashValue == other.hashValue
		}
		return false
	}

}

// MARK: - scan methods

public extension Cusp {

	/**
	Scan for BLE peripherals of specific advertising service UUIDs. If pass nil, all kinds of peripheral will be scanned. A timed-out scan will call completion closure, or else the abruption one.
	根据UUID数组扫描指定从设备, 如不指定UUID, 则扫描任意从设备. 扫描成功会执行completion闭包, 反之则执行abruption闭包;

	- parameter advertisingServiceUUIDs: a specific UUID array or nil. 指定的广播服务UUID数组或nil
	- parameter duration:                scan duration in second, 3.0s by default. 扫描时长, 默认3.0秒
	- parameter completion:              a closure called when scan timed out. 扫描完成后的回调, 返回从设备数组
	- parameter abruption:               a closure called when scan is abrupted. 扫描中断的回调, 返回错误原因
	*/
	public func scanForUUID(advertisingServiceUUIDs: [UUID]?, duration: NSTimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((NSError) -> Void)?) {

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
				let infoSet = req.available.sort({ (a, b) -> Bool in
					return a.peripheral.core.identifier.UUIDString <= b.peripheral.core.identifier.UUIDString
				})
				completion?(infoSet)
			})
			// scan completed, check request out
			self?.checkOut(req)
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
	public func scanForUUIDString(advertisingServiceUUIDStrings: [String]?, duration: NSTimeInterval = defaultDuration, completion: (([Advertisement]) -> Void)?, abruption: ((NSError) -> Void)?) {

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
}

// MARK: - Privates

extension Cusp {

	/**
	Check in a ScanRequest object. If no scanning is underway, start it immediately; otherwise, union the target UUID and apply a new scan.

	- parameter request: an instance of ScanRequest
	*/
	private func checkIn(request: ScanRequest) -> Void {
		dispatch_async(self.reqQ) { () -> Void in
			self.scanRequests.insert(request)
		}

		let targets = self.unionTarget()
		self.centralManager.scanForPeripheralsWithServices(targets, options: nil)
	}

	/**
	Check out a ScanRequest object. The scanning operation would stopped if no scan request left after checking out, or else abstract the target UUID and apply a new scan.

	- parameter request: an instance of ScanRequest
	*/
	private func checkOut(request: ScanRequest) -> Void {
		dispatch_async(self.reqQ) { () -> Void in
			self.scanRequests.remove(request)
		}

		if self.scanRequests.isEmpty {
			self.centralManager.stopScan()
		} else {
			let targets = self.unionTarget()
			self.centralManager.scanForPeripheralsWithServices(targets, options: nil)
		}
	}

	/**
	Extract target UUIDs from existed scan requests and union them. Nil array would be returned if any request's target UUID array were nil.

	- returns: a new UUID array after union
	*/
	private func unionTarget() -> [UUID]? {
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

}




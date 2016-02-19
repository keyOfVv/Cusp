//
//  CuspScan.swift
//  Aura
//
//  Created by keyOfVv on 10/26/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation
import CoreBluetooth

private let defaultDuration: NSTimeInterval = 3.0

/// 扫描请求模型
internal class ScanRequest: NSObject {

	// MARK: Stored Properties

	/// 扫描的目标UUID数组
	var advertisingUUIDs: [CBUUID]?

	/// 扫描时长
	var duration: Double = 0.0

	/// 扫描完成的回调
	var completion: (([CBPeripheral]) -> Void)?

	/// 扫描中断的回调
	var abruption: ((NSError) -> Void)?

	///
	var available = Set<Peripheral>()

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter advertisingUUIDs: 广播服务UUID数组
	- parameter duration:         扫描时长, 默认0.0秒
	- parameter completion:       扫描结束的回调
	- parameter abruption:        扫描中断的回调

	- returns: 返回一个ScanRequest对象
	*/
	internal convenience init(advertisingUUIDs: [CBUUID]?, duration: Double = 0.0, completion: (([CBPeripheral]) -> Void)?, abruption: ((NSError) -> Void)?) {
		self.init()
        self.advertisingUUIDs = advertisingUUIDs
        self.duration         = duration
        self.completion       = completion
        self.abruption        = abruption
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
	public func scan(advertisingServiceUUIDs: [CBUUID]?, duration: NSTimeInterval = defaultDuration, completion: (([CBPeripheral]) -> Void)?, abruption: ((NSError) -> Void)?) {

		log("?????????")

		// 0. 检查当前蓝牙状态
		var errorCode: Int?
		var domain = ""
		switch self.state {
		case .PoweredOff:
            errorCode = Error.PoweredOff.rawValue
            domain    = "BLE is powered off."
			break
		case .Resetting:
            errorCode = Error.Resetting.rawValue
            domain    = "BLE is resetting, please try again later."
			break
		case .Unauthorized:
            errorCode = Error.Unauthorized.rawValue
            domain    = "BLE is unauthorized."
			break
		case .Unsupported:
            errorCode = Error.Unsupported.rawValue
            domain    = "BLE is unsupported."
			break
		case .Unknown:
            errorCode = Error.Unknown.rawValue
            domain    = "BLE is in unknown state."
			break
		default:
			break
		}
		if let code = errorCode {
			let error = NSError(domain: domain, code: code, userInfo: nil)
			abruption?(error)
			return
		}

		// 2. 蓝牙状态正常, 且当前未处于扫描状态, 则创建扫描请求
		let req = ScanRequest(advertisingUUIDs: advertisingServiceUUIDs, duration: duration, completion: completion, abruption: abruption)
		self.checkIn(req)

		// 4. 结束扫描
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

	private func restructureTarget() -> [CBUUID]? {
		var targets = Set<CBUUID>()
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

	internal func advServiceUUID(data: [String: AnyObject]) -> CBUUID? {
		if let array = data["kCBAdvDataServiceUUIDs"] as? NSMutableArray {
			if let uuid = array.firstObject as? CBUUID {
				return uuid
			}
		}
		return nil
	}
}




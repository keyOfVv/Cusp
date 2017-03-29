//
//  RSSI.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

import CoreBluetooth

// MARK: RSSIRequest

/// 查询信号强度请求模型
class RSSIRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	var identifier: NSUUID = NSUUID()

	// MARK: Initializer

	override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter peripheral: 从设备对象
	- parameter success:    成功查询的回调
	- parameter failure:    查询失败的回调
	- parameter timedOut:   查询超时的回调

	- returns: 返回一个RSSIRequest对象
	*/
	convenience init(success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		self.init()
		self.success = success
		self.failure = failure
	}

	override var hash: Int {
		return identifier.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? RSSIRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: Communicate
extension Peripheral {

	/// 获取信号强度
	///
	/// - parameter peripheral: 从设备;
	/// - parameter timeOut: 超时时长, 传nil则使用默认时长;
	/// - parameter success: 获取成功的回调;
	/// - parameter failure: 获取失败的回调;
	/// - parameter timedOut: 获取超时的回调;
	public func readRSSI(success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = CuspCentral.default.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create req
		let req = RSSIRequest(success: success, failure: failure)
		// 2. add req
		self.requestQ.async(execute: { () -> Void in
			self.RSSIRequests.insert(req)
		})
		// 3. read RSSI
		self.operationQ.async(execute: { () -> Void in
			self.core.readRSSI()
		})
		// 4. set time out closure
		self.operationQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// since req timed out, don't need it any more
				self.requestQ.async(execute: { () -> Void in
					self.RSSIRequests.remove(req)
				})
			}
		}
	}
}

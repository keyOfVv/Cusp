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
internal class RSSIRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

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
	convenience init(success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
		self.success = success
		self.failure = failure
	}

	override internal var hash: Int {
		return self.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? RSSIRequest {
			return self.hash == other.hash
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
	public func readRSSI(success success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create req
		let req = RSSIRequest(success: success, failure: failure)
		// 2. add req
		dispatch_async(self.requestQ, { () -> Void in
			self.RSSIRequests.insert(req)
		})
		// 3. read RSSI
		dispatch_async(self.operationQ, { () -> Void in
			self.core.readRSSI()
		})
		// 4. set time out closure
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), self.operationQ) { () -> Void in
			if req.timedOut {
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					let error = NSError(domain: "connect operation timed out", code: Cusp.Error.TimedOut.rawValue, userInfo: nil)
					failure?(error)
				})
				// since req timed out, don't need it any more
				dispatch_async(self.requestQ, { () -> Void in
					self.RSSIRequests.remove(req)
				})
			}
		}
	}
}
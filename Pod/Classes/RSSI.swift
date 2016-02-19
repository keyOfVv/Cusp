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
internal class RSSIRequest: OperationRequest {

	// MARK: Stored Properties

	// MARK: Initializer

	/**
	构造方法

	- returns: 返回一个RSSIRequest对象
	*/
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
	convenience init(peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
		self.peripheral = peripheral
		self.success = success
		self.failure = failure
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? RSSIRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}
}

// MARK: Communicate
extension Cusp {

	/// 获取信号强度
	///
	/// - parameter peripheral: 从设备;
	/// - parameter timeOut: 超时时长, 传nil则使用默认时长;
	/// - parameter success: 获取成功的回调;
	/// - parameter failure: 获取失败的回调;
	/// - parameter timedOut: 获取超时的回调;
	public func readRSSI(peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		dispatch_async(self.mainQ) { () -> Void in
			let req = RSSIRequest(peripheral: peripheral, success: success, failure: failure)
			self.RSSIRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.readRSSI()
				})
			}
		}
	}

}
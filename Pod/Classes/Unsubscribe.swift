//
//  Unsubscribe.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: UnsubscribeRequest

/// 退订通知请求模型
internal class UnsubscribeRequest: OperationRequest {

	// MARK: Stored Properties

	/// 待退订的特征
	var characteristic: CBCharacteristic?

	// MARK: Initializer

	/// 初始化

	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter characteristic: 待退订的特征
	- parameter peripheral:     从设备对象
	- parameter success:        成功退订的回调
	- parameter failure:        退订失败的回调
	- parameter timedOut:       退订超时的回调

	- returns: 返回一个UnsubscribeRequest对象
	*/
	convenience init(characteristic: CBCharacteristic, peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
		self.characteristic = characteristic
		self.peripheral = peripheral
		self.success = success
		self.failure = failure
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? UnsubscribeRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}
}

// MARK: Communicate
extension Cusp {

	/// 取消订阅
	///
	/// - parameter characteristic: 特征;
	/// - parameter inPeripheral: 从设备;
	/// - parameter timeOut: 超时时长, 传nil则使用默认时长;
	/// - parameter success: 取消订阅成功的回调;
	/// - parameter failure: 取消订阅失败的回调;
	/// - parameter timedOut: 取消订阅超时的回调;
	public func unsubscribe(characteristic: CBCharacteristic, inPeripheral peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		dispatch_async(self.mainQ) { () -> Void in
			let req = UnsubscribeRequest(characteristic: characteristic, peripheral: peripheral, success: success, failure: failure)
			self.unsubscribeRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.setNotifyValue(true, forCharacteristic: characteristic)
				})
			}
		}
	}
}






//
//  Subscribe.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: SubscribeRequest

/// 订阅通知请求模型
internal class SubscribeRequest: OperationRequest {

	// MARK: Stored Properties

	/// 待订阅的特征
	var characteristic: CBCharacteristic?

	var update: ((NSData?) -> Void)?

	// MARK: Initializer

	/**
	构造方法

	- returns: 返回一个SubscribeRequest对象
	*/
	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter characteristic: 待订阅的特征
	- parameter peripheral:     从设备对象
	- parameter success:        成功订阅的回调
	- parameter failure:        订阅失败的回调
	- parameter timedOut:       订阅超时的回调

	- returns: 返回一个SubscribeRequest对象
	*/
	convenience init(characteristic: CBCharacteristic, peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, update: ((NSData?) -> Void)?) {
		self.init()
		self.characteristic = characteristic
		self.peripheral = peripheral
		self.success = success
		self.failure = failure
		self.update = update
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? SubscribeRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}
	
}

// MARK: Communicate
extension Cusp {

	/**
	订阅

	- parameter characteristic: 特征;
	- parameter peripheral:     从设备;
	- parameter success:        订阅成功的回调;
	- parameter failure:        订阅失败的回调;
	*/
	public func subscribe(characteristic: CBCharacteristic, inPeripheral peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, update: ((NSData?) -> Void)?) {
		dispatch_async(self.mainQ) { () -> Void in
			let req = SubscribeRequest(characteristic: characteristic, peripheral: peripheral, success: success, failure: failure, update: update)
			self.subscribeRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.setNotifyValue(true, forCharacteristic: characteristic)
				})
			}
		}
	}
}
















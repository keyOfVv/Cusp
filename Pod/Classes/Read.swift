//
//  Read.swift
//  CuspExample
//
//  Created by keyOfVv on 2/17/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

/// 读值请求模型
internal class ReadRequest: OperationRequest {

	// MARK: Stored Properties

	var characteristic: CBCharacteristic?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter data:           待写入的数据
	- parameter characteristic: 待写值的特征
	- parameter peripheral:     从设备对象
	- parameter success:        写值成功的回调
	- parameter failure:        写值失败的回调

	- returns: 返回一个WriteRequest对象
	*/
	convenience init(characteristic: CBCharacteristic?, peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
		self.characteristic = characteristic
		self.peripheral     = peripheral
		self.success        = success
		self.failure        = failure
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? ServiceDiscoveringRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}

}

// MARK: Communicate
extension Cusp {

	/**
	读值

	- parameter characteristic: 特征;
	- parameter peripheral:     从设备;
	- parameter success:        读值成功的回调;
	- parameter failure:        读值失败的回调;
	*/
	public func read(characteristic: CBCharacteristic, inPeripheral peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		dispatch_async(self.mainQ) { () -> Void in
			let req = ReadRequest(characteristic: characteristic, peripheral: peripheral, success: success, failure: failure)
			self.readRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.readValueForCharacteristic(characteristic)
				})
			}
		}
	}
}

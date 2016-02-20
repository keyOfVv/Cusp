//
//  CancelConnect.swift
//  Cusp
//
//  Created by keyOfVv on 2/16/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

/// 取消连接请求模型
internal class CancelConnectRequest: NSObject {

	// MARK: Stored Properties

	/// 待连接的从设备
	var peripheral: CBPeripheral!

	/// a closure called after disconnect
	var completion: (() -> Void)?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter peripheral: 待取消连接的从设备
	- parameter success:    成功的回调
	- parameter failure:    失败的回调
	- parameter timedOut:   超时的回调

	- returns: 返回一个ConnectRequest对象
	*/
	internal convenience init(peripheral: CBPeripheral, completion: (() -> Void)?) {
		self.init()
		self.peripheral = peripheral
		self.completion = completion
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CancelConnectRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}

}

// MARK: cancel connect
public extension Cusp {

	/**
	cancel a connecting attempt

	- parameter peripheral: a peripheral instance to which the connection attempt is about to be canceled
	*/
	public func cancelConnection(peripheral: CBPeripheral, completion: (() -> Void)?) {
		// create a cancel-connect request ...
		let req = CancelConnectRequest(peripheral: peripheral, completion: completion)
		// insert it into cancelConnectRequests set
		self.cancelConnectRequests.insert(req)
		// start disconnecting
		self.centralManager.cancelPeripheralConnection(peripheral)
	}
}
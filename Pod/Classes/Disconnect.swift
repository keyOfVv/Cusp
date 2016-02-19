//
//  Disconnect.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

/// 连接请求模型
internal class DisconnectRequest: NSObject {

	// MARK: Stored Properties

	/// 待连接的从设备
	var peripheral: Peripheral!

	/// a closure called after disconnect
	var completion: (() -> Void)?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter peripheral: 待断开连接的从设备
	- parameter success:    成功的回调
	- parameter failure:    失败的回调
	- parameter timedOut:   超时的回调

	- returns: 返回一个ConnectRequest对象
	*/
	internal convenience init(peripheral: Peripheral, completion: (() -> Void)?) {
		self.init()
		self.peripheral = peripheral
		self.completion = completion
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? DisconnectRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}
}


// MARK: Diconnect
extension Cusp {

	/**
	disconnect from a peripheral currently in connection

	- parameter peripheral: a connected peripheral about to be disconnected
	- parameter completion: a closure called right after disconnection or after connection is torn down abnormally
	*/
	public func disconnect(peripheral: CBPeripheral, completion: (() -> Void)?) {
		// create a disconnect request ...
		let req = DisconnectRequest(peripheral: peripheral, completion: completion)
		// insert it into disconnectRequests set
		self.disconnectRequests.insert(req)
		// start disconnecting
		self.centralManager.cancelPeripheralConnection(peripheral)
	}
}

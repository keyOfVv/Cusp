//
//  Connect.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

// MARK: ConnectRequest

/// device connect request
internal class ConnectRequest: CentralOperationRequest {

	// MARK: Stored Properties

	/// closure called when connection broken-down
	internal var abruption: ((NSError?) -> Void)?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	convenient initializer

	- parameter peripheral: a CBPeripheral instance to be connected
	- parameter success:    a closure called when connection established
	- parameter failure:    a closure called when connecting attempt failed or timed-out
	- parameter abruption:  a closure called when connection broken-down

	- returns: a ConnectRequest instance
	*/
	internal convenience init(peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, abruption: ((NSError?) -> Void)?) {
		self.init()
        self.peripheral = peripheral
        self.success    = success
        self.failure    = failure
        self.abruption  = abruption
	}

	override internal var hash: Int {
		return self.peripheral.hash
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? ConnectRequest {
			return self.hash == other.hash
		}
		return false
	}
}


// MARK: Connect

public extension Cusp {

	/**
	connect a peripheral
	连接从设备

	- parameter peripheral: a CBPeripheral instance to be connected. 待连接的从设备
	- parameter success:    a closure called when connection established. 连接成功时执行的闭包
	- parameter failure:    a closure called when connecting attempt failed or timed-out. 连接失败或超时时执行的闭包
	- parameter abruption:  a closure called when connection broken-down. 连接中断时执行的闭包
	*/
	public func connect(peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, abruption: ((NSError?) -> Void)?) {

		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}
		// create a connect request ...
		let req = ConnectRequest(peripheral: peripheral, success: success, failure: failure, abruption: abruption)
		// insert it into connectRequests set
		dispatch_async(self.reqQ) { () -> Void in
			self.connectRequests.insert(req)
		}
		// start connecting
		self.centralManager.connectPeripheral(peripheral.core, options: nil)

		// deal with timeout
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), self.mainQ) { () -> Void in
			if req.timedOut {
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					let error = NSError(domain: "connect operation timed out", code: Error.TimedOut.rawValue, userInfo: nil)
					failure?(error)
				})
				// cancel conncect since it's timed out
				self.cancelConnection(peripheral, completion: nil)
			}
		}
	}
}
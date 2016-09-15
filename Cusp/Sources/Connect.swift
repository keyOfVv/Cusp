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
	internal var abruption: ((CuspError?) -> Void)?

	// MARK: Initializer

	fileprivate override init() {
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
	internal convenience init(peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?, abruption: ((CuspError?) -> Void)?) {
		self.init()
        self.peripheral = peripheral
        self.success    = success
        self.failure    = failure
        self.abruption  = abruption
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		if let other = object as? ConnectRequest {
			return self.hashValue == other.hashValue
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
	public func connect(_ peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?, abruption: ((CuspError?) -> Void)?) {

		// 0. check if ble is available
		if let error = self.assertAvailability() {
			failure?(error)
			return
		}
		// create a connect request ...
		let req = ConnectRequest(peripheral: peripheral, success: success, failure: failure, abruption: abruption)
		// insert it into connectRequests set
		self.reqQ.async { () -> Void in
			self.connectRequests.insert(req)
		}
		// start connecting
		self.centralManager.connect(peripheral.core, options: nil)

		// deal with timeout
		self.mainQ.asyncAfter(deadline: DispatchTime.now() + Double(Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// cancel conncect since it's timed out
				self.cancelConnection(peripheral, completion: nil)
			}
		}
	}
}

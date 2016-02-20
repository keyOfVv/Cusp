//
//  Connect.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

// MARK: ConnectRequest

/// 连接请求模型
internal class ConnectRequest: OperationRequest {

	// MARK: Stored Properties

	/// 超时时长
	internal var timeoutPeriod: NSTimeInterval = 10.0

	/// time out flag
	internal var timedOut = true

	var abruption: ((NSError?) -> Void)?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter peripheral: 待连接的从设备
	- parameter success:    成功的回调
	- parameter failure:    失败的回调
	- parameter timedOut:   超时的回调

	- returns: 返回一个ConnectRequest对象
	*/
	internal convenience init(peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, abruption: ((NSError?) -> Void)?) {
		self.init()
        self.peripheral = peripheral
        self.success    = success
        self.failure    = failure
		self.abruption = abruption
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? ConnectRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}
}


// MARK: Connect
public extension Cusp {

	/**
	connect a peripheral(连接从设备)

	- parameter peripheral: a peripheral instance to be connected(待连接的从设备)
	- parameter success:    a closure that will be called right after peripheral connected
	- parameter failure:    a closure that will be called right after peripheral failed to be connected or timed out
	*/
	public func connect(peripheral: Peripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?, abruption: ((NSError?) -> Void)?) {
		// create a connect request ...
		let req = ConnectRequest(peripheral: peripheral, success: success, failure: failure, abruption: abruption)
		// insert it into connectRequests set
		self.connectRequests.insert(req)
		// start connecting
		self.centralManager.connectPeripheral(peripheral, options: nil)

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), self.mainQ) { () -> Void in
			if req.timedOut {
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					let error = NSError(domain: "connect operation timed out", code: Error.TimedOut.rawValue, userInfo: nil)
					failure?(error)
				})
				self.cancelConnection(peripheral, completion: nil)
			}
		}
	}

}
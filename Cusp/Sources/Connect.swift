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
class ConnectRequest: CentralOperationRequest {

	// MARK: Stored Properties

	/// closure called when connection broken-down
	var abruption: ((CuspError?) -> Void)?

	// MARK: Initializer

	fileprivate override init() { super.init() }

	/**
	convenient initializer

	- parameter peripheral: a CBPeripheral instance to be connected
	- parameter success:    a closure called when connection established
	- parameter failure:    a closure called when connecting attempt failed or timed-out
	- parameter abruption:  a closure called when connection broken-down

	- returns: a ConnectRequest instance
	*/
	convenience init(peripheral: Peripheral, timedOutAfter duration: Double? = nil, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?, abruption: ((CuspError?) -> Void)?) {
		self.init()
        self.peripheral = peripheral
        self.success    = success
        self.failure    = failure
        self.abruption  = abruption
		if let interval = duration {
			self.timeoutPeriod = interval
		}
	}

	override var hash: Int {
		return self.peripheral.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? ConnectRequest else { return false }
		return self.hash == other.hash
	}
}

// MARK: Connect

extension CuspCentral {

	/**
	connect a peripheral

	- parameter peripheral: a CBPeripheral instance to be connected.
	- parameter timedOutAfter: a period of time in second that connecting operation is deemed as timed out after that amount of time elapsed, left nil will fallback to default value (10s)
	- parameter options:	CBConnectPeripheralOptionNotifyOnConnectionKey, CBConnectPeripheralOptionNotifyOnDisconnectionKey, CBConnectPeripheralOptionNotifyOnNotificationKey;
	- parameter success:    a closure called when connection established.
	- parameter failure:    a closure called when connecting attempt failed or timed-out.
	- parameter abruption:  a closure called when connection broken-down.
	*/
	public func connect(_ peripheral: Peripheral, timedOutAfter duration: Double? = nil, options:[String:Any]? = nil, success: ((Response?) -> Void)?, failure: ((CuspError?) -> Void)?, abruption: ((CuspError?) -> Void)?) {
		// 0. check if ble is available
		if let error = assertAvailability() {
			failure?(error)
			return
		}
		// create a connect request ...
		let req = ConnectRequest(peripheral: peripheral, timedOutAfter: duration, success: success, failure: failure, abruption: abruption)
		// insert it into connectRequests set
		reqQ.async { () -> Void in
			self.connectReqs.insert(req)
		}
		// start connecting
		centralManager.connect(peripheral.core, options: options)

		// deal with timeout
		mainQ.asyncAfter(deadline: DispatchTime.now() + Double(req.timeoutPeriod)) { () -> Void in
			if req.timedOut {
				DispatchQueue.main.async(execute: { () -> Void in
					failure?(CuspError.timedOut)
				})
				// cancel conncect since it's timed out
				self.cancelConnection(peripheral, completion: nil)
				// remove req
				self.reqQ.async(execute: { () -> Void in
					self.connectReqs.remove(req)
				})
			}
		}
	}
}

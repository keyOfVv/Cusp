//
//  Disconnect.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

/// request of disconnecting a connected peripheral
internal class DisconnectRequest: NSObject {

	// MARK: Stored Properties

	/// a connected CBPeripheral instance to be disconnected
	internal var peripheral: Peripheral!

	/// a closure called when disconnected
	internal var completion: (() -> Void)?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter peripheral: a connected CBPeripheral instance to be disconnected
	- parameter completion: a closure called when disconnected

	- returns: a DisconnectRequest instance
	*/
	internal convenience init(peripheral: Peripheral, completion: (() -> Void)?) {
		self.init()
		self.peripheral = peripheral
		self.completion = completion
	}

	override internal var hash: Int {
		return self.peripheral.hash
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? DisconnectRequest {
			return self.hash == other.hash
		}
		return false
	}
}


// MARK: Diconnect
extension Cusp {

	/**
	Disconnect a peripheral currently in connection

	- parameter peripheral: a connected CBPeripheral instance to be disconnected
	- parameter completion: a closure called when disconnected
	*/
	public func disconnect(peripheral: Peripheral, completion: (() -> Void)?) {
		// create a disconnect request ...
		let req = DisconnectRequest(peripheral: peripheral, completion: completion)
		// insert it into disconnectRequests set
		dispatch_async(self.reqOpQ) { () -> Void in
			self.disconnectRequests.insert(req)
		}
		// start disconnecting
		self.centralManager.cancelPeripheralConnection(peripheral.core)
	}
}

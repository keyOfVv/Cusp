//
//  CancelConnect.swift
//  Cusp
//
//  Created by keyOfVv on 2/16/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

/// request of cancelling an in-progress connecting attempt
internal class CancelConnectRequest: NSObject {

	// MARK: Stored Properties

	/// a CBPeripheral instance to which the in-progress connecting attempt is to be cancelled
	internal var peripheral: Peripheral!

	/// a closure called when connecting attempt cancelled
	internal var completion: (() -> Void)?

	// MARK: Initializer

	fileprivate override init() { super.init() }

	/**
	Convenient initializer

	- parameter peripheral: a CBPeripheral instance to which the in-progress connecting attempt is to be cancelled
	- parameter completion: a closure called when connecting attempt cancelled

	- returns: a CancelConnectRequest instance
	*/
	internal convenience init(peripheral: Peripheral, completion: (() -> Void)?) {
		self.init()
		self.peripheral = peripheral
		self.completion = completion
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? CancelConnectRequest else { return false }
		return self.hashValue == other.hashValue
	}
}

// MARK: cancel connect

public extension Cusp {

	/**
	Cancel an in-progress connecting attempt

	- parameter peripheral: a peripheral instance to which the connection attempt is about to be canceled
	*/
	public func cancelConnection(_ peripheral: Peripheral, completion: (() -> Void)?) {
		// create a cancel-connect request ...
		let req = CancelConnectRequest(peripheral: peripheral, completion: completion)
		// insert it into cancelConnectRequests set
		self.reqQ.async { () -> Void in
			self.cancelConnectRequests.insert(req)
		}
		// start disconnecting
		self.centralManager.cancelPeripheralConnection(peripheral.core)
	}
}

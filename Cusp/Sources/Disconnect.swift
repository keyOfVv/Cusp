//
//  Disconnect.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation


/// request of disconnecting a connected peripheral
class DisconnectRequest: NSObject {

	// MARK: Stored Properties

	/// a connected CBPeripheral instance to be disconnected
	var peripheral: Peripheral!

	/// a closure called when disconnected
	var completion: (() -> Void)?

	// MARK: Initializer

	fileprivate override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter peripheral: a connected CBPeripheral instance to be disconnected
	- parameter completion: a closure called when disconnected

	- returns: a DisconnectRequest instance
	*/
	convenience init(peripheral: Peripheral, completion: (() -> Void)?) {
		self.init()
		self.peripheral = peripheral
		self.completion = completion
	}

	override var hash: Int {
		return self.peripheral.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? DisconnectRequest {
			return self.hashValue == other.hashValue
		}
		return false
	}
}


// MARK: Diconnect
extension CuspCentral {

	/**
	Disconnect a peripheral currently in connection

	- parameter peripheral: a connected CBPeripheral instance to be disconnected
	- parameter completion: a closure called when disconnected
	*/
	public func disconnect(_ peripheral: Peripheral, completion: (() -> Void)?) {
		// create a disconnect request ...
		let req = DisconnectRequest(peripheral: peripheral, completion: completion)
		// insert it into disconnectRequests set
		self.reqQ.async { () -> Void in
			self.disconnectReqs.insert(req)
		}
		// start disconnecting
		self.centralManager.cancelPeripheralConnection(peripheral.core)
	}
}

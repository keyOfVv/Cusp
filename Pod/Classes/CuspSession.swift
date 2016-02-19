//
//  CuspSession.swift
//  Aura
//
//  Created by keyOfVv on 10/23/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - Cusp Session Definition

/// 从设备连接Session
///
class CommunicatingSession: NSObject {

	// MARK: Stored Properties

	/// 已建立连接的从设备
	weak var peripheral: CBPeripheral!

	var update: ((NSData?) -> Void)?

	var abruption: ((NSError?) -> Void)?

	/// 操作队列
	internal var sessionQ: dispatch_queue_t!

	// MARK: Initializer

	/// 初始化
	override init() {
		super.init()
	}

	/// 快速构造方法
	convenience init(peripheral: CBPeripheral) {
		self.init()
		self.peripheral = peripheral
		let qLabel = "com.keyang.cusp.session." + peripheral.identifier.UUIDString
		self.sessionQ = dispatch_queue_create(qLabel, DISPATCH_QUEUE_CONCURRENT)
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CommunicatingSession {
			return self.peripheral == other.peripheral
		}
		return false
	}
}

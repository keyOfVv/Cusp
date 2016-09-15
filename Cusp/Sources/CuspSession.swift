//
//  CuspSession.swift
//  Aura
//
//  Created by keyOfVv on 10/23/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation
import KEYExtension
import CoreBluetooth

// MARK: - Cusp Session Definition

/// 从设备连接Session
///
class PeripheralSession: NSObject {

	// MARK: Stored Properties

	/// 已建立连接的从设备
	weak var peripheral: Peripheral!

//	var update: ((NSData?) -> Void)?

	var abruption: ((Error?) -> Void)?

	// MARK: Initializer

	/// 初始化
	fileprivate override init() {
		super.init()
	}

	/// 快速构造方法
	convenience init(peripheral: Peripheral) {
		self.init()
		self.peripheral = peripheral
	}

	override internal var hash: Int {
		return peripheral.hashValue
	}

	override internal func isEqual(_ object: Any?) -> Bool {
		if let other = object as? PeripheralSession {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

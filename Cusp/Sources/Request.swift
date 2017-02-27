//
//  Request.swift
//  Aura
//
//  Created by keyOfVv on 10/21/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation

import CoreBluetooth

// MARK: - Super Request Model Definitions

/// 从设备操作请求父类, 请勿直接使用本模型, 使用子类模型即可
class CentralOperationRequest: NSObject {

	// MARK: Stored Properties

	var peripheral: Peripheral!

	/// 连接成功的回调
	var success: ((Response?) -> Void)?

	/// 连接失败的回调
	var failure: ((CuspError?) -> Void)?

	/// timeout period
	var timeoutPeriod: TimeInterval = 10.0

	/// timed out or not
	var timedOut = true

	override init() {
		super.init()
	}
}

/// 从设备操作请求父类, 请勿直接使用本模型, 使用子类模型即可
class PeripheralOperationRequest: NSObject {

	// MARK: Stored Properties

//	var peripheral: Peripheral!

	/// 连接成功的回调
	var success: ((Response?) -> Void)?

	/// 连接失败的回调
	var failure: ((CuspError?) -> Void)?

	/// timeout period
	var timeoutPeriod: TimeInterval = 10.0

	/// timed out or not
	var timedOut = true

	override init() {
		super.init()
	}
}











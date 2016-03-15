//
//  CuspModels.swift
//  Aura
//
//  Created by keyOfVv on 10/21/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - Super Request Model Definitions

/// 从设备操作请求父类, 请勿直接使用本模型, 使用子类模型即可
internal class OperationRequest: NSObject {

	// MARK: Stored Properties

	internal var peripheral: Peripheral!

	/// 连接成功的回调
	internal var success: ((Response?) -> Void)?

	/// 连接失败的回调
	internal var failure: ((NSError?) -> Void)?

	/// timeout period
	internal var timeoutPeriod: NSTimeInterval = 10.0

	/// timed out or not
	internal var timedOut = true

	internal override init() {
		super.init()
	}
}










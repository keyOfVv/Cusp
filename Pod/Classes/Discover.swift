//
//  Discover.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: ServiceDiscoveringRequest

/// 扫描服务请求模型
internal class ServiceDiscoveringRequest: OperationRequest {

	// MARK: Stored Properties

	/// 待扫描的服务UUID数组
	var serviceUUIDs: [CBUUID]?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter serviceUUIDs: 待发现的服务UUID数组
	- parameter peripheral:   从设备对象
	- parameter success:      成功发现服务的回调
	- parameter failure:      发现服务失败的回调
	- parameter timedOut:     发现服务超时的回调

	- returns: 返回一个ServiceDiscoveringRequest对象
	*/
	convenience init(serviceUUIDs: [CBUUID]?, peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
		self.serviceUUIDs = serviceUUIDs
		self.peripheral = peripheral
		self.success = success
		self.failure = failure
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? ServiceDiscoveringRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}

}

// MARK: CharacteristicDiscoveringRequest

/// 扫描服务请求模型
internal class CharacteristicDiscoveringRequest: OperationRequest {

	// MARK: Stored Properties

	/// 待扫描的服务UUID数组
	var characteristicUUIDs: [CBUUID]?

	/// 待扫描的服务
	var service: CBService?

	// MARK: Initializer

	/// 初始化

	/**
	构造方法

	- returns: 返回一个CharacteristicDiscoveringRequest对象
	*/
	private override init() {
		super.init()
	}

	/**
	快速构造方法

	- parameter characteristicUUIDs: 带发现的特征UUID数组
	- parameter service:             特征所属的服务
	- parameter peripheral:          从设备对象
	- parameter success:             成功发现特征的回调
	- parameter failure:			 发现特征失败的回调
	- parameter timedOut:			 发现特征超时的回调

	- returns: 返回一个CharacteristicDiscoveringRequest对象
	*/
	convenience init(characteristicUUIDs: [CBUUID]?, service: CBService, peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
		self.characteristicUUIDs = characteristicUUIDs
		self.service = service
		self.peripheral = peripheral
		self.success = success
		self.failure = failure
	}

	override internal var hash: Int {
		return self.peripheral.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CharacteristicDiscoveringRequest {
			return self.peripheral == other.peripheral
		}
		return false
	}
}

// MARK: Discover
extension Cusp {

	/**
	发现服务

	- parameter serviceUUIDs: 服务UUID数组, 传nil则扫描所有服务;
	- parameter peripheral:   从设备;
	- parameter success:      发现服务成功的回调;
	- parameter failure:      发现服务失败的回调;
	*/
	public func discover(serviceUUIDs: [CBUUID]?, inPeripheral peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		dispatch_async(self.mainQ) { () -> Void in
			let req = ServiceDiscoveringRequest(serviceUUIDs: serviceUUIDs, peripheral: peripheral, success: success, failure: failure)
			self.serviceDiscoveringRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.discoverServices(serviceUUIDs)
				})
			}
		}
	}

	/**
	发现特征

	- parameter characteristicUUIDs: 特征UUID数组, 传nil则扫描所有特征;
	- parameter service:             服务;
	- parameter peripheral:          从设备;
	- parameter success:             发现特征成功的回调;
	- parameter failure:             发现特征连接失败的回调;
	*/
	public func discover(characteristicUUIDs: [CBUUID]?, ofService service: CBService, inPeripheral peripheral: CBPeripheral, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		dispatch_async(self.mainQ) { () -> Void in
			let req = CharacteristicDiscoveringRequest(characteristicUUIDs: characteristicUUIDs, service: service, peripheral: peripheral, success: success, failure: failure)
			self.characteristicDiscoveringRequests.insert(req)

			if let session = self.sessionFor(peripheral) {
				dispatch_async(session.sessionQ, { () -> Void in
					peripheral.discoverCharacteristics(characteristicUUIDs, forService: service)
				})
			}
		}
	}
}









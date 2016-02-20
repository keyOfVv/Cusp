//
//  Cusp.swift
//  Aura
//
//  Created by keyang on 10/21/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation
import CoreBluetooth

/// main operation queue identifier(主并发队列ID)
private let QIDMain = "com.keyang.cusp.mainConcurrentQ"

/// A framework for BLE-device communication(用于BLE通讯的框架)
public class Cusp: NSObject {

	/// Singleton Instance(单例)
	public class var central: Cusp {
		struct Static {
			static let instance: Cusp = Cusp()
		}
		return Static.instance
	}

	private override init() {
		super.init()
	}

	/// main operation concurrent queue for cusp(主并发队列)
    internal let mainQ: dispatch_queue_t = dispatch_queue_create(QIDMain, DISPATCH_QUEUE_CONCURRENT)

	/// central avator, read only(蓝牙主设备对象, 只读)
	private(set) lazy var centralManager: CBCentralManager = {
		return CBCentralManager(delegate: self, queue: self.mainQ, options: nil)
	}()

	/// BLE central state(蓝牙主设备状态)
	public var state: State {
		return State(rawValue: self.centralManager.state.rawValue)!
	}

	// MARK: Requests

	/// scan request set
	internal var scanRequests: Set<ScanRequest> = Set<ScanRequest>()

	/// a set contains all the connect requests currently in performing(连接请求的集合, 包含所有正在连接的请求)
	internal var connectRequests: Set<ConnectRequest> = Set<ConnectRequest>()

	/// a set contains all the cancel-connect requests currently in performing(取消连接请求的集合, 包含所有正在取消连接的请求)
	internal var cancelConnectRequests: Set<CancelConnectRequest> = Set<CancelConnectRequest>()

	/// a set contains all the disconnect requests currently in performing(断开连接请求的集合, 包含所有正在断开连接的请求)
	internal var disconnectRequests: Set<DisconnectRequest> = Set<DisconnectRequest>()

	/// a set contains requests of service discovering
	internal var serviceDiscoveringRequests: Set<ServiceDiscoveringRequest> = Set<ServiceDiscoveringRequest>()

	/// a set contains requests of characteristic discovering
	internal var characteristicDiscoveringRequests: Set<CharacteristicDiscoveringRequest> = Set<CharacteristicDiscoveringRequest>()

	/// a set contains requests of write characteristic value
	internal var writeRequests: Set<WriteRequest> = Set<WriteRequest>()

	/// a set contains requests of read characteristic value
	internal var readRequests: Set<ReadRequest> = Set<ReadRequest>()

	/// a set contains requests of subscribe characteristic value update
	internal var subscribeRequests: Set<SubscribeRequest> = Set<SubscribeRequest>()

	/// a set contains requests of unsubscribe characteristic value update
	internal var unsubscribeRequests: Set<UnsubscribeRequest> = Set<UnsubscribeRequest>()

	/// a set contains requests of RSSI reading
	internal var RSSIRequests: Set<RSSIRequest> = Set<RSSIRequest>()

	// MARK: Peripheral Sets

	/// discovered peripherals after scanning(扫描后获取的蓝牙设备集合)
	internal var discoveredPeripherals: Set<Peripheral> = Set<Peripheral>()

	/// communicating session with connected peripheral
	internal var sessions: Set<CommunicatingSession> = Set<CommunicatingSession>()
}

// MARK: - Interface

// MARK: - Preparation
extension Cusp {

	/**
	prepare BLE module, this method shall be called once before any BLE operation(执行任何蓝牙功能前必须执行一次本方法)
	*/
	public func prepare() {
		self.centralManager.state.rawValue
	}

}














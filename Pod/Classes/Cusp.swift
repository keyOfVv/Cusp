//
//  Cusp.swift
//  Aura
//
//  Created by keyang on 10/21/15.
//  Copyright © 2015 com.keyang. All rights reserved.
//

import Foundation

/// Notification
public let CuspStateDidChangeNotification = "CuspStateDidChangeNotification"

/// main operation queue identifier (主并发队列ID)
private let QIDMain = "com.keyang.cusp.mainConcurrentQ"

/// request operation serial queue identifier
private let QIDReqOp = "com.keyang.cusp.requestOperationQ"

/// session operation serial queue identifier
private let QIDSesOp = "com.keyang.cusp.sessionOperationQ"

/// Bluetooth Low Energy library in swift (使用swift编写的BLE通讯框架)
public class Cusp: NSObject {

	/// Singleton (单例)
	public class var central: Cusp {
		struct Static {
			static let instance: Cusp = Cusp()
		}
		return Static.instance
	}

	private override init() {
		super.init()
	}

	/// main operation concurrent queue (主并发队列)
    internal let mainQ: dispatch_queue_t = dispatch_queue_create(QIDMain, DISPATCH_QUEUE_CONCURRENT)

	/// request operation serial queue
	internal let reqOpQ: dispatch_queue_t = dispatch_queue_create(QIDReqOp, DISPATCH_QUEUE_SERIAL)

	/// session operation serial queue
	internal let sesOpQ: dispatch_queue_t = dispatch_queue_create(QIDSesOp, DISPATCH_QUEUE_SERIAL)

	/// central avator, read only(蓝牙主设备对象, 只读)
	private(set) lazy var centralManager: CentralManager = {
		return CentralManager(delegate: self, queue: self.mainQ, options: nil)
	}()

	/// BLE state (蓝牙状态)
	public var state: State {
		return State(rawValue: self.centralManager.state.rawValue)!
	}

	// MARK: Requests

	/// scan request set (扫描请求的集合)
    internal var scanRequests                      = Set<ScanRequest>()

	/// connect requests set (连接请求的集合)
    internal var connectRequests                   = Set<ConnectRequest>()

	/// cancel-connects set (取消连接请求的集合)
    internal var cancelConnectRequests             = Set<CancelConnectRequest>()

	/// disconnect requests set (断开连接请求的集合)
    internal var disconnectRequests                = Set<DisconnectRequest>()

	/// requests of service discovering (发现服务请求的集合)
    internal var serviceDiscoveringRequests        = Set<ServiceDiscoveringRequest>()

	/// requests of characteristic discovering (发现特征请求的集合)
    internal var characteristicDiscoveringRequests = Set<CharacteristicDiscoveringRequest>()

	/// requests of write characteristic value (写值请求的集合)
    internal var writeRequests                     = Set<WriteRequest>()

	/// requests of read characteristic value (读值请求的集合)
    internal var readRequests                      = Set<ReadRequest>()

	/// requests of subscribe characteristic value (订阅请求的集合)
    internal var subscribeRequests                 = Set<SubscribeRequest>()

	/// requests of unsubscribe characteristic value (退订请求的集合)
    internal var unsubscribeRequests               = Set<UnsubscribeRequest>()

	/// requests of RSSI reading (信号强度查询请求的集合)
    internal var RSSIRequests                      = Set<RSSIRequest>()

	// MARK: Peripheral Sets

	/// ever discovered peripherals after scanning (扫描后获取的蓝牙设备集合)
    internal var discoveredPeripherals             = Set<Peripheral>()

	/// communicating session with connected peripheral (已建立的连接集合)
    internal var sessions                          = Set<CommunicatingSession>()
}

// MARK: - Interface

// MARK: - Preparation
public extension Cusp {

	/**
	Prepare BLE module, this method shall be called once before any BLE operation.
	执行任何蓝牙功能前必须执行一次本方法
	*/
	public func prepare() {
		self.centralManager.state.rawValue
	}

}

// MARK: - Availability Check

extension Cusp {

	/**
	Check if ble is available. A NSError object will be returned if ble is unavailable, or else return nil.

	- returns: A NSError object or nil.
	*/
	internal func assertAvailability() -> NSError? {

		var errorCode: Int?
		var domain = ""
		switch self.state {
		case .PoweredOff:
			errorCode = Error.PoweredOff.rawValue
			domain    = "BLE is powered off."
			break
		case .Resetting:
			errorCode = Error.Resetting.rawValue
			domain    = "BLE is resetting, please try again later."
			break
		case .Unauthorized:
			errorCode = Error.Unauthorized.rawValue
			domain    = "BLE is unauthorized."
			break
		case .Unsupported:
			errorCode = Error.Unsupported.rawValue
			domain    = "BLE is unsupported."
			break
		case .Unknown:
			errorCode = Error.Unknown.rawValue
			domain    = "BLE is in unknown state."
			break
		default:
			break
		}

		if let code = errorCode {
			return NSError(domain: domain, code: code, userInfo: nil)
		}

		return nil
	}
}

// MARK: - Custom CBPeripheral subclass registeration
extension Cusp {

//	public func registerCustomPeripheral(ofClass: class, pattern: String) {
//
//	}
}














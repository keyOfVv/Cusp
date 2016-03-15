//
//  Cusp.swift
//  Aura
//
//  Created by keyang on 10/21/15.
//  Copyright © 2015 com.keyang. All rights reserved.
//
/*
 *
 *
 */

import Foundation
import CoreBluetooth

// MARK: Notifications

/// Cusp state change notification, posted in call of method "-centralManagerDidUpdateState(_:)"
public let CuspStateDidChangeNotification = "CuspStateDidChangeNotification"

// MARK: Constants

/// main operation queue identifier
private let CUSP_CENTRAL_Q_MAIN_CONCURRENT = "com.keyang.cusp.central_Q_main_concurrent"

/// request operation serial queue identifier
private let CUSP_CENTRAL_Q_REQUEST_SERIAL  = "com.keyang.cusp.central_Q_request_serial"

/// session operation serial queue identifier
private let CUSP_CENTRAL_Q_SESSION_SERIAL  = "com.keyang.cusp.central_Q_session_serial"

/// Bluetooth Low Energy library in swift
public class Cusp: NSObject {

	/// Singleton
	public class var central: Cusp {
		struct Static {
			static let instance: Cusp = Cusp()
		}
		return Static.instance
	}

	private override init() {
		super.init()
	}

	/// main operation concurrent queue, operations (scan, connect, cancel-connect, disconnect) will be submitted to this Q
    internal let mainQ: dispatch_queue_t = dispatch_queue_create(CUSP_CENTRAL_Q_MAIN_CONCURRENT, DISPATCH_QUEUE_CONCURRENT)

	/// request operation serial queue, operations (add/remove) on reqs (scan, connect, cancel-connect, disconnect) will be submitted to this Q;
    internal let reqQ: dispatch_queue_t  = dispatch_queue_create(CUSP_CENTRAL_Q_REQUEST_SERIAL, DISPATCH_QUEUE_SERIAL)

	/// session operation serial queue, operations (add/remove) on sessions (with peripheral) will be submitted to this Q;
    internal let sesQ: dispatch_queue_t  = dispatch_queue_create(CUSP_CENTRAL_Q_SESSION_SERIAL, DISPATCH_QUEUE_SERIAL)

	/// central avator, read only
	private(set) lazy var centralManager: CentralManager = {
		return CentralManager(delegate: self, queue: self.mainQ, options: nil)
	}()

	/// BLE state
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

	internal func sessionFor(peripheral: Peripheral?) -> CommunicatingSession? {
		if peripheral == nil { return nil }

		var tgtSession: CommunicatingSession?

		dispatch_sync(self.sesQ) { () -> Void in
			for session in self.sessions {
				if session.peripheral == peripheral {
					tgtSession = session
					break
				}
			}
		}

		return tgtSession
	}

	/**
	retrieve specific Peripheral object that core matches

	- parameter core: CBPeripheral object

	- returns: Peripheral object or nil if not found
	*/
	internal func peripheralFor(core: CBPeripheral) -> Peripheral? {
		for p in discoveredPeripherals {
			if p.core == core {
				return p
			}
		}
		return nil
	}
}













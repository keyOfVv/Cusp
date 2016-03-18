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

// MARK: - Protocol
@objc public protocol CustomPeripheral: NSObjectProtocol {
	var core: CBPeripheral { get }
	init(core: CBPeripheral)
}

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

	/// scan request set
    internal var scanRequests          = Set<ScanRequest>()

	/// connect requests set
    internal var connectRequests       = Set<ConnectRequest>()

	/// cancel-connects set
    internal var cancelConnectRequests = Set<CancelConnectRequest>()

	/// disconnect requests set
    internal var disconnectRequests    = Set<DisconnectRequest>()

	// MARK: Peripheral Sets

	/// discovered peripherals ever after scanning
    internal var availables            = Set<Peripheral>()

	/// session of connected peripheral
    internal var sessions              = Set<PeripheralSession>()

	/// registered custom classes
	internal var customClasses: Dictionary<String, AnyClass> = [:]

	public var isConnectedWithAnyPeripheral: Bool {
		return !sessions.isEmpty
	}
}

// MARK: - Interface

// MARK: - Preparation
public extension Cusp {

	/**
	Prepare BLE module, this method shall be called once before any BLE operation.
	*/
	public class func prepare() {
		if !self.isBLEAvailable() {
			print("BLE is currently unavailable")
		}
	}

	/**
	check if BLE is available

	- returns: boolean value
	*/
	public class func isBLEAvailable() -> Bool {
		if let _ = Cusp.central.assertAvailability() {
			return false
		}
		return true
	}

	/**
	register peripheral of a custom class, which shall be a subclass of Peripheral; any peripheral object of which the name matches specific pattern will be initialized in custom class.

	- parameter aClass: custom peripheral class subclassing Peripheral
	- parameter p:      regex pattern for name
	*/
	public func registerPeripheralClass<T: CustomPeripheral>(aClass: T.Type, forNamePattern p: String) {
		self.customClasses[p] = aClass
	}
}

// MARK: - Availability Check

internal extension Cusp {

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

// MARK: -
extension Cusp {

	/**
	Retrieve session for specific peripheral.
	Note: there is no connected-peripheral array in Cusp, each connected peripheral will be wrapped in PeripheralSession object and stored in property "sessions".

	- parameter peripheral: Peripheral object

	- returns: PeripheralSession object or nil if doesn't exist
	*/
	internal func sessionFor(peripheral: Peripheral?) -> PeripheralSession? {
		// return nil if peripheral is nil
		if peripheral == nil { return nil }

		// session retrieval operation shall be performed in sesQ to prevent race condition
		var tgtSession: PeripheralSession?
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
}













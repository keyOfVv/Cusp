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
import KEYExtension
import CoreBluetooth

// MARK: - Constants

/// once token for -prepare()
private var onceToken = Int()

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
open class Cusp: NSObject {

	/// Singleton
	open class var central: Cusp {
		struct Static {
			static let instance: Cusp = Cusp()
		}
		return Static.instance
	}

	fileprivate override init() {
		super.init()
	}

	/// main operation concurrent queue, operations (scan, connect, cancel-connect, disconnect) will be submitted to this Q
    internal let mainQ: DispatchQueue = DispatchQueue(label: CUSP_CENTRAL_Q_MAIN_CONCURRENT, attributes: DispatchQueue.Attributes.concurrent)

	/// request operation serial queue, operations (add/remove) on reqs (scan, connect, cancel-connect, disconnect) will be submitted to this Q;
    internal let reqQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_REQUEST_SERIAL, attributes: [])

	/// session operation serial queue, operations (add/remove) on sessions (with peripheral) will be submitted to this Q;
    internal let sesQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_SESSION_SERIAL, attributes: [])

	/// central avator, read only
	open fileprivate(set) lazy var centralManager: CentralManager = {
		return CentralManager(delegate: self, queue: self.mainQ, options: nil)
	}()

	/// BLE state
	open var state: State {
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
    internal var availables = Set<Peripheral>()

	/// session of connected peripheral
    internal var sessions              = Set<PeripheralSession>()

	/// registered custom classes
	internal var customClasses		   = [(String, AnyClass)]()

	/// a boolean value indicates whether Cusp is connected with any peripheral
	open var isConnectedWithAnyPeripheral: Bool {
		return !sessions.isEmpty
	}

	/// a boolean value indicates whether Cusp is scanning
	open var isScanning: Bool = false
}

// MARK: - Interface

// MARK: - Preparation
public extension Cusp {

	/**
	Prepare BLE module, this method shall be called once before any BLE operation.
	*/
	@available(*, unavailable, message: "use -prepare(_:) instead")
	public class func prepare() {
		if !self.isBLEAvailable() {
			print("BLE is currently unavailable")
		}
	}

	/**
	check BLE availability, one shall always call this method before any BLE operation

	- parameter completion: a block after completed preparing
	*/
	public class func prepare(_ completion: ((_ available: Bool) -> Void)?) {
		// since checking ble status needs little
//		dispatch_once(&onceToken) {
			_ = self.isBLEAvailable()
			Cusp.central.mainQ.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
				GLOBAL_MAIN_QUEUE.async(execute: {
					completion?(self.isBLEAvailable())
				})
			})
			return
//		}
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
	public func registerPeripheralClass<T: CustomPeripheral>(_ aClass: T.Type, forNamePattern p: String) {
		self.customClasses.append((p, aClass))
	}

	public func registerPeripheralClass_oc(_ aClass: AnyClass, forNamePattern p: String) {
		self.customClasses.append((p, aClass))
	}

	/**
	clear all
	*/
	public func clear() {
//		dispatch_async(reqQ) { () -> Void in
//			self.sessions.removeAll()
//			self.availables.removeAll()
//			self.scanRequests.removeAll()
//			self.connectRequests.removeAll()
//			self.disconnectRequests.removeAll()
//			self.cancelConnectRequests.removeAll()
//		}
	}
}

// MARK: - Availability Check

internal extension Cusp {

	/**
	Check if ble is available. A NSError object will be returned if ble is unavailable, or else return nil.

	- returns: A NSError object or nil.
	*/
	internal func assertAvailability() -> Error? {

		var errorCode: Int?
		var domain = ""
		switch self.state {
		case .poweredOff:
			errorCode = Error.poweredOff.rawValue
			domain    = "BLE is powered off."
			break
		case .resetting:
			errorCode = Error.resetting.rawValue
			domain    = "BLE is resetting, please try again later."
			break
		case .unauthorized:
			errorCode = Error.unauthorized.rawValue
			domain    = "BLE is unauthorized."
			break
		case .unsupported:
			errorCode = Error.unsupported.rawValue
			domain    = "BLE is unsupported."
			break
		case .unknown:
			errorCode = Error.unknown.rawValue
			domain    = "BLE is in unknown state."
			break
		default:
			break
		}

		if let code = errorCode {
//			return NSError(domain: domain, code: code, userInfo: nil)
			return Error(rawValue: code)
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
	internal func sessionFor(_ peripheral: Peripheral?) -> PeripheralSession? {
		// return nil if peripheral is nil
		if peripheral == nil { return nil }

		// session retrieval operation shall be performed in sesQ to prevent race condition
		var tgtSession: PeripheralSession?
		self.sesQ.sync { () -> Void in
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












//
//  Cusp.swift
//  Aura
//
//  Created by keyang on 10/21/15.
//  Copyright © 2015 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - Constants

/// once token for -prepare()
private var onceToken = Int()

// MARK: - Protocol
@objc public protocol CustomPeripheral: NSObjectProtocol {
	var core: CBPeripheral { get }
	init(core: CBPeripheral)
}

// MARK: - Notifications

/// Cusp state change notification, posted in call of method "-centralManagerDidUpdateState(_:)"
@available(*, deprecated, message: "use Notification.Name.CuspStateDidChange")
public let CuspStateDidChangeNotification = "CuspStateDidChangeNotification"

extension Notification.Name {
	public static let CuspStateDidChange: Notification.Name = Notification.Name("CuspStateDidChangeNotification")
}

// MARK: - Constants

/// main operation queue identifier
private let CUSP_CENTRAL_Q_MAIN_CONCURRENT = "com.keyang.cusp.central_Q_main_concurrent"
/// request operation serial queue identifier
private let CUSP_CENTRAL_Q_REQUEST_SERIAL  = "com.keyang.cusp.central_Q_request_serial"
/// session operation serial queue identifier
private let CUSP_CENTRAL_Q_SESSION_SERIAL  = "com.keyang.cusp.central_Q_session_serial"

// MARK: - Definition

/// Bluetooth Low Energy library in swift
public class Cusp: NSObject {

	/// Singleton
	public class var central: Cusp {
		struct Static {
			static let instance: Cusp = Cusp()
		}
		return Static.instance
	}
	/// output debug log to console, disable this in release configuration
	static var showsDebugLog: Bool = false
	/// intentedly left private
	fileprivate override init() { super.init() }
	/// main operation concurrent queue, for all BLE-related operations (scan, connect, cancel-connect, disconnect)
    let mainQ: DispatchQueue = DispatchQueue(label: CUSP_CENTRAL_Q_MAIN_CONCURRENT, attributes: DispatchQueue.Attributes.concurrent)
	/// request operation serial queue, for all operations (add/remove) on reqs (scan, connect, cancel-connect, disconnect)
    let reqQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_REQUEST_SERIAL, attributes: [])
	/// session operation serial queue, for all operations (add/remove) on sessions (connected peripherals)
    let sesQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_SESSION_SERIAL, attributes: [])

	/// true CB central, read only
	fileprivate(set) lazy var centralManager: CentralManager = {
		return CentralManager(delegate: self, queue: self.mainQ, options: nil)
	}()

	/// BLE state
	public var state: State {
		return State(rawValue: centralManager.state.rawValue)!
	}

	// MARK: Requests Collection

	/// scan request set
    var scanReqs = Set<ScanRequest>()
	/// connect requests set
    var connectReqs = Set<ConnectRequest>()
	/// cancel-connects set
    var cancelConnectReqs = Set<CancelConnectRequest>()
	/// disconnect requests set
    var disconnectReqs = Set<DisconnectRequest>()

	// MARK: Peripheral Collection

	/// discovered peripherals ever after scanning
    var availables = Set<Peripheral>()
	/// session of connected peripheral
    var sessions = Set<PeripheralSession>()
	/// registered custom classes
	var customClasses = [(String, AnyClass)]()

	/// a boolean value indicates whether Cusp is connected with any peripheral
	public var isConnectedWithAnyPeripheral: Bool {
		return !sessions.isEmpty
	}
	/// a boolean value indicates whether Cusp is scanning;
	public internal(set) var isScanning: Bool = false

	public class func enableDebugLog(enabled: Bool) {
		self.showsDebugLog = enabled
	}
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
			Cusp.central.mainQ.asyncAfter(deadline: DispatchTime.now() + Double(0.1), execute: {
				DispatchQueue.main.async(execute: { 
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
	internal func assertAvailability() -> CuspError? {
		switch self.state {
		case .poweredOff:
			return CuspError.poweredOff
		case .resetting:
			return CuspError.resetting
		case .unauthorized:
			return CuspError.unauthorized
		case .unsupported:
			return CuspError.unsupported
		case .unknown:
			return CuspError.unknown
		default:
			return nil
		}
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













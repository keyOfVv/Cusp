//
//  Cusp.swift
//  Aura
//
//  Created by keyang on 10/21/15.
//  Copyright © 2015 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

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

private let CUSP_BACKGROUND_TASK_NAME  = "com.keyang.cusp.backgroundTask"

private let CUSP_CENTRAL_IDENTIFIER_DEFAULT = "com.keyang.cusp.central.identifier.default"

// MARK: - Definition

/// Bluetooth Low Energy library in swift
public class CuspCentral: NSObject {

	/// Singleton
	@available(*, deprecated, message: "use defaultCentral instead")
	public class var central: CuspCentral {
		return CuspCentral.defaultCentral
	}
	/// default central
	public class var defaultCentral: CuspCentral {
		struct Static {
			static let instance: CuspCentral = CuspCentral()
		}
		return Static.instance
	}
	/// output debug log to console, disable this in release configuration
	static var showsDebugLog: Bool = false
	/// intentedly left private
	fileprivate override init() {
		super.init()
		CuspCentral.prepare { (available) in
			dog("Cusp Central initialized, BLE is now \(available ? "available" : "unavailable")")
		}
	}
	/// main operation concurrent queue, for all BLE-related operations (scan, connect, cancel-connect, disconnect)
    let mainQ: DispatchQueue = DispatchQueue(label: CUSP_CENTRAL_Q_MAIN_CONCURRENT, attributes: DispatchQueue.Attributes.concurrent)
	/// request operation serial queue, for all operations (add/remove) on reqs (scan, connect, cancel-connect, disconnect)
    let reqQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_REQUEST_SERIAL, attributes: [])
	/// session operation serial queue, for all operations (add/remove) on sessions (connected peripherals)
    let sesQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_SESSION_SERIAL, attributes: [])

	static fileprivate(set) var centralRestoreIdentifier: String?

	/// true CB central, read only
	fileprivate(set) lazy var centralManager: CentralManager = {
		if let id = centralRestoreIdentifier {
			dog("central initialized with restore id=\(id)")
			return CentralManager(delegate: self, queue: self.mainQ, options: [CBCentralManagerOptionRestoreIdentifierKey: id])
		} else {
			dog("central initialized with default restore id")
			return CentralManager(delegate: self, queue: self.mainQ, options: [CBCentralManagerOptionRestoreIdentifierKey: CUSP_CENTRAL_IDENTIFIER_DEFAULT])
		}
	}()

	/// BLE state
	public var state: CuspBLEState {
		return CuspBLEState(rawValue: centralManager.state.rawValue)!
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

	var backgroundTaskID: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
}

// MARK: - Interface

// MARK: - Preparation
extension CuspCentral {

	/**
	Prepare Cusp before any BLE operation

	- parameter completion: a block after completed preparing
	*/
	class func prepare(_ completion: ((_ available: Bool) -> Void)?) {
		prepare(withCentralIdentifier: CUSP_CENTRAL_IDENTIFIER_DEFAULT, completion: completion)
	}

	/**
	Prepare Cusp before any BLE operation, specify UID for central in case restoring BLE related objects is necessary

	- parameter restoreIdentifier: a UID for restoring central after app back into foreground
	- parameter completion:		   a block after completed preparing
	*/
	class func prepare(withCentralIdentifier restoreIdentifier: String?, completion: ((_ available: Bool) -> Void)?) {
		centralRestoreIdentifier = restoreIdentifier
		// since checking ble status needs little
		_ = self.isBLEAvailable()
		CuspCentral.defaultCentral.mainQ.asyncAfter(deadline: DispatchTime.now() + Double(0.1), execute: {
			DispatchQueue.main.async(execute: {
				completion?(self.isBLEAvailable())
			})
		})
	}

	/**
	check if BLE is available

	- returns: boolean value
	*/
	public class func isBLEAvailable() -> Bool {
		if let _ = CuspCentral.defaultCentral.assertAvailability() {
			return false
		}
		return true
	}

	/**
	register peripheral of a custom class, which shall be a subclass of Peripheral; any peripheral object of which the name matches specific pattern will be initialized in custom class.

	- parameter aClass: custom peripheral class subclassing Peripheral
	- parameter p:      regex pattern for name
	*/
	@available(*, deprecated, message: "")
	public func registerPeripheralClass<T: CustomPeripheral>(_ aClass: T.Type, forNamePattern p: String) {
		self.customClasses.append((p, aClass))
	}
	@available(*, deprecated, message: "")
	public func registerPeripheralClass_oc(_ aClass: AnyClass, forNamePattern p: String) {
		self.customClasses.append((p, aClass))
	}

	/**
	clear all
	*/
	@available(*, deprecated, message: "this method does nothing currently")
	func clear() {
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

extension CuspCentral {

	/**
	Check if ble is available. A NSError object will be returned if ble is unavailable, or else return nil.

	- returns: A NSError object or nil.
	*/
	func assertAvailability() -> CuspError? {
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
extension CuspCentral {

	/**
	Retrieve session for specific peripheral.
	Note: there is no connected-peripheral array in Cusp, each connected peripheral will be wrapped in PeripheralSession object and stored in property "sessions".

	- parameter peripheral: Peripheral object

	- returns: PeripheralSession object or nil if doesn't exist
	*/
	@available(*, deprecated, message: "user subscription instead")
	func sessionFor(_ peripheral: Peripheral?) -> PeripheralSession? {
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

	/**
	Retrieve session for specific peripheral.
	Note: there is no connected-peripheral array in Cusp, each connected peripheral will be wrapped in PeripheralSession object and stored in property "sessions".
	*/
	subscript(peripheral: Peripheral?) -> PeripheralSession? {
		// return nil if peripheral is nil
		guard let p = peripheral else {
			return nil
		}
		// session retrieval operation shall be performed in sesQ to prevent race condition
		var tgtSession: PeripheralSession?
		sesQ.sync { 
			for s in sessions {
				if s.peripheral == p {
					tgtSession = s
					break
				}
			}
		}
		return tgtSession
	}
}

// MARK: - Background task
extension CuspCentral {

	/**
	Execute operations while application is in background mode;
	IMPORTANT: 
	- This method MUST be called in AppDelegate's -applicationDidEnterBackground(_ application: UIApplication) method, otherwise task won't be executed at all;
	- `UIBackgroundModes` key MUST contain `bluetooth-central` value in file `Info.plist`;
	- If perform scanning in background, adverisingUUID array MUST NOT be nil or empty;
	
	- parameter withApplication: an UIApplication object;
	- parameter task: a closure containing codes executed while app is in background mode;

	*/
	public func executeBackgroundTask(withApplication app: UIApplication, task: (() -> Void)?) {
		backgroundTaskID = app.beginBackgroundTask(withName: CUSP_BACKGROUND_TASK_NAME) {
			app.endBackgroundTask(self.backgroundTaskID)
			self.backgroundTaskID = UIBackgroundTaskInvalid
		}
		DispatchQueue.global().async {
			task?()
		}
	}
}

public func enableDebugLog(enabled: Bool) {
	CuspCentral.showsDebugLog = enabled
}









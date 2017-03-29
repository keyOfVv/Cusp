//
//  Cusp.swift
//  Aura
//
//  Created by keyang on 10/21/15.
//  Copyright © 2015 com.keyang. All rights reserved.
//

import Foundation
import CoreBluetooth

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

	/// default central
	public class var `default`: CuspCentral {
		struct Static {
			static let instance: CuspCentral = CuspCentral(withRestoreIdentifier: nil)
		}
		return Static.instance
	}

	/// output debug log to console, disable this in release configuration
	static var showsDebugLog: Bool = false
	/// intentedly left private
	fileprivate init(withRestoreIdentifier id: String?) {
		dog("central initialized with restore id=\(id ?? CUSP_CENTRAL_IDENTIFIER_DEFAULT)")
		centralRestoreIdentifier = id ?? CUSP_CENTRAL_IDENTIFIER_DEFAULT
		super.init()
	}
	/// main operation concurrent queue, for all BLE-related operations (scan, connect, cancel-connect, disconnect)
	let mainQ: DispatchQueue = DispatchQueue(label: CUSP_CENTRAL_Q_MAIN_CONCURRENT, qos: DispatchQoS.userInteractive, attributes: DispatchQueue.Attributes.concurrent)
	/// request operation serial queue, for all operations (add/remove) on reqs (scan, connect, cancel-connect, disconnect)
	let reqQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_REQUEST_SERIAL, qos: DispatchQoS.userInteractive, attributes: [])
	/// session operation serial queue, for all operations (add/remove) on sessions (connected peripherals)
	let sesQ: DispatchQueue  = DispatchQueue(label: CUSP_CENTRAL_Q_SESSION_SERIAL, qos: DispatchQoS.userInteractive, attributes: [])

	fileprivate(set) var centralRestoreIdentifier: String

	/// true CB central, read only
	fileprivate(set) lazy var centralManager: CentralManager = {
		let centralManager = CentralManager(delegate: self, queue: self.mainQ, options: [CBCentralManagerOptionRestoreIdentifierKey: self.centralRestoreIdentifier])
		dog("preparing CBCentralManager")
		let semaphore = DispatchSemaphore(value: 0)
		self.mainQ.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: { semaphore.signal() })
		semaphore.wait()
		dog("CBCentralManager is ready")
		return centralManager
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

	/// a boolean value indicates whether Cusp is connected with any peripheral
	public var isConnectedWithAnyPeripheral: Bool {
		return !sessions.isEmpty
	}
	/// a boolean value indicates whether Cusp is scanning;
	public internal(set) var isScanning: Bool = false

	var backgroundTaskID: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
}

// MARK: -
extension CuspCentral {

	/**
	check if BLE is available

	- returns: boolean value
	*/
	@available(*, deprecated, message: "this method will be removed in near future")
	public func isBLEAvailable() -> Bool {
		if let _ = self.assertAvailability() {
			return false
		}
		return true
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
		case .poweredOff:	return .poweredOff
		case .resetting:	return .resetting
		case .unauthorized: return .unauthorized
		case .unsupported:	return .unsupported
		case .unknown:		return .unknown
		default:			return nil
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
			tgtSession = sessions.first { $0.peripheral == peripheral }
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
			tgtSession = sessions.first { $0.peripheral == p }
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








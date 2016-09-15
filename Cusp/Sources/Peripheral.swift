//
//  Peripheral.swift
//  Pods
//
//  Created by Ke Yang on 3/15/16.
//
//

import Foundation

import CoreBluetooth

/// operation concurrent queue identifier
private let CUSP_PERIPHERAL_Q_OPERATION_CONCURRENT = "com.keyang.cusp.peripheral.operationQ"

/// request serial queue identifier
private let CUSP_PERIPHERAL_Q_REQUEST_SERIAL = "com.keyang.cusp.peripheral.requestQ"

/// subscription serial queue identifier
private let CUSP_PERIPHERAL_Q_SUBSCRIPTION_SERIAL = "com.keyang.cusp.peripheral.subscriptionQ"

public enum PeripheralState : Int {

	case disconnected
	case connecting
	case connected
//	@available(iOS 9.0, *)
//	case Disconnecting
	case unknown	// this shall be "Disconnecting" in version 9.x
}

/// peripheral class for Cusp, shall be subclassed by custom peripheral class
@objc open class Peripheral: NSObject, CustomPeripheral {

	/// a retained reference to CBPeripheral object, read-only
	open fileprivate(set) var core: CBPeripheral {
		didSet {
			core.delegate = self
		}
	}

	required public init(core: CBPeripheral) {
		self.core = core
	}

	// MARK: Computed Properties

	/// name of peripheral
	open var name: String? {
		return core.name
	}

	/// state of peripheral
	open var state: PeripheralState {
		return PeripheralState(rawValue: core.state.rawValue) ?? .disconnected
	}

	/// uuid of peripheral
	open var identifier: Foundation.UUID {
		return core.identifier
	}

	/// operation concurrent queue for all operations including read, write, subscribe, unsubscribe, RSSI, etc.;
	internal let operationQ: DispatchQueue = DispatchQueue(label: CUSP_PERIPHERAL_Q_OPERATION_CONCURRENT, attributes: DispatchQueue.Attributes.concurrent)

	/// request serial queue for all add/remove operation on all kinds of request;
	internal var requestQ: DispatchQueue = DispatchQueue(label: CUSP_PERIPHERAL_Q_REQUEST_SERIAL, attributes: [])

	/// subscription serial queue for subscription operation;
	internal var subscriptionQ: DispatchQueue = DispatchQueue(label: CUSP_PERIPHERAL_Q_SUBSCRIPTION_SERIAL, attributes: [])

	/// requests of service discovering
	internal var serviceDiscoveringRequests        = Set<ServiceDiscoveringRequest>()

	/// requests of characteristic discovering
	internal var characteristicDiscoveringRequests = Set<CharacteristicDiscoveringRequest>()

	/// requests of read characteristic value
	internal var readRequests                      = Set<ReadRequest>()

	/// requests of write characteristic value
	internal var writeRequests                     = Set<WriteRequest>()

	/// requests of subscribe characteristic value
	internal var subscribeRequests                 = Set<SubscribeRequest>()

	/// requests of unsubscribe characteristic value
	internal var unsubscribeRequests               = Set<UnsubscribeRequest>()

	/// requests of RSSI reading
	internal var RSSIRequests                      = Set<RSSIRequest>()

	internal var subscriptions = Set<Subscription>()

	open override var hash: Int {
		return core.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? Peripheral {
			return self.hashValue == other.hashValue
		}
		return false
	}

	deinit {
		dog("\(self) DESTROIED")
	}
}

// MARK: - CustomStringConvertible
extension Peripheral {

	open override var description: String {
		return core.description
	}
}

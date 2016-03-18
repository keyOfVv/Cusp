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

	case Disconnected
	case Connecting
	case Connected
//	@available(iOS 9.0, *)
//	case Disconnecting
	case Unknown	// this shall be "Disconnecting" in version 9.x
}

/// peripheral class for Cusp, shall be subclassed by custom peripheral class
@objc public class Peripheral: NSObject, CustomPeripheral {

	/// a retained reference to CBPeripheral object, read-only
	public private(set) var core: CBPeripheral {
		didSet {
			core.delegate = self
		}
	}

	required public init(core: CBPeripheral) {
		self.core = core
	}

	// MARK: Computed Properties

	/// name of peripheral
	public var name: String? {
		return core.name
	}

	/// state of peripheral
	public var state: PeripheralState {
		return PeripheralState(rawValue: core.state.rawValue) ?? .Disconnected
	}

	/// uuid of peripheral
	public var identifier: NSUUID {
		return core.identifier
	}

	/// operation concurrent queue for all operations including read, write, subscribe, unsubscribe, RSSI, etc.;
	internal let operationQ: dispatch_queue_t = dispatch_queue_create(CUSP_PERIPHERAL_Q_OPERATION_CONCURRENT, DISPATCH_QUEUE_CONCURRENT)

	/// request serial queue for all add/remove operation on all kinds of request;
	internal var requestQ: dispatch_queue_t = dispatch_queue_create(CUSP_PERIPHERAL_Q_REQUEST_SERIAL, DISPATCH_QUEUE_SERIAL)

	/// subscription serial queue for subscription operation;
	internal var subscriptionQ: dispatch_queue_t = dispatch_queue_create(CUSP_PERIPHERAL_Q_SUBSCRIPTION_SERIAL, DISPATCH_QUEUE_SERIAL)

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

	public override var hash: Int {
		return core.hashValue
	}

	public override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? Peripheral {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CustomStringConvertible
extension Peripheral {

	public override var description: String {
		return core.description
	}
}
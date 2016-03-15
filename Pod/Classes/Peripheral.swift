//
//  Peripheral.swift
//  Pods
//
//  Created by Ke Yang on 3/15/16.
//
//

import Foundation
import CoreBluetooth

/// session operation serial queue identifier
private let QIDOp = "com.keyang.cusp.peripheral.operationQ"

private let QIDReq = "com.keyang.cusp.peripheral.operationQ"

public enum PeripheralState : Int {

	case Disconnected
	case Connecting
	case Connected
//	@available(iOS 9.0, *)
//	case Disconnecting
	case Unknown	// this shall be "Disconnecting" in version 9.x
}


/// peripheral class for Cusp, shall be subclassed by custom peripheral class
public class Peripheral: NSObject {

	/// a retained reference to CBPeripheral object, read-only
	public private(set) var core: CBPeripheral {
		didSet {
			core.delegate = self
		}
	}

	init(core: CBPeripheral) {
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

	/// session operation serial queue
	internal let operationQ: dispatch_queue_t = dispatch_queue_create(QIDOp, DISPATCH_QUEUE_CONCURRENT)

	internal var requestQ: dispatch_queue_t = dispatch_queue_create(QIDReq, DISPATCH_QUEUE_SERIAL)

	/// requests of service discovering (发现服务请求的集合)
	internal var serviceDiscoveringRequests        = Set<ServiceDiscoveringRequest>()

	/// requests of characteristic discovering (发现特征请求的集合)
	internal var characteristicDiscoveringRequests = Set<CharacteristicDiscoveringRequest>()

	/// requests of read characteristic value (读值请求的集合)
	internal var readRequests                      = Set<ReadRequest>()

	/// requests of write characteristic value (写值请求的集合)
	internal var writeRequests                     = Set<WriteRequest>()

	/// requests of subscribe characteristic value (订阅请求的集合)
	internal var subscribeRequests                 = Set<SubscribeRequest>()

	/// requests of unsubscribe characteristic value (退订请求的集合)
	internal var unsubscribeRequests               = Set<UnsubscribeRequest>()

	/// requests of RSSI reading (信号强度查询请求的集合)
	internal var RSSIRequests                      = Set<RSSIRequest>()

	/// communicating session with connected peripheral (已建立的连接集合)
//	internal var sessions                          = Set<CommunicatingSession>()
}

// MARK: - CustomStringConvertible
extension Peripheral {

	public override var description: String {
		return core.description
	}
}
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
	public fileprivate(set) var core: CBPeripheral {
		didSet {
			core.delegate = self
		}
	}

	required public init(core: CBPeripheral) {
		self.core = core
	}

	// MARK: Stored Properties

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

	/// requests of descriptor discovering
	var descriptorDiscoveringRequests = Set<DescriptorDiscoveringRequest>()

	/// requests of read characteristic value
	internal var readRequests                      = Set<ReadRequest>()

	/// requests of read characteristic value
	var readDescriptorRequests            = Set<ReadDescriptorRequest>()

	/// requests of write characteristic value
	internal var writeRequests                     = Set<WriteRequest>()

	/// requests of write characteristic value
	internal var writeDescriptorRequests                     = Set<WriteDescriptorRequest>()

	/// requests of subscribe characteristic value
	internal var subscribeRequests                 = Set<SubscribeRequest>()

	/// requests of unsubscribe characteristic value
	internal var unsubscribeRequests               = Set<UnsubscribeRequest>()

	/// requests of RSSI reading
	internal var RSSIRequests                      = Set<RSSIRequest>()

	internal var subscriptions = Set<Subscription>()

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

// MARK: - Getter for services
extension Peripheral {

	/// services
	public var services: [Service]? {
		return core.services
	}

	/// get service object via subscription
	public subscript(serviceUUIDString: String) -> Service? {
		guard let servs = services else {
			return nil
		}
		for serv in servs {
			if serv.uuid.uuidString == serviceUUIDString.uppercased() {
				return serv
			}
		}
		return nil
	}

	/// get service object
	public func serviceWith(UUIDString: String) -> Service? {
		return self[UUIDString]
	}
}

// MARK: - Device Information
extension Peripheral {

	/**
	get Manufacturer Name String (GATT-2A29) value;

	- parameter completion: closure called after reading Manufacturer Name String completed, an nil string will be returned if there raised any error;
	*/
	public func getManufacturerNameString(completion: @escaping (String?) -> Void) {
		guard state == PeripheralState.connected else {
			dog("ERROR: Manufacturer Name String is available only after device is connected")
			completion(nil); return
		}
		discoverServices(UUIDStrings: [GATTService.DeviceInformation.rawValue], success: { (resp) in
			guard let service = self[GATTService.DeviceInformation.rawValue] else {
				dog("service \(GATTService.DeviceInformation.rawValue) not discovered")
				completion(nil); return
			}
			self.discoverCharacteristics(UUIDStrings: [GATTCharacteristic.ManufacturerNameString.rawValue], ofService: service, success: { (resp) in
				guard let char = service[GATTCharacteristic.ManufacturerNameString.rawValue] else {
					dog("char \(GATTCharacteristic.ManufacturerNameString.rawValue) of service \(GATTService.DeviceInformation.rawValue) not discovered")
					completion(nil); return
				}
				self.read(char, success: { (resp) in
					guard let data = resp?.value else {
						completion(nil); return
					}
					completion(String(data: data, encoding: String.Encoding.utf8))
				}, failure: { (error) in
					dog(error)
					completion(nil)
				})
			}, failure: { (error) in
				dog(error)
				completion(nil)
			})
		}) { (error) in
			dog(error)
			completion(nil)
		}
	}

	/**
	get Firmware Revision String (GATT-2A26) value;

	- parameter completion: closure called after reading Firmware Revision String completed, an nil string will be returned if there raised any error;
	*/
	public func getFirmwareRevisionString(completion: @escaping (String?) -> Void) {
		guard state == PeripheralState.connected else {
			dog("ERROR: Firmware Revision String is available only after device is connected")
			completion(nil); return
		}
		discoverServices(UUIDStrings: [GATTService.DeviceInformation.rawValue], success: { (resp) in
			guard let service = self[GATTService.DeviceInformation.rawValue] else {
				dog("service \(GATTService.DeviceInformation.rawValue) not discovered")
				completion(nil); return
			}
			self.discoverCharacteristics(UUIDStrings: [GATTCharacteristic.FirmwareRevisionString.rawValue], ofService: service, success: { (resp) in
				guard let char = service[GATTCharacteristic.FirmwareRevisionString.rawValue] else {
					dog("char \(GATTCharacteristic.FirmwareRevisionString.rawValue) of service \(GATTService.DeviceInformation.rawValue) not discovered")
					completion(nil); return
				}
				self.read(char, success: { (resp) in
					guard let data = resp?.value else {
						completion(nil); return
					}
					completion(String(data: data, encoding: String.Encoding.utf8))
				}, failure: { (error) in
					dog(error)
					completion(nil)
				})
			}, failure: { (error) in
				dog(error)
				completion(nil)
			})
		}) { (error) in
			dog(error)
			completion(nil)
		}
	}
}

// MARK: -
extension Service {

	/// get characteristic object via subscript
	public subscript(characteristicUUIDString: String) -> Characteristic? {
		guard let chars = characteristics else {
			return nil
		}
		for char in chars {
			if char.uuid.uuidString == characteristicUUIDString.uppercased() {
				return char
			}
		}
		return nil
	}

	/// get characteristic object
	public func characteristicWith(UUIDString: String) -> Characteristic? {
		return self[UUIDString]
	}
}

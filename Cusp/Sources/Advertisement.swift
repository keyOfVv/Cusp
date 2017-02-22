//
//  Advertisement.swift
//  Pods
//
//  Created by Ke Yang on 3/15/16.
//
//

import Foundation

// MARK: - AdvertisementInfo

/// advertisement info after scan.
open class Advertisement: NSObject {

	// MARK: Stored Properties

	/// peripheral
	open fileprivate(set) var peripheral: Peripheral!

	/// advertisement data dictionary
	public fileprivate(set) var advertisementData: Dictionary<String, Any>!

	/// is peripheral connectable or not
	open var isConnectable: Bool {
		return advertisementData["kCBAdvDataIsConnectable"] as? Bool ?? false
	}

	/// a UUID array contains advertising UUID of peripheral
	open var advertisingUUIDs: [UUID]? {
		return advertisementData["kCBAdvDataServiceUUIDs"] as? [UUID]
	}

	/// manufacturerData of peripheral
	open var manufacturerData: Data? {
		return advertisementData["kCBAdvDataManufacturerData"] as? Data
	}

	/// local name in advertisement data
	open var localName: String? {
		return advertisementData["kCBAdvDataLocalName"] as? String
	}

	/// a UUIDString array contains advertising UUIDStrig of peripheral
	open var advertisingUUIDStrings: [String] {
		return advertisingUUIDs?.map { $0.uuidString } ?? []
	}

	/// signal strength 信号强度
	open fileprivate(set) var RSSI: NSNumber!

	fileprivate override init() {
		super.init()
	}

	convenience init(peripheral: Peripheral, advertisementData: Dictionary<String, Any>, RSSI: NSNumber) {
		self.init()
		self.peripheral        = peripheral
		self.advertisementData = advertisementData
		self.RSSI              = RSSI
	}

	open override var hash: Int {
		return self.peripheral.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? Advertisement {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CustomStringConvertible
extension Advertisement {

	open override var description: String {
		return "\n{\n\t\(peripheral),\n\tadvertisingUUIDs = \(advertisingUUIDStrings),\n\tRSSI = \(RSSI)\n}"
	}
}

//
//  CuspCentralDelegate.swift
//  Cusp
//
//  Created by keyang on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - CBCentralManagerDelegate

extension Cusp: CBCentralManagerDelegate {

	/**
	REQUIRED: called each time the BLE-state of Central changes

	- parameter central: a CBCentralManager instance
	*/
	@available(*, unavailable, message="don't call this method directly")
	public func centralManagerDidUpdateState(central: CBCentralManager) {

	}

	/**
	OPTIONAL: called right after a Peripheral was discovered by Central

	- parameter central:           a CBCentralManager instance
	- parameter peripheral:        a CBPeripheral instance
	- parameter advertisementData: a dictionary contains base data advertised by discovered peripheral
	- parameter RSSI:              an NSNumber object representing the signal strength of discovered peripheral
	*/
	public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
//		log("DISCOVERED: \(peripheral)")
		// retained as discovered
		self.discoveredPeripherals.insert(peripheral)
//		self.availablePeripherals.insert(peripheral)
//		log("\(peripheral.services)")
//		log("\(advertisementData)")
		log("\(advertisementData["kCBAdvDataServiceUUIDs"])")  // <10,1,0x1390e5c90>,[0x1390e6300---2095579008]

		let array = advertisementData["kCBAdvDataServiceUUIDs"] as! NSMutableArray
		let object = array.firstObject as! CBUUID
		log("\(object.UUIDString)") // 1803

		if let uuid = self.advServiceUUID(advertisementData) {
			for req in self.scanRequests {
				if req.advertisingUUIDs == nil {
					req.available.insert(peripheral)
				} else if req.advertisingUUIDs?.contains(uuid) == true {
					req.available.insert(peripheral)
					break
				}
			}
		}
	}

	/**
	OPTIONAL: called right after a connection was established between a Peripheral and Central

	- parameter central:    a CBCentralManager instance
	- parameter peripheral: a CBPeripheral instance
	*/
	public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
		log("CONNECTED: \(peripheral)")
		dispatch_async(self.mainQ) { () -> Void in
			// find the target connect request ...
			var tgtReq: ConnectRequest?
			for req in self.connectRequests {
				if req.peripheral == peripheral {
					tgtReq = req
					break
				}
			}
			// target found, call its success closure, then remove it
			if let req = tgtReq {
				req.timedOut = false
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					req.success?(nil)
				})

				let session = CommunicatingSession(peripheral: peripheral)
				session.abruption = req.abruption
				peripheral.delegate = self
				self.sessions.insert(session)

				self.connectRequests.remove(req)
			}
		}
	}

	/**
	OPTIONAL: called when a Central-Peripheral connection attempt failed

	- parameter central:    a CBCentralManager instance
	- parameter peripheral: a CBPeripheral instance
	- parameter error:      error info
	*/
	public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		log("FAILED: \(peripheral)")
		dispatch_async(self.mainQ) { () -> Void in
			// released from interested
//			self.interestedPeripherals.remove(peripheral)
			// find the target connect request ...
			var tgtReq: ConnectRequest?
			for req in self.connectRequests {
				if req.peripheral == peripheral {
					tgtReq = req
					break
				}
			}
			// target found, call its failure closure, then remove it
			if let req = tgtReq {
				req.timedOut = false
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					req.failure?(error)
				})
				self.connectRequests.remove(req)
			}
		}
	}

	/**
	OPTIONAL: called right after a peripheral was disconnected from central

	- parameter central:    a CBCentralManager instance
	- parameter peripheral: a CBPeripheral instance
	- parameter error:      error info
	*/
	public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		log("DISCONNECTED: \(peripheral)")
		log("\(error)")
		dispatch_async(self.mainQ) { () -> Void in
			if let errorInfo = error {
				// abnormal disconnection, found out specific session
				if let session = self.sessionFor(peripheral) {
					dispatch_async(dispatch_get_main_queue(), {[weak session] () -> Void in
						log("%%%%%%%%%%%")
						session?.abruption?(errorInfo)
					})
				}

			} else {
				// normal disconnection
				// whether disconnect-active or cancel-pending?

				// disconnect-active
				var tgtDisReq: DisconnectRequest?
				for req in self.disconnectRequests {
					if req.peripheral == peripheral {
						tgtDisReq = req
						break
					}
				}
				if let req = tgtDisReq {
					// released from connected
//					self.interestedPeripherals.remove(peripheral)
					dispatch_async(dispatch_get_main_queue(), {[weak req] () -> Void in
						req?.completion?()
					})
					self.disconnectRequests.remove(req)
					return
				}

				// cancel-pending
				var tgtKclReq: CancelConnectRequest?
				for req in self.cancelConnectRequests {
					if req.peripheral == peripheral {
						tgtKclReq = req
						break
					}
				}
				if let req = tgtKclReq {
					// released from connecting
//					self.interestedPeripherals.remove(peripheral)
					dispatch_async(dispatch_get_main_queue(), {[weak req] () -> Void in
						req?.completion?()
					})
					self.cancelConnectRequests.remove(req)
					return
				}
			}
		}
	}
}

// MARK: - Privates

extension Cusp {

	private func advServiceUUID(data: [String: AnyObject]) -> UUID? {
		if let array = data["kCBAdvDataServiceUUIDs"] as? NSMutableArray {
			if let uuid = array.firstObject as? UUID {
				return uuid
			}
		}
		return nil
	}

}













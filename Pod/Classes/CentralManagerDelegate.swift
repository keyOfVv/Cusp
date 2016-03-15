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
		NSNotificationCenter.defaultCenter().postNotificationName(CuspStateDidChangeNotification, object: nil)	// post BLE state change notification
	}

	/**
	OPTIONAL: called right after a Peripheral was discovered by Central

	- parameter central:           a CBCentralManager instance
	- parameter peripheral:        a CBPeripheral instance
	- parameter advertisementData: a dictionary contains base data advertised by discovered peripheral
	- parameter RSSI:              an NSNumber object representing the signal strength of discovered peripheral
	*/
	public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
		dispatch_async(self.mainQ) { () -> Void in
			// 1. once discovered, wrap CBPeripheral into custom class...
			let p = Peripheral(core: peripheral)
			self.discoveredPeripherals.insert(p)
			// 2. then forge an advertisement object...
			let advInfo = Advertisement(peripheral: p, advertisementData: advertisementData, RSSI: RSSI)
			let uuids = advInfo.advertisingUUIDs
			// 3. finally, put it into Set "available" of scan req
			for req in self.scanRequests {
				if req.advertisingUUIDs == nil {	// a scan req for all peripherals
					req.available.insert(advInfo)	// put any peripheral into Set "available"
					break
				} else if req.advertisingUUIDs?.overlapsWith(uuids) == true {	// a scan req for specific peripheral(s)
					req.available.insert(advInfo)	// put specific peripheral into Set "available"
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
				if req.peripheral.core == peripheral {
					tgtReq = req
					break
				}
			}
			// req target found
			if let req = tgtReq {
				// 1.disable timeout call
				req.timedOut = false
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					// 2.call success closure
					req.success?(nil)
				})

				dispatch_async(self.sesQ, { () -> Void in
					// 3.find out specific peripheral
					if let p = self.peripheralFor(peripheral) {
						// 4.wrap peripheral into a session
						let session = PeripheralSession(peripheral: p)
						session.abruption = req.abruption
						self.sessions.insert(session)
					}
				})

				dispatch_async(self.reqQ, { () -> Void in
					// 5. remove req
					self.connectRequests.remove(req)
				})
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
			// find the target connect request ...
			var tgtReq: ConnectRequest?
			for req in self.connectRequests {
				if req.peripheral == peripheral {
					tgtReq = req
					break
				}
			}
			// req target found, call its failure closure, then remove it
			if let req = tgtReq {
				// 1. disable timeout call
				req.timedOut = false
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					// 2. call failure closure
					req.failure?(error)
				})
				dispatch_async(self.reqQ, { () -> Void in
					// 3. remove req
					self.connectRequests.remove(req)
				})
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
				// abnormal disconnection, find out specific Peripheral and session
				if let p = self.peripheralFor(peripheral) {
					if let session = self.sessionFor(p) {
						dispatch_async(dispatch_get_main_queue(), { () -> Void in
							// call abruption closure
							session.abruption?(errorInfo)
							})
						dispatch_async(self.sesQ, { () -> Void in
							// remove the abrupted session
							self.sessions.remove(session)
						})
					}
				}

			} else {
				// normal disconnection
				// whether disconnect-active or cancel-pending?

				// disconnect-active
				// find out specific disconnect req
				var tgtDisReq: DisconnectRequest?
				for req in self.disconnectRequests {
					if req.peripheral.core == peripheral {
						tgtDisReq = req
						break
					}
				}
				if let req = tgtDisReq {
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						// call completion closure
						req.completion?()
					})
					dispatch_async(self.reqQ, { () -> Void in
						// remove req
						self.disconnectRequests.remove(req)
					})
					if let p = self.peripheralFor(peripheral) {
						if let session = self.sessionFor(p) {
							dispatch_async(self.sesQ, { () -> Void in
								// remove the disconnected session
								self.sessions.remove(session)
							})
						}
					}
					return
				}

				// cancel-pending
				// find out specific cancel-connect req
				var tgtKclReq: CancelConnectRequest?
				for req in self.cancelConnectRequests {
					if req.peripheral.core == peripheral {
						tgtKclReq = req
						break
					}
				}
				if let req = tgtKclReq {
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						// call completion closure
						req.completion?()
					})
					dispatch_async(self.reqQ, { () -> Void in
						// remove req
						self.cancelConnectRequests.remove(req)
					})
					return
				}
			}
		}
	}
}

private extension Cusp {

	/**
	Retrieve Peripheral object for specific core from discoveredPeripherals.
	Note: this method is private

	- parameter core: CBPeripheral object

	- returns: Peripheral object or nil if not found
	*/
	private func peripheralFor(core: CBPeripheral) -> Peripheral? {
		for p in discoveredPeripherals {
			if p.core == core {
				return p
			}
		}
		return nil
	}
}

// MARK: -
extension SequenceType where Generator.Element : Equatable {

	private func includes(S: [Self.Generator.Element]) -> Bool {
		for element in S {
			if !self.contains(element) {
				return false
			}
		}
		return true
	}

	private func overlapsWith(S: [Self.Generator.Element]?) -> Bool {
		if S == nil {
			return false
		}
		for element in S! {
			if self.contains(element) {
				return true
			}
		}
		return false
	}
}













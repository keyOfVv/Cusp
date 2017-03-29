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

extension CuspCentral: CBCentralManagerDelegate {

	/**
	REQUIRED: called each time the BLE-state of Central changes

	- parameter central: a CBCentralManager instance
	*/
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		Foundation.NotificationCenter.default.post(name: Notification.Name.CuspStateDidChange, object: self) // post BLE state change notification
	}

	/**
	OPTIONAL: called right after a Peripheral was discovered by Central

	- parameter central:           a CBCentralManager instance
	- parameter peripheral:        a CBPeripheral instance
	- parameter advertisementData: a dictionary contains base data advertised by discovered peripheral
	- parameter RSSI:              an NSNumber object representing the signal strength of discovered peripheral
	*/
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		mainQ.async { () -> Void in
			if let p = self.peripheralFor(peripheral) {
				peripheral.delegate = p
				self.dealWithFoundPeripherals(p, advertisementData: advertisementData, RSSI: RSSI)
			} else {
				let p = Peripheral.init(core: peripheral)
				peripheral.delegate = p
				self.dealWithFoundPeripherals(p, advertisementData: advertisementData, RSSI: RSSI)
			}
		}
	}

	/**
	OPTIONAL: called right after a connection was established between a Peripheral and Central

	- parameter central:    a CBCentralManager instance
	- parameter peripheral: a CBPeripheral instance
	*/
	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		dog("CONNECTED: \(peripheral)")
		mainQ.async { () -> Void in
			// find matched connect request
			if let req = (self.connectReqs.first { $0.peripheral.core == peripheral }) {
				// 1.disable timeout call
				req.timedOut = false
				DispatchQueue.main.async(execute: { () -> Void in
					// 2.call success closure
					req.success?(nil)
				})

				self.sesQ.async(execute: { () -> Void in
					// 3.find out specific peripheral
					if let p = self.peripheralFor(peripheral) {
						// 4.wrap peripheral into a session
						let session = PeripheralSession(peripheral: p)
						session.abruption = req.abruption
						self.sessions.insert(session)
					}
				})

				self.reqQ.async(execute: { () -> Void in
					// 5. remove req
					self.connectReqs.remove(req)
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
	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		mainQ.async { () -> Void in
			// find matched connect request, call its failure closure, then remove it
			if let req = (self.connectReqs.first{ $0.peripheral.core == peripheral }) {
				// 1. disable timeout call
				req.timedOut = false
				DispatchQueue.main.async(execute: { () -> Void in
					dog("connect peripheral <\(String(describing: peripheral.name))> failed due to \(String(describing: error))")
					// 2. call failure closure
					req.failure?(CuspError(err: error))
				})
				self.reqQ.async(execute: { () -> Void in
					// 3. remove req
					self.connectReqs.remove(req)
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
	public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		mainQ.async { () -> Void in
			if let errorInfo = error {
				dog("connection to peripheral <\(String(describing: peripheral.name))> broke down abnoramlly due to \(errorInfo)")
				// abnormal disconnection, find out specific Peripheral and session
				if let p = self.peripheralFor(peripheral) {
					p.subscriptions.removeAll()	// remove all subscriptions
					if let session = self[p] {
						DispatchQueue.main.async(execute: { () -> Void in
							// call abruption closure
							session.abruption?(CuspError(err: errorInfo))
							})
						self.sesQ.async(execute: { () -> Void in
							// remove the abrupted session
							self.sessions.remove(session)
							dog("removed session of \(peripheral))")
						})
					}
				}

			} else {
				// normal disconnection
				// whether disconnect-active or cancel-pending?

				// disconnect-active
				// find out specific disconnect req
				if let req = (self.disconnectReqs.first { $0.peripheral.core == peripheral }) {
					DispatchQueue.main.async(execute: { () -> Void in
						// call completion closure
						req.completion?()
					})
					self.reqQ.async(execute: { () -> Void in
						// remove req
						self.disconnectReqs.remove(req)
					})
					if let p = self.peripheralFor(peripheral) {
						if let session = self[p] {
							self.sesQ.async(execute: { () -> Void in
								// remove the disconnected session
								self.sessions.remove(session)
							})
						}
					}
					return
				}

				// cancel-pending
				// find out specific cancel-connect req
				if let req = (self.cancelConnectReqs.first { $0.peripheral.core == peripheral }) {
					DispatchQueue.main.async(execute: { () -> Void in
						// call completion closure
						req.completion?()
					})
					self.reqQ.async(execute: { () -> Void in
						// remove req
						self.cancelConnectReqs.remove(req)
					})
					return
				}
			}
		}
	}

	public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
		dog(dict)
	}
}

extension CuspCentral {

	/**
	Retrieve Peripheral object for specific core from discoveredPeripherals.
	Note: this method is private

	- parameter core: CBPeripheral object

	- returns: Peripheral object or nil if not found
	*/
	func peripheralFor(_ core: CBPeripheral) -> Peripheral? {
		return availables.first { $0.core == core }
	}

	/**
	private method deal with ble devices and their ad info

	- parameter peripheral:        instance of Peripheral class
	- parameter advertisementData: advertisement info
	- parameter RSSI:              RSSI
	*/
	func dealWithFoundPeripherals(_ peripheral: Peripheral, advertisementData: [String : Any], RSSI: NSNumber) {
		availables.insert(peripheral)
		// 2. then forge an advertisement object...
		let advInfo = Advertisement(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI)
		let uuids = advInfo.advertisingUUIDs
		// 3. finally, put it into Set "available" of scan req
		for req in scanReqs {
			if let adUuids = req.advertisingUUIDs {	// if specific req has intended advertising uuids...
				if adUuids.overlapsWith(uuids) {	// and these intended advertising uuids overlaps with those that are advertising...
					req.available.insert(advInfo)	// then put specific peripheral into Set "available"
				}
			} else {	// if specific req has no intended advertising uuids...
				req.available.insert(advInfo)	// then put any peripheral into Set "available"
				break
			}
		}
	}

	func coreCatched(_ core: CBPeripheral) -> Bool {
		return availables.first { $0.core == core } != nil
	}
}

private extension CBPeripheral {

	func matches(_ pattern: String) -> Bool {
		do {
			let name = self.name ?? ""
			let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
			if let result = regex.firstMatch(in: name, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, name.characters.count)) {
				if result.range.location != NSNotFound {
					return true
				}
			}
		} catch {

		}
		return false
	}
}

// MARK: -
extension Sequence where Iterator.Element : Equatable {

	fileprivate func includes(_ S: [Self.Iterator.Element]) -> Bool {
		for element in S {
			if !self.contains(element) {
				return false
			}
		}
		return true
	}

	fileprivate func overlapsWith(_ S: [Self.Iterator.Element]?) -> Bool {
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













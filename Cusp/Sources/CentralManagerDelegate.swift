//
//  CuspCentralDelegate.swift
//  Cusp
//
//  Created by keyang on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation
import KEYExtension
import CoreBluetooth

// MARK: - CBCentralManagerDelegate

extension Cusp: CBCentralManagerDelegate {

	/**
	REQUIRED: called each time the BLE-state of Central changes

	- parameter central: a CBCentralManager instance
	*/
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		Foundation.NotificationCenter.default.post(name: Notification.Name(rawValue: CuspStateDidChangeNotification), object: nil)	// post BLE state change notification
	}

	/**
	OPTIONAL: called right after a Peripheral was discovered by Central

	- parameter central:           a CBCentralManager instance
	- parameter peripheral:        a CBPeripheral instance
	- parameter advertisementData: a dictionary contains base data advertised by discovered peripheral
	- parameter RSSI:              an NSNumber object representing the signal strength of discovered peripheral
	*/
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		dog(peripheral)
		self.mainQ.async { () -> Void in
			// 0. check if any custom peripheral class registered
			if !self.customClasses.isEmpty {
				// custom peripheral class exists
				// 1. once discovered, wrap CBPeripheral into custom class...
				for (regex, aClass) in self.customClasses {
					if peripheral.matches(regex) {
						if let classRef = aClass.self as? Peripheral.Type {
							// 1. check if core catched
							if let p = self.peripheralFor(peripheral) {
								peripheral.delegate = p
								self.dealWithFoundPeripherals(p, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI)
							} else {
								// 2. uncatched, then catch it!
								let p = classRef.init(core: peripheral)
								peripheral.delegate = p
								self.dealWithFoundPeripherals(p, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI)
							}
						}
					}
				}
			} else {
				// no custom peripheral class
				// 1. check if core catched
				if let p = self.peripheralFor(peripheral) {
					peripheral.delegate = p
					self.dealWithFoundPeripherals(p, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI)
				} else {
					let p = Peripheral.init(core: peripheral)
					peripheral.delegate = p
					self.dealWithFoundPeripherals(p, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI)
				}
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
		self.mainQ.async { () -> Void in
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
	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		dog("FAILED: \(peripheral)")
		self.mainQ.async { () -> Void in
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
				DispatchQueue.main.async(execute: { () -> Void in
					// 2. call failure closure
					req.failure?(error)
				})
				self.reqQ.async(execute: { () -> Void in
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
	public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		dog("DISCONNECTED: \(peripheral)")
		dog("\(error)")
		self.mainQ.async { () -> Void in
			if let errorInfo = error {
				// abnormal disconnection, find out specific Peripheral and session
				if let p = self.peripheralFor(peripheral) {
					p.subscriptions.removeAll()	// remove all subscriptions
					if let session = self.sessionFor(p) {
						DispatchQueue.main.async(execute: { () -> Void in
							// call abruption closure
							session.abruption?(errorInfo)
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
				var tgtDisReq: DisconnectRequest?
				for req in self.disconnectRequests {
					if req.peripheral.core == peripheral {
						tgtDisReq = req
						break
					}
				}
				if let req = tgtDisReq {
					DispatchQueue.main.async(execute: { () -> Void in
						// call completion closure
						req.completion?()
					})
					self.reqQ.async(execute: { () -> Void in
						// remove req
						self.disconnectRequests.remove(req)
					})
					if let p = self.peripheralFor(peripheral) {
						if let session = self.sessionFor(p) {
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
				var tgtKclReq: CancelConnectRequest?
				for req in self.cancelConnectRequests {
					if req.peripheral.core == peripheral {
						tgtKclReq = req
						break
					}
				}
				if let req = tgtKclReq {
					DispatchQueue.main.async(execute: { () -> Void in
						// call completion closure
						req.completion?()
					})
					self.reqQ.async(execute: { () -> Void in
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
	func peripheralFor(_ core: CBPeripheral) -> Peripheral? {
		dog("seach for peripheral in \(self.availables) of \(self)")
		for p in availables {
			if p.core == core {
				return p
			}
		}
		return nil
	}

	/**
	private method deal with ble devices and their ad info

	- parameter peripheral:        instance of Peripheral class
	- parameter advertisementData: advertisement info
	- parameter RSSI:              RSSI
	*/
	func dealWithFoundPeripherals(_ peripheral: Peripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
		self.availables.insert(peripheral)
		dog("added peripheral in \(self.availables) of \(self)")
		// 2. then forge an advertisement object...
		let advInfo = Advertisement(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI)
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

	func coreCatched(_ core: CBPeripheral) -> Bool {
		for p in self.availables {
			if p.core == core {
				return true
			}
		}
		return false
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












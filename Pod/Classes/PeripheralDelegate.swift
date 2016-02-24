//
//  CuspPeripheralDelegate.swift
//  Cusp
//
//  Created by keyOfVv on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - CBPeripheralDelegate

extension Cusp: CBPeripheralDelegate {

	/*!
	*  @method peripheral:didDiscoverServices:
	*
	*  @param peripheral	The peripheral providing this information.
	*  @param error			If an error occurred, the cause of the failure.
	*
	*  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
	*						<i>peripheral</i>'s @link services @/link property.
	*
	*/
	public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
		if let session = self.sessionFor(peripheral) {
			dispatch_async(session.sessionQ) { () -> Void in
				var tgtReq: ServiceDiscoveringRequest?
				for req in self.serviceDiscoveringRequests {
					if req.peripheral == peripheral {
						tgtReq = req
						break
					}
				}
				if let req = tgtReq {
					req.timedOut = false
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						if let errorInfo = error {
							// discovering failed
							req.failure?(errorInfo)
						} else {
							// discovering succeed
							req.success?(nil)
						}
					})
					dispatch_barrier_async(session.sessionQ, { () -> Void in
						self.serviceDiscoveringRequests.remove(req)
					})
				}
			}
		}
	}

	/*!
	*  @method peripheral:didDiscoverCharacteristicsForService:error:
	*
	*  @param peripheral	The peripheral providing this information.
	*  @param service		The <code>CBService</code> object containing the characteristic(s).
	*  @param error			If an error occurred, the cause of the failure.
	*
	*  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
	*						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
	*/
	public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
		if let session = self.sessionFor(peripheral) {
			dispatch_async(session.sessionQ) { () -> Void in
				var tgtReq: CharacteristicDiscoveringRequest?
				for req in self.characteristicDiscoveringRequests {
					if req.peripheral == peripheral {
						tgtReq = req
						break
					}
				}
				if let req = tgtReq {
					req.timedOut = false
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						if let errorInfo = error {
							// discovering failed
							req.failure?(errorInfo)
						} else {
							// discovering succeed
							req.success?(nil)
						}
					})
					dispatch_barrier_async(session.sessionQ, { () -> Void in
						self.characteristicDiscoveringRequests.remove(req)
					})
				}
			}
		}
	}

	/*!
	*  @method peripheral:didUpdateValueForCharacteristic:error:
	*
	*  @param peripheral		The peripheral providing this information.
	*  @param characteristic	A <code>CBCharacteristic</code> object.
	*	@param error			If an error occurred, the cause of the failure.
	*
	*  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
	*/
	public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
		// found out whether value is read or subscirbed
		if let session = self.sessionFor(peripheral) {
			dispatch_async(session.sessionQ, { () -> Void in
				var tgtReq: ReadRequest?
				for req in self.readRequests {
					if req.peripheral == peripheral {
						tgtReq = req
						break
					}
				}
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					if let req = tgtReq {
						req.timedOut = false
						// read
						if let errorInfo = error {
							// failed
							req.failure?(errorInfo)
						} else {
							// succeed
							let resp = Response()
							resp.value = characteristic.value
							req.success?(resp)
						}
						dispatch_barrier_async(session.sessionQ, { () -> Void in
							self.readRequests.remove(req)
						})
					} else {
						// subscribed
						session.update?(characteristic.value)
					}
				})
			})
		}
	}

	/*!
	*  @method peripheral:didWriteValueForCharacteristic:error:
	*
	*  @param peripheral		The peripheral providing this information.
	*  @param characteristic	A <code>CBCharacteristic</code> object.
	*	@param error			If an error occurred, the cause of the failure.
	*
	*  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
	*/
	public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
		if let session = self.sessionFor(peripheral) {
			dispatch_async(session.sessionQ, { () -> Void in
				var tgtReq: WriteRequest?
				for req in self.writeRequests {
					if req.peripheral == peripheral {
						tgtReq = req
						break
					}
				}
				if let req = tgtReq {
					req.timedOut = false
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						if let errorInfo = error {
							// write failed
							req.failure?(errorInfo)
						} else {
							// write succeed
							req.success?(nil)
						}
					})
					dispatch_barrier_async(session.sessionQ, { () -> Void in
						self.writeRequests.remove(req)
					})
				}
			})
		}
	}

	/*!
	*  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
	*
	*  @param peripheral		The peripheral providing this information.
	*  @param characteristic	A <code>CBCharacteristic</code> object.
	*	@param error			If an error occurred, the cause of the failure.
	*
	*  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
	*/
	public func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
		if let session = self.sessionFor(peripheral) {
			dispatch_async(session.sessionQ, { () -> Void in
				var tgtReq: SubscribeRequest?
				for req in self.subscribeRequests {
					if req.peripheral == peripheral {
						tgtReq = req
						break
					}
				}
				if let req = tgtReq {
					req.timedOut = false
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						if let errorInfo = error {
							// subscribe failed
							req.failure?(errorInfo)
						} else {
							// subscribe succeed
							req.success?(nil)
							session.update = req.update
						}
					})
					dispatch_barrier_async(session.sessionQ, { () -> Void in
						self.subscribeRequests.remove(req)
					})
				} else {
					var tgtReq: UnsubscribeRequest?
					for req in self.unsubscribeRequests {
						if req.peripheral == peripheral {
							tgtReq = req
							break
						}
					}
					if let req = tgtReq {
						req.timedOut = false
						dispatch_async(dispatch_get_main_queue(), { () -> Void in
							if let errorInfo = error {
								// unsubscribe failed
								req.failure?(errorInfo)
							} else {
								// unsubscribe succeed
								req.success?(nil)
							}
						})
						dispatch_barrier_async(session.sessionQ, { () -> Void in
							self.unsubscribeRequests.remove(req)
						})
					}
				}
			})
		}
	}

	// TODO: 8.0+ only
	public func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
		if let session = self.sessionFor(peripheral) {
			dispatch_async(session.sessionQ, { () -> Void in
				var tgtReq: RSSIRequest?
				for req in self.RSSIRequests {
					if req.peripheral == peripheral {
						tgtReq = req
						break
					}
				}
				if let req = tgtReq {
					req.timedOut = false
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						if let errorInfo = error {
							// write failed
							req.failure?(errorInfo)
						} else {
							// write succeed
							let resp = Response()
							resp.RSSI = RSSI
							req.success?(resp)
						}
					})
					self.RSSIRequests.remove(req)
				}
			})
		}
	}

	internal func sessionFor(peripheral: CBPeripheral?) -> CommunicatingSession? {
		if peripheral == nil { return nil }

		for session in self.sessions {
			if session.peripheral == peripheral {
				return session
			}
		}

		return nil
	}
}
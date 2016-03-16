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

extension Peripheral: CBPeripheralDelegate {

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
		dispatch_async(self.operationQ) { () -> Void in
			// multiple reqs of discovering service within a short duration will be responsed simultaneously
			// 1. check if service UUID specified in req...
			for req in self.serviceDiscoveringRequests {
				if let uuids = req.serviceUUIDs {
					// if so, check if all interested services are discovered, otherwise return directly
					if !self.areServicesAvailable(uuids: uuids) {
						return
					}
				}
			}
			// 2. all interested services are discovered, OR in case no service UUID specified in req...
			for req in self.serviceDiscoveringRequests {
				req.timedOut = false
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					if let errorInfo = error {
						// discovering failed
						req.failure?(errorInfo)
					} else {
						// discovering succeed, call success closure of each req
						req.success?(nil)
					}
				})
				// 4. once the success/failure closure called, remove the req
				dispatch_async(self.requestQ, { () -> Void in
					self.serviceDiscoveringRequests.remove(req)
				})
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
		dispatch_async(self.operationQ) { () -> Void in
			// multiple reqs of discovering characteristic within a short duration will be responsed simultaneously
			// 1. check if characteristic UUID specified in req...
			for req in self.characteristicDiscoveringRequests {
				if let uuids = req.characteristicUUIDs {
					// if so, check if all interested characteristics are discovered, otherwise return directly
					if !self.areCharacteristicsAvailable(uuids: uuids) {
						return
					}
				}
			}
			// 2. all interested characteristics are discovered, OR in case no characteristic UUID specified in req...
			for req in self.characteristicDiscoveringRequests {
				req.timedOut = false
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					if let errorInfo = error {
						// discovering failed
						req.failure?(errorInfo)
					} else {
						// discovering succeed, call success closure of each req
						req.success?(nil)
					}
				})
				// 4. once the success/failure closure called, remove the req
				dispatch_async(self.requestQ, { () -> Void in
					self.characteristicDiscoveringRequests.remove(req)
				})
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

		dispatch_async(self.operationQ, { () -> Void in
			var tgtReq: ReadRequest?
			for req in self.readRequests {
				if req.characteristic == characteristic {
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
					dispatch_async(self.requestQ, { () -> Void in
						self.readRequests.remove(req)
					})
				} else {
					// subscribed
					// TODO: deal with value updates
					//						session.update?(characteristic.value)
				}
			})
		})
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

		dispatch_async(self.operationQ, { () -> Void in
			var tgtReq: WriteRequest?
			for req in self.writeRequests {
				if req.characteristic == characteristic {
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
				dispatch_async(self.requestQ, { () -> Void in
					self.writeRequests.remove(req)
				})
			}
		})
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
		dispatch_async(self.operationQ, { () -> Void in
			var tgtReq: SubscribeRequest?
			for req in self.subscribeRequests {
				if req.characteristic == characteristic {
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
						// TODO: deal with value updates
//						session.update = req.update
					}
				})
				dispatch_async(self.requestQ, { () -> Void in
					self.subscribeRequests.remove(req)
				})
			} else {
				var tgtReq: UnsubscribeRequest?
				for req in self.unsubscribeRequests {
					if req.characteristic == characteristic {
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
					dispatch_async(self.requestQ, { () -> Void in
						self.unsubscribeRequests.remove(req)
					})
				}
			}
		})
	}

	// TODO: 8.0+ only
	public func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
		dispatch_async(self.operationQ, { () -> Void in
			for req in self.RSSIRequests {
				req.timedOut = false
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					if let errorInfo = error {
						// read RSSI failed
						req.failure?(errorInfo)
					} else {
						// read RSSI succeed
						let resp = Response()
						resp.RSSI = RSSI
						req.success?(resp)
					}
				})
				dispatch_async(self.requestQ, { () -> Void in
					self.RSSIRequests.remove(req)
				})
			}
		})
	}
}
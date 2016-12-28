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
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		self.operationQ.async { () -> Void in
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
				DispatchQueue.main.async(execute: { () -> Void in
					if let errorInfo = error {
						// discovering failed
						req.failure?(CuspError.unknown)
					} else {
						// discovering succeed, call success closure of each req
						req.success?(nil)
					}
				})
				// 4. once the success/failure closure called, remove the req
				self.requestQ.async(execute: { () -> Void in
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
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		self.operationQ.async { () -> Void in
			// multiple reqs of discovering characteristic within a short duration will be responsed simultaneously
			// 1. check if characteristic UUID specified in req...
			for req in self.characteristicDiscoveringRequests {
				if let uuids = req.characteristicUUIDs {
					// if so, check if all interested characteristics are discovered, otherwise return directly
					if !self.areCharacteristicsAvailable(uuids: uuids, forService: service) {
						return
					}
				}
			}
			// 2. all interested characteristics are discovered, OR in case no characteristic UUID specified in char-discove-req...
			for req in self.characteristicDiscoveringRequests {
				req.timedOut = false
				DispatchQueue.main.async(execute: { () -> Void in
					if let _ = error {
						// discovering failed
						req.failure?(CuspError.unknown)
					} else {
						// discovering succeed, call success closure of each req
						req.success?(nil)
					}
				})
				// 4. once the success/failure closure called, remove the req
				self.requestQ.async(execute: { () -> Void in
					self.characteristicDiscoveringRequests.remove(req)
				})
			}
		}
	}

	public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
		operationQ.sync {
			var targetReq: DescriptorDiscoveringRequest?
			for req in self.descriptorDiscoveringRequests {
				if req.characteristic == characteristic {
					targetReq = req
					break
				}
			}
			guard let req = targetReq else { return }
			req.timedOut = false
			DispatchQueue.main.async(execute: { () -> Void in
				if let _ = error {
					// discovering failed
					dog("discover descriptor for char \(characteristic.uuid.uuidString) failed due to \(error)")
					req.failure?(CuspError.unknown)
				} else {
					// discovering succeed, call success closure of each req
					dog("discover descriptor for char \(characteristic.uuid.uuidString) succeed")
					req.success?(nil)
				}
			})
			// 4. once the success/failure closure called, remove the req
			self.requestQ.async(execute: { () -> Void in
				self.descriptorDiscoveringRequests.remove(req)
			})
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
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		// this method is invoked after readValueForCharacteristic call or subscription...
		// so it's necessary to find out whether value is read or subscirbed...
		// if subscribed, then ignore read req
		operationQ.async { () -> Void in
			if characteristic.isNotifying {
				// subscription update
				// find out specific subscription
				for sub in self.subscriptions {
					if sub.characteristic == characteristic {
						// prepare to call update call back
						DispatchQueue.main.async(execute: { () -> Void in
							if error == nil {
								let resp = Response()
								resp.value = characteristic.value	// wrap value
								sub.update?(resp)
							}
						})
						return
					}
				}
			} else {
				// may invoked by value reading req
				// find out specific req
				for req in self.readRequests {
					if req.characteristic == characteristic {
						// prepare to call back
						DispatchQueue.main.async(execute: { () -> Void in
							// disable timeout closure
							req.timedOut = false
							if let err = error {
								// read value failed
								req.failure?(CuspError.unknown)
							} else {
								// read value succeed
								let resp = Response()
								resp.value = characteristic.value	// wrap value
								req.success?(resp)
							}
						})
						return
					}
				}
			}
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
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

		self.operationQ.async(execute: { () -> Void in
			var tgtReq: WriteRequest?
			for req in self.writeRequests {
				if req.characteristic == characteristic {
					tgtReq = req
					break
				}
			}
			if let req = tgtReq {
				req.timedOut = false
				DispatchQueue.main.async(execute: { () -> Void in
					if let errorInfo = error {
						// write failed
						req.failure?(CuspError.unknown)
					} else {
						// write succeed
						req.success?(nil)
					}
				})
				self.requestQ.async(execute: { () -> Void in
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
	public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		self.operationQ.sync {
			switch characteristic.isNotifying {
			case true:
				var tgtReq: SubscribeRequest?
				for req in self.subscribeRequests {
					if req.characteristic == characteristic {
						tgtReq = req
						break
					}
				}
				if let req = tgtReq {
					req.timedOut = false
					DispatchQueue.main.async(execute: { () -> Void in
						if let errorInfo = error {
							// subscribe failed
							req.failure?(CuspError.unknown)
						} else {
							// subscribe succeed
							req.success?(nil)
							self.subscriptionQ.async(execute: { () -> Void in
								// create subscription object
								let subscription = Subscription(characteristic: characteristic, update: req.update)
								self.subscriptions.insert(subscription)
							})
						}
					})
					self.requestQ.async(execute: { () -> Void in
						self.subscribeRequests.remove(req)
					})
				}
				break
			case false:
				var tgtReq: UnsubscribeRequest?
				for req in self.unsubscribeRequests {
					if req.characteristic == characteristic {
						tgtReq = req
						break
					}
				}
				if let req = tgtReq {
					req.timedOut = false
					DispatchQueue.main.async(execute: { () -> Void in
						if let errorInfo = error {
							// unsubscribe failed
							req.failure?(CuspError.unknown)
						} else {
							// unsubscribe succeed
							req.success?(nil)
							self.subscriptionQ.async(execute: { () -> Void in
								var tgtSub: Subscription?
								for sub in self.subscriptions {
									if sub.characteristic == characteristic {
										tgtSub = sub
										break
									}
								}
								if let sub = tgtSub {
									self.subscriptions.remove(sub)
								}
							})
						}
					})
					self.requestQ.async(execute: { () -> Void in
						self.unsubscribeRequests.remove(req)
					})
					break
				}
			}
		}
	}

	// TODO: 8.0+ only
	public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
		self.operationQ.async(execute: { () -> Void in
			for req in self.RSSIRequests {
				req.timedOut = false
				DispatchQueue.main.async(execute: { () -> Void in
					if let errorInfo = error {
						// read RSSI failed
						req.failure?(CuspError.unknown)
					} else {
						// read RSSI succeed
						let resp = Response()
						resp.RSSI = RSSI
						req.success?(resp)
					}
				})
				self.requestQ.async(execute: { () -> Void in
					self.RSSIRequests.remove(req)
				})
			}
		})
	}
}

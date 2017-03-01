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
						dog("dicovering services failed due to \(errorInfo)")
						// discovering failed
						req.failure?(CuspError(err: errorInfo))
					} else {
						// discovering succeed, call success closure of each req
						req.success?(nil)
					}
				})
			}
			// 4. once the success/failure closure called, remove the req
			self.requestQ.async(execute: { () -> Void in
				self.serviceDiscoveringRequests.filter { !$0.timedOut }.forEach { self.serviceDiscoveringRequests.remove($0) }
			})
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
					if let errorInfo = error {
						dog("discovering characteristics of service <\(service.uuid.uuidString)> failed due to \(errorInfo)")
						// discovering failed
						req.failure?(CuspError(err: errorInfo))
					} else {
						// discovering succeed, call success closure of each req
						req.success?(nil)
					}
				})
			}
			// 4. once the success/failure closure called, remove the req
			self.requestQ.async(execute: { () -> Void in
				self.characteristicDiscoveringRequests.filter { !$0.timedOut }.forEach { self.characteristicDiscoveringRequests.remove($0) }
			})
		}
	}

	public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
		operationQ.sync {
			guard let req = (self.descriptorDiscoveringRequests.first { $0.characteristic == characteristic }) else {
				fatalError("Peripheral received didDiscoverDescriptors callback has no matched descriptorDiscoveringRequest")
			}
			req.timedOut = false
			DispatchQueue.main.async(execute: { () -> Void in
				if let errorInfo = error {
					// discovering failed
					dog("discover descriptors for char \(characteristic.uuid.uuidString) failed due to \(errorInfo)")
					req.failure?(CuspError(err: errorInfo))
				} else {
					// discovering succeed, call success closure of each req
					dog("discover descriptors for char \(characteristic.uuid.uuidString) succeed")
					req.success?(nil)
				}
			})
			// 4. once the success/failure closure called, remove the req
			self.requestQ.async(execute: { () -> Void in
				self.descriptorDiscoveringRequests.remove(req)
			})
		}
	}

	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
		operationQ.sync {
			guard let req = (self.readDescriptorRequests.first { $0.descriptor == descriptor }) else {
				fatalError("Peripheral received didUpdateValueForDescriptor callback has no matched readDescriptorRequest")
			}
			req.timedOut = false
			DispatchQueue.main.async(execute: { () -> Void in
				if let errorInfo = error {
					// read failed
					dog("read descriptor \(descriptor.uuid.uuidString) failed due to \(errorInfo)")
					req.failure?(CuspError(err: errorInfo))
				} else {
					// read succeed, call success closure of each req
					dog("read descriptor \(descriptor.uuid.uuidString) succeed")
					req.success?(nil)
				}
			})
			// 4. once the success/failure closure called, remove the req
			self.requestQ.async(execute: { () -> Void in
				self.readDescriptorRequests.remove(req)
			})
		}
	}

	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
		operationQ.sync {
			guard let req = (self.writeDescriptorRequests.first { $0.descriptor == descriptor }) else {
				fatalError("Peripheral received didWriteValueForDescriptor callback has no matched writeDescriptorRequest")
			}
			req.timedOut = false
			DispatchQueue.main.async(execute: { () -> Void in
				if let errorInfo = error {
					// read failed
					dog("write descriptor for descriptor \(descriptor.uuid.uuidString) failed due to \(errorInfo)")
					req.failure?(CuspError(err: errorInfo))
				} else {
					// read succeed, call success closure of each req
					dog("write descriptor for descriptor \(descriptor.uuid.uuidString) succeed")
					req.success?(nil)
				}
			})
			// 4. once the success/failure closure called, remove the req
			self.requestQ.async(execute: { () -> Void in
				self.writeDescriptorRequests.remove(req)
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
				guard let sub = (self.subscriptions.first { $0.characteristic == characteristic }) else {
					fatalError("Peripheral received value update via notification(s) is not referenced by subscriptions set")
				}
				// prepare to call update call back
				if let errorInfo = error {
					dog("updating value for char <\(characteristic.uuid.uuidString)> failed due to \(errorInfo)")
					dog(errorInfo)
				} else {
					let resp = Response()
					resp.value = characteristic.value	// wrap value
					DispatchQueue.main.async(execute: { () -> Void in
						sub.update?(resp)
					})
				}
			} else {
				// may invoked by value reading req
				// find out specific req
				guard let req = (self.readRequests.first { $0.characteristic == characteristic }) else {
					fatalError("Peripheral received value update via read operation(s) is not referenced by subscriptions set")
				}
				// prepare to call back
				DispatchQueue.main.async(execute: { () -> Void in
					// disable timeout closure
					req.timedOut = false
					if let errorInfo = error {
						dog("read value for char <\(characteristic.uuid.uuidString)> failed due to \(errorInfo)")
						// read value failed
						req.failure?(CuspError(err: errorInfo))
					} else {
						// read value succeed
						let resp = Response()
						resp.value = characteristic.value	// wrap value
						req.success?(resp)
					}
				})
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
			guard let req = (self.writeRequests.first { $0.characteristic == characteristic }) else {
				fatalError("Peripheral received didWriteValueForCharacteristic callback has no matched writeRequest")
			}
			req.timedOut = false
			DispatchQueue.main.async(execute: { () -> Void in
				if let errorInfo = error {
					dog("write value for <\(characteristic.uuid.uuidString)> failed due to \(errorInfo)")
					// write failed
					req.failure?(CuspError(err: errorInfo))
				} else {
					// write succeed
					req.success?(nil)
				}
			})
			self.requestQ.async(execute: { () -> Void in
				self.writeRequests.remove(req)
			})
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
				guard let req = (self.subscribeRequests.first { $0.characteristic == characteristic }) else {
					fatalError("Peripheral received didUpdateNotificationStateForCharacteristic callback has no matched subscribeRequest")
				}
				req.timedOut = false
				DispatchQueue.main.async(execute: { () -> Void in
					if let errorInfo = error {
						dog("subscribe char <\(characteristic.uuid.uuidString)> failed due to \(errorInfo)")
						// subscribe failed
						req.failure?(CuspError(err: errorInfo))
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

			case false:
				guard let req = (self.unsubscribeRequests.first { $0.characteristic == characteristic }) else {
					fatalError("Peripheral received didUpdateNotificationStateForCharacteristic callback has no matched unsubscribeRequest")
				}
				req.timedOut = false
				DispatchQueue.main.async(execute: { () -> Void in
					if let errorInfo = error {
						dog("unsubscribe char <\(characteristic.uuid.uuidString)> failed due to \(errorInfo)")
						// unsubscribe failed
						req.failure?(CuspError(err: errorInfo))
					} else {
						// unsubscribe succeed
						req.success?(nil)
						// remove subscription
						self.subscriptionQ.async(execute: { () -> Void in
							guard let sub = (self.subscriptions.first { $0.characteristic == characteristic }) else {
								fatalError("Peripheral unsubscribed has no matched subscription")
							}
							self.subscriptions.remove(sub)
						})
					}
				})
				self.requestQ.async(execute: { () -> Void in
					self.unsubscribeRequests.remove(req)
				})
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
						dog("read RSSI failed due to \(errorInfo)")
						// read RSSI failed
						req.failure?(CuspError(err: errorInfo))
					} else {
						// read RSSI succeed
						let resp = Response()
						resp.RSSI = RSSI
						req.success?(resp)
					}
				})
			}
			self.requestQ.async {
				self.RSSIRequests.filter { !$0.timedOut }.forEach { self.RSSIRequests.remove($0) }
			}
		})
	}
}

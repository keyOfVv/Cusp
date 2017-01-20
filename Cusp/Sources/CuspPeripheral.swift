//
//  CuspPeripheral.swift
//  Cusp
//
//  Created by Ke Yang on 16/01/2017.
//  Copyright © 2017 com.keyofvv. All rights reserved.
//

import UIKit
import CoreBluetooth

private let CUSP_PERIPHERAL_Q_MAIN_CONCURRENT = "com.keyang.cusp.central_Q_main_concurrent"

class CuspPeripheral: NSObject {

	lazy var peripheralManager: CBPeripheralManager = {
		return CBPeripheralManager(delegate: self, queue: self.mainQ, options: nil)
	}()

	let mainQ: DispatchQueue = DispatchQueue(label: CUSP_PERIPHERAL_Q_MAIN_CONCURRENT, attributes: DispatchQueue.Attributes.concurrent)

}

// MARK: -
extension CuspPeripheral: CBPeripheralManagerDelegate {

	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {

	}
}

//
//  Peripheral.swift
//  Pods
//
//  Created by Ke Yang on 3/15/16.
//
//

import Foundation
import CoreBluetooth

public class Peripheral: NSObject {
	public var core: CBPeripheral

	init(core: CBPeripheral) {
		self.core = core
	}
}
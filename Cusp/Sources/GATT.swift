//
//  GATT.swift
//  Cusp
//
//  Created by Ke Yang on 16/12/2016.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import Foundation

enum GATTService: String {
	case DeviceInformation = "180A"

}

enum GATTCharacteristic: String {
	case DeviceName = "2A00"
	case FirmwareRevisionString = "2A26"
	case ManufacturerNameString = "2A29"
}

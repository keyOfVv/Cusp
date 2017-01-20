//
//  ScanTableViewCell.swift
//  Cusp
//
//  Created by Ke Yang on 20/01/2017.
//  Copyright © 2017 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

class ScanTableViewCell: UITableViewCell {

	@IBOutlet weak var deviceNameLabel: UILabel!
	@IBOutlet weak var RSSILabel: UILabel!
	@IBOutlet weak var idLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!

	var advertisement: Advertisement? {
		didSet {
			deviceNameLabel.text = advertisement?.peripheral.name ?? "<unnamed>"
			if let rssi = advertisement?.RSSI {
				RSSILabel.text = "RSSI: \(rssi)"
			} else {
				RSSILabel.text = "RSSI: N/A"
			}
			idLabel.text = "identifier: " + (advertisement?.peripheral.identifier.uuidString ?? "N/A")
			switch advertisement?.peripheral.state {
			case PeripheralState.connected?:
				stateLabel.text = "State: connected"
			case PeripheralState.connecting?:
				stateLabel.text = "State: connecting"
			case PeripheralState.disconnected?:
				stateLabel.text = "State: disconnected"
			case PeripheralState.unknown?:
				stateLabel.text = "State: unknown"
			default:
				break
			}
		}
	}

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

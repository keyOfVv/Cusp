//
//  SCRTableViewController.swift
//  Cusp
//
//  Created by Ke Yang on 27/02/2017.
//  Copyright © 2017 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

class SCRTableViewController: UITableViewController {

	var ad: Advertisement? {
		didSet {
			tableView.reloadData()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Connect/Disconnect & Subscription"
		tableView.register(UINib(nibName: "ScanTableViewCell", bundle: nil), forCellReuseIdentifier: ScanTableViewCellReuseID)
		CuspCentral.default.scanForUUIDString(["1803"], completion: { (ads) in
			self.ad = ads.first
		}, abruption: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return self.ad == nil ? 0 : 1 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: ScanTableViewCellReuseID, for: indexPath) as! ScanTableViewCell
		cell.advertisement = self.ad
		return cell
    }

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 100
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let peripheral = self.ad?.peripheral else { return }
		switch peripheral.state {
		case .disconnected:
			CuspCentral.default.connect(peripheral, success: { (_) in
				peripheral.readRSSI(success: { (resp) in
					dog(resp?.RSSI)
				}, failure: nil)
			}, failure: nil, abruption: nil)
		case .connected:
			CuspCentral.default.disconnect(peripheral, completion: {
				dog("diconnected")
			})
		case .unknown:
			dog("unknown state")
		case .connecting:
			dog("connecting")
		}
	}
}

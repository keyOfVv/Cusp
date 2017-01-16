//
//  ScanTableViewController.swift
//  Cusp
//
//  Created by Ke Yang on 16/01/2017.
//  Copyright © 2017 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

class ScanTableViewController: UITableViewController {

	var advertisements: [Advertisement]? {
		didSet {
			self.tableView.reloadData()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Scan"
		setRescanButton()
		scan()
    }

	func setRescanButton() {
		let barBtnItem = UIBarButtonItem(title: "rescan", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScanTableViewController.scan))
		self.navigationItem.rightBarButtonItem = barBtnItem
	}

	func scan() {
		CuspCentral.defaultCentral.scanForUUIDString(nil, completion: { (advertisements) in
			self.advertisements = advertisements
		}) { (error) in
			// error raised while scanning
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.advertisements?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell: UITableViewCell
		if let reuseCell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier") {
			cell = reuseCell
		} else {
			cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "reuseIdentifier")
		}

		let deviceName = advertisements?[indexPath.row].peripheral.name ?? "<unnamed>"
		var rssiStr = ""
		if let rssi = advertisements?[indexPath.row].RSSI {
			rssiStr = "\(rssi)"
		} else {
			rssiStr = "n/a"
		}
		cell.textLabel?.text = "\(rssiStr) \(deviceName)"

		return cell
    }

}

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

	var peripherals: [Peripheral]? {
		didSet {
			self.tableView.reloadData()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		CuspCentral.defaultCentral.scanForUUIDString(nil, completion: { (advertisements) in
			var ps = [Peripheral]()
			advertisements.forEach({ (ad) in
				ps.append(ad.peripheral)
			})
			self.peripherals = ps
		}) { (error) in
			// error raised while scanning
		}
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell: UITableViewCell
		if let reuseCell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier") {
			cell = reuseCell
		} else {
			cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "reuseIdentifier")
		}

		cell.textLabel?.text = peripherals?[indexPath.row].name
		return cell
    }

}

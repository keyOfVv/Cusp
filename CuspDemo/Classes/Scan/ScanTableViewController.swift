//
//  ScanTableViewController.swift
//  Cusp
//
//  Created by Ke Yang on 16/01/2017.
//  Copyright © 2017 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

private let ScanTableViewCellReuseID = "ScanTableViewCell"

class ScanTableViewController: UITableViewController {

	var advertisements: [Advertisement]? {
		didSet {
			self.tableView.reloadData()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Scan"
		tableView.register(UINib(nibName: "ScanTableViewCell", bundle: nil), forCellReuseIdentifier: ScanTableViewCellReuseID)
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
		let cell = tableView.dequeueReusableCell(withIdentifier: ScanTableViewCellReuseID, for: indexPath) as! ScanTableViewCell
		cell.advertisement = advertisements?[indexPath.row]
		return cell
    }

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 100
	}

}

//
//  DemoMainTableViewController.swift
//  Cusp
//
//  Created by Ke Yang on 23/12/2016.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

/**
* 1. Scan
* 2. Connect
* 3. GATT
*/

class DemoMainTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Cusp Demos"
		NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveNotification(notification:)), name: NSNotification.Name.CuspStateDidChange, object: nil)

		CuspCentral.default.scanForUUIDString(nil, completion: { (advertisements) in
			//				self.advertisements = advertisements
		}) { (error) in
			// error raised while scanning
		}
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell: UITableViewCell
		if let c = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier") {
			cell = c
		} else {
			cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "reuseIdentifier")
		}

		switch indexPath.row {
		case 0:
			cell.textLabel?.text = "Scan"
		case 1:
			cell.textLabel?.text = "Scan->Connect->Subscribe->Unsubscribe->Disconnect"
		case 2:
			cell.textLabel?.text = "Descriptor Operations"
		default:
			break
		}
		return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch indexPath.row {
		case 0:
			let scanDemoVC = ScanTableViewController(style: UITableViewStyle.plain)
			navigationController?.pushViewController(scanDemoVC, animated: true)
		case 1:
			let connTBVC = ConnectTableViewController()
			navigationController?.pushViewController(connTBVC, animated: true)
		case 2:
			let descVC = DescriptorViewController()
			navigationController?.pushViewController(descVC, animated: true)
		default:
			break
		}
	}
}

// MARK: -
extension DemoMainTableViewController {

	func didReceiveNotification(notification: Notification) {
		dog(notification)
	}
}

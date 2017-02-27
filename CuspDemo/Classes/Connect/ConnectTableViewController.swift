//
//  ConnectTableViewController.swift
//  Cusp
//
//  Created by Ke Yang on 27/02/2017.
//  Copyright © 2017 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

class ConnectTableViewController: UITableViewController {

	var ad: Advertisement? {
		didSet {
			tableView.reloadData()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.register(UINib(nibName: "ScanTableViewCell", bundle: nil), forCellReuseIdentifier: ScanTableViewCellReuseID)
		CuspCentral.default.scanForUUIDString(["FE90"], completion: { (ads) in
			self.ad = ads.first
		}, abruption: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.ad == nil ? 0 : 1
    }

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
				peripheral.subscribe(characteristic: "00008002-60B2-21F8-BCE3-94EEA697F98C",
				                     ofService: "00008000-60B2-21F8-BCE3-94EEA697F98C",
				                     success: { (_) in
										dog("subscribed")
				}, failure: nil, update: { (resp) in
					dog(resp?.value)
				})
			}, failure: nil, abruption: nil)
		case .connected:
			peripheral.unsubscribe(characteristic: "00008002-60B2-21F8-BCE3-94EEA697F98C",
			                       ofService: "00008000-60B2-21F8-BCE3-94EEA697F98C",
			                       success: { (_) in
									dog("unsubscribed")
									CuspCentral.default.disconnect(peripheral, completion: {
										dog("diconnected")
									})
			}, failure: nil)
		case .unknown:
			dog("unknown state")
		case .connecting:
			dog("connecting")
		}
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

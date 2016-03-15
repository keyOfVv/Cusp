//
//  DeviceTableViewController.swift
//  Cusp
//
//  Created by keyOfVv on 2/14/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp
import CoreBluetooth

// MARK: - Constants

// MARK: - [Controller] BLE Device Table View Controller

/// BLE Device Table View Controller
public class DeviceTableViewController: UITableViewController {

	// MARK: Interface Properties

	// MARK: Stored Properties

	var available: [Advertisement]? {
		didSet {
			self.tableView.reloadData()
		}
	}

	// MARK: Computed Properties

	// MARK: Initializer

	// MARK: View Life Circle

	@available(*, unavailable, message="don't call this method directly")
    override public func viewDidLoad() {
        super.viewDidLoad()

		self.title = "Devices"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "scan", style: UIBarButtonItemStyle.Plain, target: self, action: "scan")
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: TableView Data Source

	@available(*, unavailable, message="don't call this method directly")
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (self.available == nil ? 0 : self.available!.count)
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier")
		if cell == nil {
			cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "reuseIdentifier")
		}
		if let advInfo = self.available?[indexPath.row] {
			cell?.textLabel?.text = advInfo.peripheral.name
			cell?.detailTextLabel?.text = String(advInfo.RSSI.integerValue)
		}

        return cell!
    }

	public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//		if let peripheral = self.peripherals?[indexPath.row] {
//			Cusp.central.connect(peripheral, success: { (response) -> Void in
//				let deviceInfoTableViewController = DeviceInfoTableViewController(style: UITableViewStyle.Grouped)
//				deviceInfoTableViewController.peripheral = peripheral
//				self.navigationController?.pushViewController(deviceInfoTableViewController, animated: true)
//				}, failure: { (error) -> Void in
//					log(error)
//			})
//		}
	}


	// MARK: TableView Delegate

	public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 44.0
	}

	override public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return CGFloat(5.0)
	}

	// MARK: 其他

	// MARK: 销毁

	deinit {

	}
}

// MARK: - 开放接口

public extension DeviceTableViewController {

}

// MARK: - 内部方法

public extension DeviceTableViewController {

	internal func scan() {

		Cusp.central.scanForUUIDString(nil, completion: { (advertisementInfoArray) -> Void in
			log("\(advertisementInfoArray)")
			self.available = advertisementInfoArray.sort({ (a, b) -> Bool in
				return a.peripheral.name <= b.peripheral.name
			})
			}, abruption: { (error) -> Void in
				log(error)
		})
	}
}

// MARK: - 私有方法

private extension DeviceTableViewController {

}

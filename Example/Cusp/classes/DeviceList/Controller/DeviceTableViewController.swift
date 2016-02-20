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

	// MARK: 控件属性

	// MARK: 储值属性

	var peripherals: [Peripheral]? {
		didSet {
			self.tableView.reloadData()
		}
	}

	// MARK: 计算属性

	// MARK: 构造方法

	// MARK: View生命周期方法

	@available(*, unavailable, message="don't call this method directly")
    override public func viewDidLoad() {
        super.viewDidLoad()

		self.title = "BLE devices list"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "scan", style: UIBarButtonItemStyle.Plain, target: self, action: "scan")
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: TableView数据源方法

	@available(*, unavailable, message="don't call this method directly")
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (self.peripherals == nil ? 0 : self.peripherals!.count)
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier")
		if cell == nil {
			cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "reuseIdentifier")
		}
		if let peripheral = self.peripherals?[indexPath.row] {
			cell?.textLabel?.text = peripheral.name
			cell?.detailTextLabel?.text = String(peripheral.RSSI?.integerValue)
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


	// MARK: TableView代理方法

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
//		let uuid = CBUUID(string: "1803")
		Cusp.central.scan(nil, completion: { (peripherals) -> Void in
			log("\(peripherals)")
			self.peripherals = peripherals.sort({ (peripheralA, peripheralB) -> Bool in
				return peripheralA.name <= peripheralB.name
			})

			}, abruption: { (error) -> Void in
				log(error)
		})
	}
}

// MARK: - 私有方法

private extension DeviceTableViewController {

}

// MARK: - DeviceBriefTableViewCellDelegate

//extension DeviceTableViewController: DeviceBriefTableViewCellDelegate {
//	func deviceBriefTableViewCell(deviceBriefTableViewCell: DeviceBriefTableViewCell, wantsConnectTo peripheral: Peripheral) {
////		Cusp.central.connect(peripheral, success: { (response) -> Void in
////			Cusp.central.discover(nil, inPeripheral: peripheral, success: { (response) -> Void in
////
////				}, failure: { (error) -> Void in
////
////			})
////			}, failure: { (error) -> Void in
////
////		})
//	}
//
//	func deviceBriefTableViewCell(deviceBriefTableViewCell: DeviceBriefTableViewCell, wantsDisconnectFrom peripheral: Peripheral) {
//
//	}
//
//	func deviceBriefTableViewCell(deviceBriefTableViewCell: DeviceBriefTableViewCell, wantsCancelConnectTo peripheral: Peripheral) {
//
//	}
//}

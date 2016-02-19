//
//  DeviceInfoTableViewController.swift
//  CuspExample
//
//  Created by keyOfVv on 2/16/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import UIKit
import Cusp

// MARK: - 私有常量

// MARK: - [控制器]<#描述#>

/// <#描述#>
public class DeviceInfoTableViewController: UITableViewController {

	// MARK: 控件属性

	// MARK: 储值属性

	var peripheral: Peripheral?

	// MARK: 计算属性

	// MARK: 构造方法

	// MARK: View生命周期方法

	@available(*, unavailable, message="don't call this method directly")
    override public func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "disconnect", style: UIBarButtonItemStyle.Plain, target: self, action: "disconnect")
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: TableView数据源方法

	@available(*, unavailable, message="don't call this method directly")
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
	@available(*, unavailable, message="don't call this method directly")
    override public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

	// MARK: TableView代理方法

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
	@available(*, unavailable, message="don't call this method directly")
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

	// MARK: 其他

	// MARK: 销毁

	deinit {

	}
}

// MARK: - 开放接口

public extension DeviceInfoTableViewController {

}

// MARK: - 内部方法

public extension DeviceInfoTableViewController {

	internal func disconnect() {
		if let peripheral = self.peripheral {
			Cusp.central.disconnect(peripheral, completion: { () -> Void in
				log("disconnected")
			})
		}
	}
}

// MARK: - 私有方法

private extension DeviceInfoTableViewController {

}

// MARK: - 代理方法

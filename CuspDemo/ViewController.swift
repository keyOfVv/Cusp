//
//  ViewController.swift
//  CuspDemo
//
//  Created by Ke Yang on 08/12/2016.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

class ViewController: UIViewController {

	var per: Peripheral? {
		didSet {
			self.test()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		CuspCentral.default.scanForUUIDString(nil, completion: { (ads) in
			self.per = ads.first?.peripheral
			print(ads)
			if ads.count > 0 {
				CuspCentral.default.stopScan()
			}
		}, abruption: { (error) in

		})
	}

	func test() {
		guard let per = self.per else {
			return
		}
		CuspCentral.default.connect(per, success: { (resp) in
			print("connected")
			per.getManufacturerNameString(completion: { (manufacturerName) in
				print(manufacturerName)
			})
			per.getFirmwareRevisionString(completion: { (firmwareRevision) in
				print(firmwareRevision)
			})
		}, failure: { (error) in
			print(error)
		}) { (error) in
			print(error)
		}
	}
}


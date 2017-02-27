//
//  DescriptorViewController.swift
//  Cusp
//
//  Created by Ke Yang on 28/12/2016.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

class DescriptorViewController: UIViewController {

	var peripheral: Peripheral? {
		didSet {
			test()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Descriptor Test"

		enableDebugLog(enabled: false)
		CuspCentral.default.scanForUUIDString(nil, completion: { (ads) in
			self.peripheral = (ads.first { $0.peripheral.name == "keyang" })?.peripheral
		}) { (error) in

		}
    }

	func test() {
	}
}

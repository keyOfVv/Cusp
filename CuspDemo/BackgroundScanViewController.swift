//
//  BackgroundScanViewController.swift
//  Cusp
//
//  Created by Ke Yang on 23/12/2016.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

class BackgroundScanViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Background Scanning"
		Cusp.enableDebugLog(enabled: false)
		Cusp.prepare(withCentralIdentifier: "com.keyang.cusp.backgroundScanDemo") { (available) in
			self.repeatScanForever()
		}
    }

	func repeatScanForever() {
		Cusp.central.scanForUUIDString(nil, completion: { (ads) in
			print("\(ads.count) peripherals found")
			self.repeatScanForever()
		}, abruption: { (error) in

		})
	}
}

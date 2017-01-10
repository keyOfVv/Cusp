//
//  BackgroundScanViewController.swift
//  Cusp
//
//  Created by Ke Yang on 23/12/2016.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import UIKit
@testable import Cusp

class BackgroundScanViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Background Scanning"

		enableDebugLog(enabled: false)
		self.repeatScanForever(duration: 3.0)
    }

	func repeatScanForever(duration: TimeInterval) {
		CuspCentral.defaultCentral.scanForUUIDString(nil, duration: duration, completion: { (ads) in
			dog("\(ads.count) peripherals found")
		}, abruption: { (error) in

		})
	}

	deinit {
		dog("BackgroundScanViewController deinited")
		CuspCentral.defaultCentral.stopScan()
	}
}

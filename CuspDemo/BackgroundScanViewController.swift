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
		Cusp.prepare(withCentralIdentifier: "com.keyang.cusp.backgroundScanDemo") { [weak self] (available) in
			self?.repeatScanForever(duration: 3.0)
		}
    }

	func repeatScanForever(duration: TimeInterval) {
		Cusp.central.scanForUUIDString(nil, duration: duration, completion: { [weak self] (ads) in
			dog("\(ads.count) peripherals found")
//			self?.repeatScanForever(duration: 3.0)
		}, abruption: { (error) in

		})
	}

	deinit {
		dog("BackgroundScanViewController deinited")
		Cusp.central.stopScan()
	}
}

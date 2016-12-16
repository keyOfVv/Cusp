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

		Cusp.prepare { (available) in
			Cusp.central.scanForUUIDString(nil, completion: { (ads) in
				self.per = ads.first?.peripheral
			}, abruption: { (error) in

			})
		}
	}

	func test() {
		guard let per = self.per else {
			return
		}
		Cusp.central.connect(per, success: { (resp) in
			per.discoverService(UUIDStrings: nil, success: { (resp) in
				per.discoverCharacteristic(UUIDStrings: nil, ofService: per["180A"]!, success: { (resp) in
					per["180A"]!.characteristics?.forEach({ (char) in
						print(char.uuid.uuidString)
						print(char)
					})
				}, failure: { (error) in

				})
			}, failure: { (error) in

			})
		}, failure: { (error) in

		}) { (error) in

		}
	}
}


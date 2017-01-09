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
		CuspCentral.prepare(withCentralIdentifier: "com.keyang.cusp.descriptorOperationDemo") { [weak self] (available) in
			CuspCentral.central.scanForUUIDString(nil, completion: { (ads) in
				for d in ads {
					if d.peripheral.name == "keyang" {
						self?.peripheral = d.peripheral
						break
					}
				}
			}) { (error) in
				
			}
		}
    }

	func test() {
		guard let p = peripheral else {
			return
		}
//		Cusp.central.connect(p, success: { (resp) in
//			p.discoverServices(UUIDStrings: ["D0611E78-BBB4-4591-A5F8-487910AE4366"], success: { (resp) in
//				p.discoverCharacteristics(UUIDStrings: ["8667556C-9A37-4C91-84ED-54EE27D90049"], ofService: p["D0611E78-BBB4-4591-A5F8-487910AE4366"]!, success: { (resp) in
//					p.discoverDescriptors(forCharacteristic: p["D0611E78-BBB4-4591-A5F8-487910AE4366"]!["8667556C-9A37-4C91-84ED-54EE27D90049"]!, success: { (resp) in
//						dog(p["D0611E78-BBB4-4591-A5F8-487910AE4366"]!["8667556C-9A37-4C91-84ED-54EE27D90049"]!.descriptors)
//						let des = p["D0611E78-BBB4-4591-A5F8-487910AE4366"]!["8667556C-9A37-4C91-84ED-54EE27D90049"]!.descriptors?.first!
//						var enabled: UInt16 = 1
//						var bEnabled = Data(bytes: &enabled, count: MemoryLayout.size(ofValue: UInt16()))
//						p.write(bEnabled, forDescriptor: des!, success: { (resp) in
//							dog("written")
//						}, failure: { (error) in
//
//						})
//					}, failure: { (error) in
//
//					})
//				}, failure: { (error) in
//
//				})
//			}, failure: { (error) in
//
//			})
//		}, failure: { (error) in
//
//		}) { (error) in
//
//		}
	}
}

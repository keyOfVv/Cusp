//
//  AppDelegate.swift
//  CuspDemo
//
//  Created by Ke Yang on 08/12/2016.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import UIKit
import Cusp

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		Cusp.enableDebugLog(enabled: true)
		CuspCentral.defaultCentral.prepare { (available) in
			dog("BLE is \(available ? "" : "NOT ")ready")
		}
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
//		CuspCentral.defaultCentral.executeBackgroundTask(withApplication: application) {
//			self.repeatScanForever()
//		}
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}

	func repeatScanForever() {
		CuspCentral.defaultCentral.scanForUUIDString(["1803"], completion: { (ads) in
			dog("\(ads.count) peripherals found while in background")
			self.repeatScanForever()
		}, abruption: { (error) in

		})
	}
}

func dog(_ anyObject: Any?, function: String = #function, file: String = #file, line: Int = #line) {

	let dateFormat		  = DateFormatter()
	dateFormat.dateFormat = "HH:mm:ss.SSS"

	let date = NSDate()
	let time = dateFormat.string(from: date as Date)

	print("[\(time)] <\((file as NSString).lastPathComponent)> \(function) LINE(\(line)): \(anyObject)")
}



//
//  Subscription.swift
//  Pods
//
//  Created by Ke Yang on 3/16/16.
//
//

import Foundation

internal class Subscription: NSObject {
	internal private(set) var characteristic: Characteristic!
	internal private(set) var update: ((Response?) -> Void)?

	private override init() {
		super.init()
	}

	convenience init(characteristic: Characteristic, update: ((Response?) -> Void)?) {
		self.init()
		self.characteristic = characteristic
		self.update = update
	}

	override var hash: Int {
		return self.characteristic.hashValue
	}

	override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? Subscription {
			return self.hashValue == other.hashValue
		}
		return false
	}
}
//
//  Subscription.swift
//  Pods
//
//  Created by Ke Yang on 3/16/16.
//
//

import Foundation


class Subscription: NSObject {
	fileprivate(set) var characteristic: Characteristic!
	fileprivate(set) var update: ((Response?) -> Void)?

	fileprivate override init() {
		super.init()
	}

	convenience init(characteristic: Characteristic, update: ((Response?) -> Void)?) {
		self.init()
		self.characteristic = characteristic
		self.update = update
	}

	override var hash: Int {
		return characteristic.hashValue
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? Subscription {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

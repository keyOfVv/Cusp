//
//  keyOfVv+UIView.swift
//  Aura
//
//  Created by keyOfVv on 11/4/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import UIKit

// MARK: - 快速访问UIView尺寸位置的各项属性

public extension UIView {

	/// 原点横坐标
	public var x: CGFloat {
		get { return self.frame.origin.x }
		set { self.frame.origin.x = newValue }
	}

	/// 原点纵坐标
	public var y: CGFloat {
		get { return self.frame.origin.y }
		set { self.frame.origin.y = newValue }
	}

	/// 宽度
	public var width: CGFloat {
		get { return self.frame.size.width }
		set { self.frame.size.width = newValue }
	}

	/// 高度
	public var height: CGFloat {
		get { return self.frame.size.height }
		set { self.frame.size.height = newValue }
	}

	/// 原点
	public var origin: CGPoint {
		get { return self.frame.origin }
		set { self.frame.origin = newValue }
	}

	/// 尺寸
	public var size: CGSize {
		get { return self.frame.size }
		set { self.frame.size = newValue }
	}

	/// 最大横坐标
	public var maxX: CGFloat {
		get { return self.x + self.width }
		set { self.frame.origin.x = newValue - self.width }
	}

	/// 最大纵坐标
	public var maxY: CGFloat {
		get { return self.y + self.height }
		set { self.frame.origin.y = newValue - self.height }
	}

	/// 中点横坐标
	public var centerX: CGFloat {
		get { return self.x + self.width * 0.5 }
		set { self.frame.origin.x = newValue - self.width * 0.5 }
	}

	/// 中点纵坐标
	public var centerY: CGFloat {
		get { return self.y + self.height * 0.5 }
		set { self.frame.origin.y = newValue - self.height * 0.5 }
	}

	/// 中点
	public var centre: CGPoint {
		get { return CGPointMake(self.centerX, self.centerY) }
		set {
			self.centerX = newValue.x
			self.centerY = newValue.y
		}
	}
}










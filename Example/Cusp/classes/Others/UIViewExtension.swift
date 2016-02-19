//
//  keyOfVv+UIView.swift
//  Aura
//
//  Created by keyOfVv on 11/4/15.
//  Copyright © 2015 com.sangebaba. All rights reserved.
//

import Foundation

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

// MARK: - 快速设置阴影

public extension UIView {

	/// 默认的阴影色深
	private var defaultShadowOpacity: Float {
		return Float(0.65)
	}

	/// 默认的阴影偏移量 - X轴
	private var defaultShadowOffsetX: CGFloat {
		return 0.0.cgFloat
	}

	/// 默认的阴影偏移量 - Y轴
	private var defaultShadowOffsetY: CGFloat {
		return 2.0.cgFloat
	}

	/// 默认的阴影发散度
	private var defaultShadowRadius: CGFloat {
		return 3.0.cgFloat
	}

	/**
	设置阴影, 使用默认值(不透明度0.65, 横轴偏移0.0, 纵轴偏移2.0, 羽化半径3.0)
	*/
	public func configShadow() {
        self.layer.shadowOpacity = self.defaultShadowOpacity
        self.layer.shadowOffset  = CGSizeMake(self.defaultShadowOffsetX, self.defaultShadowOffsetY)
        self.layer.shadowRadius  = self.defaultShadowRadius
	}

	/**
	设置阴影

	- parameter opacity: 不透明度
	- parameter offsetX: 横轴偏移
	- parameter offsetY: 纵轴偏移
	- parameter radius:  羽化半径
	*/
	public func configShadow(opacity opacity: Double?, offsetX: Double?, offsetY: Double?, radius: Double?) {

		self.layer.shadowOpacity = (opacity == nil) ? self.defaultShadowOpacity : Float(opacity!)
		self.layer.shadowOffset  = CGSizeMake(
			(offsetX == nil) ? self.defaultShadowOffsetX : offsetX!.cgFloat,
			(offsetY == nil) ? self.defaultShadowOffsetY : offsetY!.cgFloat
		)
		self.layer.shadowRadius  = (radius == nil) ? self.defaultShadowRadius : radius!.cgFloat
	}
}

// MARK: - 设置圆角半径和裁切

public extension UIView {

	/**
	设置圆角半径和裁切

	- parameter cornerRadius:  圆角半径
	- parameter masksToBounds: 是否裁切
	*/
	public func configCornerRadius(cornerRadius: Double, masksToBounds: Bool) {
		self.layer.cornerRadius = cornerRadius.cgFloat
		self.layer.masksToBounds = masksToBounds
	}
}

// MARK: - 设置右上角的图形角标

public extension UIView {

	/**
	添加图形角标

	- parameter badgeValue: 角标文本
	*/
	public func addBadge(badgeValue: String) {
		let attributes = [
			NSFontAttributeName: FONT_CONTENT_SUB
		]
		let rect = (badgeValue as NSString).boundingRectWithSize(CGSIZE_MAX, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributes, context: nil)
		let badge = Badge(frame: rect)
		badge.text = badgeValue
		self.addSubview(badge)
	}

	/**
	移除图形角标
	*/
	public func removeBadges() {
		for subview in self.subviews {
			if subview.isKindOfClass(Badge.self) {
				(subview as! Badge).removeFromSuperview()
			}
		}
	}
}

// MARK: - 设置控件的加载状态效果

public extension UIView {

	/**
	开始加载, 在控件的中心会出现一个UIActivityIndicatorView, 附带动画效果
	*/
	public func startLoading() {
		let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
		self.hidden = true
		activityIndicator.centre = self.centre
		self.superview?.addSubview(activityIndicator)
		activityIndicator.startAnimating()
	}

	/**
	停止加载, UIActivityIndicatorView消失
	*/
	public func ceaseLoading() {
		if !self.isLoading() {
			return
		}
		if let superview = self.superview {
			for subview in superview.subviews {
				if subview.isKindOfClass(UIActivityIndicatorView.self) {
					let activityIndicator = subview as! UIActivityIndicatorView
					activityIndicator.stopAnimating()
					activityIndicator.removeFromSuperview()
					self.hidden = false
				}
			}
		}
	}

	/**
	控件是否处于加载效果显示状态

	- returns: 布尔值
	*/
	public func isLoading() -> Bool {
		if let superview = self.superview {
			for subview in superview.subviews {
				if subview.isKindOfClass(UIActivityIndicatorView.self) {
					let activityIndicator = subview as! UIActivityIndicatorView
					return activityIndicator.isAnimating()
				}
			}
		}
		return false
	}
}

// MARK: - 控件截图

public extension UIView {

	/**
	对控件进行截图

	- returns: 截取的图片
	*/
	public func snapshot() -> UIImage? {
		let widthInPxl = self.width
		let heightInPxl = self.height
		// 准备截图
		let size = CGSizeMake(widthInPxl, heightInPxl)

		log("snapshotSize= " + NSStringFromCGSize(size))
		var image: UIImage?
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		if let context = UIGraphicsGetCurrentContext() {
			self.layer.renderInContext(context)
			image = UIGraphicsGetImageFromCurrentImageContext()
		}
		log("actualSnapshotSize= " + NSStringFromCGSize(image!.size))
		UIGraphicsEndImageContext()
		return image
	}
}












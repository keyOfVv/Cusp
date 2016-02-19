//
//  Functions.swift
//  Aura
//
//  Created by keyOfVv on 1/8/16.
//  Copyright © 2016 com.sangebaba. All rights reserved.
//

import Foundation

// MARK: - 通用函数

/**
打印控制台日志, 仅在debug模式时有效, release模式时此方法不执行任务操作;

- parameter anyObject: 任意对象(不包括Int, Double, Bool)
- parameter function:  函数(方法)名称
- parameter file:      文件名称
- parameter line:      代码行号
*/
public func log(anyObject: AnyObject?, function: String = __FUNCTION__, file: String = __FILE__, line: Int	= __LINE__) {
	#if DEBUG
		let dateFormat		  = NSDateFormatter()
		dateFormat.dateFormat = "HH:mm:ss.SSS"

		let date = NSDate()
		let time = dateFormat.stringFromDate(date)

		print("[\(time)] <\((file as NSString).lastPathComponent)> \(function) LINE(\(line)): \(anyObject)")
	#endif
}

/**
去除数组中的重复元素

- parameter source: 数组

- returns: 去除重复元素后的新数组
*/
func uniq<S: SequenceType, T: Hashable where S.Generator.Element == T>(source: S) -> [T] {
	var buffer = [T]()
	var added = Set<T>()
	for elem in source {
		if !added.contains(elem) {
			buffer.append(elem)
			added.insert(elem)
		}
	}
	return buffer
}

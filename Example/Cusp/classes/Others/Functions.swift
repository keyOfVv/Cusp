//
//  Functions.swift
//  Aura
//
//  Created by keyOfVv on 1/8/16.
//  Copyright © 2016 com.sangebaba. All rights reserved.
//

import Foundation

// MARK: - Useful functions

/**
a useful NSLOG substitute works under DEBUG mode only (please add "-D DEBUG" in Other Swift Flags manually)
控制台打印函数, 用以取代NSLog函数

- parameter anyObject: any object other than Int/Double/Bool (任意对象除Int/Double/Bool之外, 使用"\(Int/Double/Bool)"转换为String后再打印)
- parameter function:  name of method/function (方法/函数名称)
- parameter file:      name of file (文件名称)
- parameter line:      line no. (代码行号)
*/
internal func log(anyObject: AnyObject?, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
	#if DEBUG
        let formatter        = NSDateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"

		let date = NSDate()
		let time = formatter.stringFromDate(date)

		print("[\(time)] <\((file as NSString).lastPathComponent)> \(function) LINE(\(line)): \(anyObject)")
	#endif
}

/**
去除数组中的重复元素

- parameter source: 数组

- returns: 去除重复元素后的新数组
*/
internal func uniq<S: SequenceType, T: Hashable where S.Generator.Element == T>(source: S) -> [T] {
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

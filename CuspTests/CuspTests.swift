//
//  CuspTests.swift
//  CuspTests
//
//  Created by Ke Yang on 9/15/16.
//  Copyright © 2016 com.keyofvv. All rights reserved.
//

import XCTest
@testable import Cusp

class CuspTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
		let expect = expectation(description: "featured articles shall NOT be nil or empty")
		waitForExpectations(timeout: 45.0) { (error) in
			if let err = error {
				XCTFail("timed out due to: \(err)")
			}
		}
		Cusp.central.scanForUUIDString(["1803"], completion: { (ads) in
			dog(ads)
			expect.fulfill()
			}) { (err) in

		}
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

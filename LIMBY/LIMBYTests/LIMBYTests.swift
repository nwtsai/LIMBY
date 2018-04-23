//
//  LIMBYTests.swift
//  LIMBYTests
//
//  Created by Nathan Tsai on 2/1/18.
//  Copyright © 2018 Nathan Tsai. All rights reserved.
//

import XCTest
@testable import LIMBY

class LIMBYTests: XCTestCase {
    
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
        DataQueue.singleton.login(username: "peifeng2005", password: "peifeng2005", vc: LoginViewController())
        DataQueue.singleton.subscribe(prefix: "weight")
        var vc : LineChartViewController = LineChartViewController()
        sleep(15)
        var qc = DataQueue.singleton.queue.count // queue count
        var pc = vc.getValues().count // processed count
        XCTAssert(qc == pc)
    }
    
    func testPerformanceExample() {
        // Requirement: Must update a point within 10 seconds.
        DataQueue.singleton.login(username: "peifeng2005", password: "peifeng2005", vc: ViewController())
        DataQueue.singleton.subscribe(prefix: "weight")
        sleep(10)
        var qc = DataQueue.singleton.queue.count
        XCTAssert(qc > 0)
    }
    
}

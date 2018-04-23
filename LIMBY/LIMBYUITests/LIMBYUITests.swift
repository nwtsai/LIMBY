//
//  LIMBYUITests.swift
//  LIMBYUITests
//
//  Created by Nathan Tsai on 2/1/18.
//  Copyright © 2018 Nathan Tsai. All rights reserved.
//

import XCTest

class LIMBYUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGoodLogin() {
        let app = XCUIApplication()
        let usernameTextField = app.textFields["Username"]
        XCTAssertTrue(usernameTextField.exists)
        usernameTextField.tap()
        usernameTextField.typeText("peifeng2005@gmail.com")

        let passwordSecureTextField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureTextField.exists)
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("peifeng2005")

        app.buttons["Login"].tap()
        let lineChartView = app.navigationBars["LIMBY.LineChartView"]
        let exists = NSPredicate(format: "exists == 1")
        
        expectation(for: exists, evaluatedWith: lineChartView, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertTrue(lineChartView.exists)
    }

    func testBadLogin() {
        let app = XCUIApplication()
        app.buttons["Login"].tap()
        let error_alert = app.alerts["Error"]
        XCTAssertTrue(error_alert.exists)
    }

}

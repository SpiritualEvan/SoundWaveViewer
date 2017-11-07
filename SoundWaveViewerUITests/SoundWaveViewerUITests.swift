//
//  SoundWaveViewerUITests.swift
//  SoundWaveViewerUITests
//
//  Created by Won Cheul Seok on 2017. 11. 7..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import XCTest

class SoundWaveViewerUITests: XCTestCase {
    
    var app:XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNewFile() {
        // press new file button
        let newFileButton = app.buttons.element(boundBy: 0)
        XCTAssertEqual("+", newFileButton.title)
        XCTAssertFalse(newFileButton.images.element(boundBy: 0).exists)
        newFileButton.tap()
        
        // get photo
        app.cells.element(boundBy: 0).tap()
        app.cells.element(boundBy: 0).tap()
        
        // check new file button title
        XCTAssertTrue(newFileButton.title.isEmpty)
        XCTAssertTrue(newFileButton.images.element(boundBy: 0).exists)
    }
    
}

//
//  SVWaveFormBuilderTests.swift
//  SoundWaveViewerTests
//
//  Created by Won Cheul Seok on 2017. 11. 9..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import XCTest
import AVFoundation

@testable import SoundWaveViewer

class SVWaveFormBuilderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBuildWaveForm() {
        
        // test for multi track audios
        let onNextExpectation = expectation(description: "onNextExpectation")
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        SVWaveFormBuilder.buildWaveform(mediaURL: URL(fileURLWithPath:mediaPath!)) { (waveform, error) in
            XCTAssertNotNil(waveform)
            XCTAssertNil(error)
            XCTAssertNotNil(waveform!.pcmDatas)
            XCTAssertTrue(0 < waveform!.pcmDatas.count)
            onNextExpectation.fulfill()
        }
    
        self.waitForExpectations(timeout: 10) { (error) in
            guard nil == error else {
                XCTFail((error?.localizedDescription)!)
                return
            }
        }
    }
}

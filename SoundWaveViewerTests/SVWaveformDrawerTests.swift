//
//  SVWaveformDrawerTests.swift
//  SoundWaveViewerTests
//
//  Created by Evan Seok on 2017. 11. 13..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import XCTest

@testable import SoundWaveViewer

class SVWaveformDrawerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testWaveformImageWithWaveformSegmentInformation() {
        
        var dataArray = [Float](repeating:1.0, count: 44100 * 60 * 30)
        dataArray += [Float](repeating:-1.0, count: 44100 * 60 * 30)
        let expectedSize = CGSize(width: 10.0, height: 10.0)
        do {
            let image = try SVWaveformDrawer.waveformImage(waveform: dataArray, imageSize: expectedSize)
            XCTAssertNotNil(image)
            XCTAssertEqual(expectedSize, image.size)
        }catch {
            XCTFail(error.localizedDescription)
        }
        
    }
}

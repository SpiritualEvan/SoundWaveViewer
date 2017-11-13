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
    
    func testGeneratingWaveformImage() {
        
        let dataArray = [MinMaxElement](repeating:(1.0, -1.0), count: 4096)
        let expectedSize = CGSize(width: 4096, height: 4096)
        self.measure {
            do {
                let image = try SVWaveformDrawer.waveformImage(waveform: dataArray, imageSize: expectedSize)
                XCTAssertNotNil(image)
                XCTAssertEqual(expectedSize, image.size)
            }catch {
                XCTFail(error.localizedDescription)
            }
        }
        
    }
}

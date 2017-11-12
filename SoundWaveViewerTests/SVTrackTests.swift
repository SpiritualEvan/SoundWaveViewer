//
//  SVTrackTests.swift
//  SoundWaveViewerTests
//
//  Created by Won Cheul Seok on 2017. 11. 12..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import XCTest

@testable import SoundWaveViewer

class SVTrackTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNumberOfWaveformSegments() {
        let track = SVTrack()
        track.pcmDatas = [Float](repeating:0.0, count:10000)
        XCTAssertEqual(track.numberOfWaveformSegments(samplesPerPixel: 10, segmentWidth: 100), 10)
        XCTAssertEqual(track.numberOfWaveformSegments(samplesPerPixel: 11, segmentWidth: 100), 10)
        XCTAssertEqual(track.numberOfWaveformSegments(samplesPerPixel: 9, segmentWidth: 3), 371)
    }
    func testGeneratingWaveformWithRange() {
        
    }
    
}

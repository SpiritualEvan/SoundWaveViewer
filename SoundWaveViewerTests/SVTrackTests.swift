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
        XCTAssertEqual(track.numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription(imageSize: CGSize(width: 100, height: 100), indexOfSegment: 0, samplesPerPixel: 10)), 10)
        XCTAssertEqual(track.numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription(imageSize: CGSize(width: 100, height: 100), indexOfSegment: 0, samplesPerPixel: 11)), 10)
        XCTAssertEqual(track.numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription(imageSize: CGSize(width: 3, height: 100), indexOfSegment: 0, samplesPerPixel: 9)), 371)
        
    }
    func testGeneratingWaveformWithRange() {
        
    }
    
}

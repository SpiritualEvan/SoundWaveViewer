//
//  SVSoundLoaderTests.swift
//  SoundWaveViewerTests
//
//  Created by Evan Seok on 2017. 11. 8..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import XCTest
@testable import SoundWaveViewer

class SVSoundLoaderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMediaLoad() {
        
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "multi_track_audio", ofType: "MOV")
        XCTAssertNotNil(mediaPath)
        SVSoundLoader.loadMedia(mediaPath: mediaPath) { (media, error) in
            XCTAssertNotNil(media)
            XCTAssertGreaterThan(0, media!.tracks.count)
        }
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

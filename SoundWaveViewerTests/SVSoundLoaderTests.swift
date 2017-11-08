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
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "multi_track_audio", ofType: "MOV")
        XCTAssertNotNil(mediaPath)
        
        let loadedMedia = SVSoundLoader.loadMedia(mediaPath: mediaPath)
        XCTAssertNotNil(loadedMedia)
        
        XCTAssertEqual(<#T##expression1: [Equatable]##[Equatable]#>, <#T##expression2: [Equatable]##[Equatable]#>) loadedMedia!.title
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

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
    
    func testLoad4TrackMedia() {
        
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "4_tracks_audio", ofType: "mov")
        XCTAssertNotNil(mediaPath)
        
        let onNextExpectation = expectation(description: "onNextExpectation")
        SVSoundLoader.loadTracks(mediaURL: URL(fileURLWithPath: mediaPath!)) { (media, error) in
            XCTAssertTrue(nil != media)
            XCTAssertNotNil(media!.asset)
            XCTAssertEqual(4, media!.tracks.count)
            XCTAssertNil(error)
            onNextExpectation.fulfill()
        }
    
        self.waitForExpectations(timeout: 10) { (error) in
            guard nil == error else {
                XCTFail((error?.localizedDescription)!)
                return
            }
            
        }
    }
    func testLoad1TrackMedia() {
        
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        XCTAssertNotNil(mediaPath)
        
        let onNextExpectation = expectation(description: "onNextExpectation")
        SVSoundLoader.loadTracks(mediaURL: URL(fileURLWithPath: mediaPath!)) { (media, error) in
            XCTAssertTrue(nil != media)
            XCTAssertNotNil(media!.asset)
            XCTAssertEqual(1, media!.tracks.count)
            XCTAssertNil(error)
            onNextExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 10) { (error) in
            guard nil == error else {
                XCTFail((error?.localizedDescription)!)
                return
            }
            
        }
    }
    func testVideoOnlyMedia() {
        
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "video_only", ofType: "mov")
        let onNextExpectation = expectation(description: "onNextExpectation")
        SVSoundLoader.loadTracks(mediaURL: URL(fileURLWithPath: mediaPath!)) { (medias, error) in
            XCTAssertTrue(nil == medias)
            XCTAssertTrue(error! is SVSoundLoaderError)
            XCTAssertEqual(SVSoundLoaderError.NoAudioTracksFounded, (error as! SVSoundLoaderError))
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

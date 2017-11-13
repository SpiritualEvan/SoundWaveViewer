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
    func testBuildPCMData() {
        
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        let asset = AVURLAsset(url: URL(fileURLWithPath:mediaPath!))
        let audioTrack = asset.tracks(withMediaType: .audio)[0]
        do {
            let track = try SVTrack(asset: asset, track: audioTrack)
            XCTAssertNotNil(track.pcmDatas)
            XCTAssertGreaterThan(track.pcmDatas.count, 0)
        }catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        
    }
    func testDownsamplingRealPCMData() {
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        let asset = AVURLAsset(url: URL(fileURLWithPath:mediaPath!))
        let audioTrack = asset.tracks(withMediaType: .audio)[0]
        do {
            let track = try SVTrack(asset: asset, track: audioTrack)
            self.measure {
                let downsampleArray = track.downsampleData(length: 320)
                XCTAssertNotNil(downsampleArray)
                XCTAssertEqual(320, downsampleArray.count)
            }
        }catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        
    }
    func testDownsampling1HourSoundA() {
        let track = SVTrack()
        track.pcmDatas = [Float](repeating:1.0, count: 44100 * 60 * 60)
        track.maxLength = 1.0
        self.measure {
            let downsampleArray = track.downsampleData(length: 10)
            XCTAssertNotNil(downsampleArray)
            XCTAssertEqual(10, downsampleArray.count)
            
            // vDSP_desamp doesn't calculate accurately
            XCTAssertTrue(0.1 > fabs(downsampleArray.first! - 1.0)) // expect 1.0
            XCTAssertTrue(0.1 > fabs(downsampleArray.last! - 1.0)) // expect 1.0
        }
        
    }
    func testDownsampling1HourSoundB() {
        let track = SVTrack()
        track.pcmDatas = [Float](repeating:1.0, count: 44100 * 60 * 30)
        track.pcmDatas += [Float](repeating:-1.0, count: 44100 * 60 * 30)
        track.maxLength = 1.0
        self.measure {
            let floatArray = track.downsampleData(length: 20)
            XCTAssertNotNil(floatArray)
            XCTAssertEqual(20, floatArray.count)
            XCTAssertTrue(0.1 > fabs(floatArray.first! - 1.0)) // expect 1.0
            XCTAssertTrue(0.1 > fabs(floatArray[9] - 1.0)) // expect 1.0
            XCTAssertTrue(0.1 > fabs(floatArray[10] + 1.0)) // expect -1.0
            XCTAssertTrue(0.1 > fabs(floatArray.last! + 1.0)) // expect -1.0
        }
    }
    
}

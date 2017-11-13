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
//    func testGeneratingMultitackMedia() {
//        let composition = AVMutableComposition()
//        let onNextExpectation = expectation(description: "onNextExpectation")
//
//        let mediaNames = [("1","m4a"),
//                          ("2","m4a"),
//                          ("3","m4a"),
//                          ("4","m4a"),
//                          ("5","MP4"),
//                          ("6","MP4"),
//                          ("7","MOV"),
//                          ("8","MOV"),
//                          ("9","MOV"),
//                          ("10","MOV"),
//                          ("11","MOV"),
//                          ("12","MOV"),
//                          ("13","MP4"),]
//        for mediaName in mediaNames {
//            let filePath = Bundle(for: type(of: self)).path(forResource: mediaName.0, ofType: mediaName.1)!
//            let asset = AVURLAsset(url: URL(fileURLWithPath: filePath))
//            let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
//            do {
//                try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration),
//                                          of: asset.tracks(withMediaType: .audio)[0], at: kCMTimeZero)
//            }catch {
//                XCTFail(error.localizedDescription)
//            }
//
//        }
//        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
//        exportSession.outputURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]).appendingPathComponent("export.mov")
//        exportSession.outputFileType = AVFileType.mov
//        exportSession.shouldOptimizeForNetworkUse = false
//        exportSession.exportAsynchronously {
//
//            let exportAsset = AVURLAsset(url: exportSession.outputURL!)
//            XCTAssertEqual(exportAsset.tracks(withMediaType: .audio).count, mediaNames.count)
//            onNextExpectation.fulfill()
//        }
//
//        self.waitForExpectations(timeout: 10) { (error) in
//            guard nil == error else {
//                XCTFail((error?.localizedDescription)!)
//                return
//            }
//
//        }
//
//    }

    
}

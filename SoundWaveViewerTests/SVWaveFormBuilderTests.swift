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
        self.continueAfterFailure = false
    }
    
    override func tearDown() {
        super.tearDown()
    }
    func testBuildPCMData() {
        
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        let asset = AVURLAsset(url: URL(fileURLWithPath:mediaPath!))
        let audioTrack = asset.tracks(withMediaType: .audio)[0]
        do {
            let pcmData = try SVWaveFormBuilder.buildPCMData(asset: asset, track: audioTrack)
            XCTAssertNotNil(pcmData)
            XCTAssertGreaterThan(pcmData!.count, 0)
        }catch {
            XCTFail(error.localizedDescription)
        }
        
        
    }
    func testDownsamplingRealPCMData() {
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        let asset = AVURLAsset(url: URL(fileURLWithPath:mediaPath!))
        let audioTrack = asset.tracks(withMediaType: .audio)[0]
        do {
            let pcmData = try SVWaveFormBuilder.buildPCMData(asset: asset, track: audioTrack)
            self.measure {
                let downsampleArray = SVWaveFormBuilder.downsamplePCMDatas(pcmDatas: pcmData!, targetDownsampleLength: 320)
                XCTAssertNotNil(downsampleArray)
                XCTAssertEqual(320, downsampleArray!.count)
            }
        }catch {
            XCTFail(error.localizedDescription)
        }
        
        
    }
    func testDownsampling1HourSoundA() {
        let floatArray = [Float](repeating:1.0, count: 44100 * 60 * 60)
        self.measure {
            let downsampleArray = SVWaveFormBuilder.downsamplePCMDatas(pcmDatas: floatArray, targetDownsampleLength: 10)
            XCTAssertNotNil(downsampleArray)
            XCTAssertEqual(10, downsampleArray!.count)
            
            // vDSP_desamp doesn't calculate accurately
            XCTAssertTrue(0.1 > fabs(downsampleArray!.first! - 1.0)) // expect 1.0
            XCTAssertTrue(0.1 > fabs(downsampleArray!.last! - 1.0)) // expect 1.0
        }
        
    }
    func testDownsampling1HourSoundB() {
        var dataArray = [Float](repeating:1.0, count: 44100 * 60 * 30)
        dataArray += [Float](repeating:-1.0, count: 44100 * 60 * 30)
        self.measure {
            let floatArray = SVWaveFormBuilder.downsamplePCMDatas(pcmDatas: dataArray, targetDownsampleLength: 20)
            XCTAssertNotNil(floatArray)
            XCTAssertEqual(20, floatArray!.count)
            XCTAssertTrue(0.1 > fabs(floatArray!.first! - 1.0)) // expect 1.0
            XCTAssertTrue(0.1 > fabs(floatArray![9] - 1.0)) // expect 1.0
            XCTAssertTrue(0.1 > fabs(floatArray![10] + 1.0)) // expect -1.0
            XCTAssertTrue(0.1 > fabs(floatArray!.last! + 1.0)) // expect -1.0
        }
    }
    func testGeneratingWaveformThumbnail() {
        
        let onNextExpectation = expectation(description: "onNextExpectation")
        
        var dataArray = [Float](repeating:1.0, count: 44100 * 60 * 30)
        dataArray += [Float](repeating:-1.0, count: 44100 * 60 * 30)
        let waveform = SVTrack()
        waveform.pcmDatas = dataArray
        let expectImageSize = CGSize(width: 100, height: 120)
        let task = waveform.thumbnail(size: expectImageSize) { (image, error) in
            XCTAssertNotNil(image)
            XCTAssertEqual(expectImageSize, image!.size)
            XCTAssertNil(error)
            onNextExpectation.fulfill()
        }
        XCTAssertNotNil(task)
        task!.start()
        
        self.waitForExpectations(timeout: 3) { (error) in
            guard nil == error else {
                XCTFail((error?.localizedDescription)!)
                return
            }
        }

    }
    
}

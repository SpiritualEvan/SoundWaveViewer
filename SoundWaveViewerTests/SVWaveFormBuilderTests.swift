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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
    func testBuildWaveFormFromFile() {
        
        // test for multi track audios
        let onNextExpectation = expectation(description: "onNextExpectation")
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        SVWaveFormBuilder.buildWaveform(mediaURL: URL(fileURLWithPath:mediaPath!), briefWaveformWidth:320) { (waveform, error) in
            XCTAssertNotNil(waveform)
            XCTAssertNil(error)
            XCTAssertNotNil(waveform!.pcmDatas)
            XCTAssertTrue(0 < waveform!.pcmDatas.count)
            onNextExpectation.fulfill()
        }
    
        self.waitForExpectations(timeout: 10) { (error) in
            guard nil == error else {
                XCTFail((error?.localizedDescription)!)
                return
            }
        }
    }
    func testBuildWaveFormFromAVAssetTrack() {
        
        // test for multi track audios
        let onNextExpectation = expectation(description: "onNextExpectation")
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        let asset = AVURLAsset(url: URL(fileURLWithPath:mediaPath!))
        let audioTrack = asset.tracks(withMediaType: .audio)[0]
        SVWaveFormBuilder.buildWaveform(asset:asset, track: audioTrack, briefWaveformWidth: 320) { (waveformFromTrack, error) in
            XCTAssertNotNil(waveformFromTrack)
            XCTAssertNil(error)
            XCTAssertNotNil(waveformFromTrack!.pcmDatas)
            XCTAssertTrue(0 < waveformFromTrack!.pcmDatas.count)
            onNextExpectation.fulfill()
        }
        
        
        
        self.waitForExpectations(timeout: 100) { (error) in
            guard nil == error else {
                XCTFail((error?.localizedDescription)!)
                return
            }
        }
    }
    func testDownsampling1HourSoundA() {
        let floatArray = [Float32](repeating:1.0, count: 44100 * 60 * 60)
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
        var dataArray = [Float32](repeating:1.0, count: 44100 * 60 * 30)
        dataArray += [Float32](repeating:-1.0, count: 44100 * 60 * 30)
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
        
        var dataArray = [Float32](repeating:1.0, count: 44100 * 60 * 30)
        dataArray += [Float32](repeating:-1.0, count: 44100 * 60 * 30)
        var waveform = SVWaveForm()
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

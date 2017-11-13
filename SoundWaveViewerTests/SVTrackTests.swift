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
        track.waveformData = [WaveformMinMax](repeating:(0.0, 0.0), count:10000)
        XCTAssertEqual(track.numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription(size: CGSize(width: 100, height: 100), indexOfSegment: 0)), 10)
        XCTAssertEqual(track.numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription(size: CGSize(width: 100, height: 100), indexOfSegment: 0)), 10)
        XCTAssertEqual(track.numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription(size: CGSize(width: 3, height: 100), indexOfSegment: 0)), 371)
        
    }
    func testBuildPCMData() {
        
        // test for multi track audios
        let mediaPath = Bundle(for: type(of: self)).path(forResource: "1", ofType: "m4a")
        let asset = AVURLAsset(url: URL(fileURLWithPath:mediaPath!))
        let audioTrack = asset.tracks(withMediaType: .audio)[0]
        do {
            let track = try SVTrack(asset: asset, track: audioTrack)
            XCTAssertNotNil(track.waveformData)
            XCTAssertGreaterThan(track.waveformData.count, 0)
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
                let reducedWaveformData = track.reducedWavedata(width: 320)
                XCTAssertNotNil(reducedWaveformData)
                XCTAssertEqual(320, reducedWaveformData.count)
            }
        }catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        
    }
    func testDownsampling1HourSoundA() {
        let track = SVTrack()
        track.waveformData = [WaveformMinMax](repeating:(1.0, 1.0), count: 99999)
        self.measure {
            let reducedWaveformData = track.reducedWavedata(width: 10)
            XCTAssertNotNil(reducedWaveformData)
            XCTAssertEqual(reducedWaveformData.count, 11)
            XCTAssertEqual(reducedWaveformData.first!.0, 0.0)
            XCTAssertEqual(reducedWaveformData.last!.1, 1.0)
        }
        
    }
    func testDownsampling1HourSoundB() {
        let track = SVTrack()
        track.waveformData = [WaveformMinMax](repeating:(-1.0, 1.0), count: 10000)
        track.waveformData += [WaveformMinMax](repeating:(-1.0, 1.0), count: 10000)
        self.measure {
            let floatArray = track.reducedWavedata(width: 20)
            XCTAssertNotNil(floatArray)
            XCTAssertEqual(20, floatArray.count)
            XCTAssertEqual(floatArray.first!.0, -1.0)
            XCTAssertEqual(floatArray[9].0, -1.0)
            XCTAssertEqual(floatArray[10].0, -1.0)
            XCTAssertEqual(floatArray.last!.1, 1.0)
        }
    }
    func testConvertPCMToWaveform() {
        
        let pcmData = [Float](repeating:1.0, count: 1024)
        let wavedata = SVTrack.convertToWaveform(pcmData: pcmData, samplePerWave: SVTrack.SamplePerWave512)
        XCTAssertEqual(wavedata.count, 2)
        XCTAssertEqual(wavedata[0].0, 1.0)
        XCTAssertEqual(wavedata[0].1, 1.0)
        
        var pcmData2 = [Float](repeating:1.0, count: 256)
        pcmData2 += [Float](repeating:-1.0, count: 256)
        pcmData2 += [Float](repeating:-1.0, count: 513)
        let wavedata2 = SVTrack.convertToWaveform(pcmData: pcmData2, samplePerWave: SVTrack.SamplePerWave512)
        XCTAssertEqual(wavedata2.count, 3)
        XCTAssertEqual(wavedata2[0].0, -1.0)
        XCTAssertEqual(wavedata2[0].1, 1.0)

    }
}

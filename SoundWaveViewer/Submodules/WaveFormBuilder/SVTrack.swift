//
//  SVWaveFormBuilder.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 9..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

enum SVWaveFormError:Error {
    case failedToReadAudioFile(url:URL)
    case failedToCreateContextWhileCreatingWaveformThumbnail
    case failedReadingAudioTrack(readerStaus:AVAssetReaderStatus)
    case failedToGetCMSampleBufferGetDataBuffer
    case failedToGetStreamBasicDescription
}

typealias WaveformMinMax = (Float, Float)

struct SVWaveformSegmentDescription {
    let size:CGSize
    let indexOfSegment:Int
}

class SVTrack {
    
    static let SamplePerWave512:Int = 512
    
    var asset:AVAsset!
    var assetTrack:AVAssetTrack!
    var waveformData = [WaveformMinMax]()
    private var thumbnail:UIImage?
    
    init() {}
    
    init(asset:AVAsset!, track:AVAssetTrack!) throws {
        
        self.waveformData = [WaveformMinMax]()
        guard let basicDesc = CMAudioFormatDescriptionGetStreamBasicDescription(track!.formatDescriptions[0] as! CMAudioFormatDescription) else {
            throw SVWaveFormError.failedToGetStreamBasicDescription
        }
        let basicDescObj = basicDesc.pointee
        let outputSettings:[String:Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                                           AVSampleRateKey: basicDescObj.mSampleRate,
                                           AVNumberOfChannelsKey: basicDescObj.mChannelsPerFrame,
                                           AVLinearPCMBitDepthKey:32,
                                           AVLinearPCMIsBigEndianKey:false,
                                           AVLinearPCMIsFloatKey:true,
                                           AVLinearPCMIsNonInterleaved: true]
        
        let reader = try AVAssetReader(asset: asset)
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(trackOutput)
        reader.startReading()
        
        while AVAssetReaderStatus.completed != reader.status {
            switch reader.status {
            case .reading:
                if let nextSampleBuffer = trackOutput.copyNextSampleBuffer() {
                    if let pcmBlock = CMSampleBufferGetDataBuffer(nextSampleBuffer) {
                        let pcmBlockSize = CMBlockBufferGetDataLength(pcmBlock)
                        let pcmBlockArray = [Float](repeating:0.0, count:pcmBlockSize/4)
                        let blockPointer = UnsafeMutablePointer(mutating:pcmBlockArray)
                        CMBlockBufferCopyDataBytes(pcmBlock, 0, pcmBlockSize, blockPointer)
                        let wavedata = SVTrack.convertToWaveform(pcmData: pcmBlockArray,
                                                                 samplePerWave:SVTrack.SamplePerWave512)
                        self.waveformData.append(contentsOf: wavedata)
                    }else {
                        throw SVWaveFormError.failedToGetCMSampleBufferGetDataBuffer
                    }
                }
                break
            case .cancelled, .unknown, .failed:
                throw SVWaveFormError.failedReadingAudioTrack(readerStaus: reader.status)
            case .completed:
                break
            }
            
        }
        
    }
    class func convertToWaveform(pcmData:[Float], samplePerWave:Int) -> [WaveformMinMax] {
        let pcmSegments = stride(from: 0, to: pcmData.count, by: samplePerWave).map {
            [Float](pcmData[$0 ..< Swift.min($0 + samplePerWave, pcmData.count)])
        }
        var max:Float = 0.0
        var min:Float = 0.0
        let waveformData = pcmSegments.map { (pcmSegment) -> (WaveformMinMax) in
            vDSP_maxv(pcmSegment, 1, &max, vDSP_Length(pcmSegment.count))
            vDSP_minv(pcmSegment, 1, &min, vDSP_Length(pcmSegment.count))
            return (min, max)
        }
        return waveformData
    }
    func numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription) -> Int {
        let numberOfSegment = Float(waveformData.count) / Float(segmentDescription.size.width)
        return Int(fabs(numberOfSegment) < numberOfSegment ? numberOfSegment + 1 : numberOfSegment)
    }
    func requestWaveformSegmentImage(segmentDescription: SVWaveformSegmentDescription,
                       completion:@escaping ((_ image:UIImage?, _ error:Error?) -> Void )) -> Operation {
        return BlockOperation { [weak self] in
            
            guard nil != self else {
                return
            }
            guard let strongSelf = self else {
                return
            }
            
            do {
                strongSelf.thumbnail = try SVWaveformDrawer.waveformImage(waveform: strongSelf.waveformData, imageSize: segmentDescription.size)
            }catch {
                completion(nil, error)
                return
            }
            
            DispatchQueue.main.async {
                completion(strongSelf.thumbnail, nil)
            }
            
            
        }
        
    }
    func requestThumbnail(size:CGSize, completion:@escaping((_ image:UIImage?, _ error:Error?) -> Void)) -> Operation! {
        
        return BlockOperation { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            guard nil == strongSelf.thumbnail else {
                DispatchQueue.main.async {
                    completion(strongSelf.thumbnail!, nil)
                }
                return
            }
            let reducedWaveformData = strongSelf.reducedWavedata(width: Int(size.width))
            
            do {
                strongSelf.thumbnail = try SVWaveformDrawer.waveformImage(waveform: reducedWaveformData, imageSize: size)
            }catch {
                completion(nil, error)
                return
            }
            DispatchQueue.main.async {
                completion(strongSelf.thumbnail, nil)
            }
        }
    }
    func reducedWavedata(width:Int) -> [WaveformMinMax] {
        let wavePerSegment = Int(waveformData.count / width) > 0 ? Int(waveformData.count / width) : 1
        let reducedWaveformData = stride(from: 0, to: waveformData.count, by: wavePerSegment).map { (index) -> WaveformMinMax in
            let waveformDatas = [WaveformMinMax](self.waveformData[index ..< Swift.min(index + wavePerSegment, self.waveformData.count)])
            return waveformDatas.reduce((0.0, 0.0)) { (Swift.min($0.0, $1.0), Swift.max($0.1, $1.1))}
        }
        return reducedWaveformData
    }
}

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
    case failedToCreatePCMFormatObject
    case failedToAllocatePCMBufferObject
    case cannotFoundFloatDataFromPCMBuffer
    case failedToCreateDownsamplePCMData
    case failedToCreateContextWhileCreatingWaveformThumbnail
    case failedReadingAudioTrack(readerStaus:AVAssetReaderStatus)
    case failedToGetCMSampleBufferGetDataBuffer
    case failedToGetStreamBasicDescription
}

struct SVWaveformSegmentDescription {
    let imageSize:CGSize
    let indexOfSegment:Int
    let samplesPerPixel:Int
}

class SVTrack {
    
    var asset:AVAsset!
    var assetTrack:AVAssetTrack!
    var pcmDatas = [Float]()
    var maxLength:Float = 0.0
    private var thumbnail:UIImage?
    
    init() {}
    init(asset:AVAsset!, track:AVAssetTrack!) throws {
        self.pcmDatas = [Float]()
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
                        self.pcmDatas.append(contentsOf: pcmBlockArray)
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
        
        
        var maxPCMData:Float = 0.0
        var minPCMData:Float = 0.0
        vDSP_maxv(pcmDatas, 1, &maxPCMData, vDSP_Length(pcmDatas.count))
        vDSP_minv(pcmDatas, 1, &minPCMData, vDSP_Length(pcmDatas.count))
        self.maxLength = fabs(minPCMData) > maxPCMData ? fabs(minPCMData) : maxPCMData
    }
    
    func numberOfWaveformSegments(segmentDescription: SVWaveformSegmentDescription) -> Int {
        var totalWidth = Double(pcmDatas.count) / Double(segmentDescription.samplesPerPixel)
        if totalWidth > floor(totalWidth) {
            totalWidth = floor(totalWidth) + 1
        }
        var numberOfSegment = totalWidth / Double(segmentDescription.imageSize.width)
        if numberOfSegment > floor(numberOfSegment) {
            numberOfSegment = floor(numberOfSegment) + 1
        }
        return Int(numberOfSegment)
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
            
            let samplePerSegment = Int(segmentDescription.imageSize.width) * segmentDescription.samplesPerPixel
            let fromIndex = samplePerSegment * segmentDescription.indexOfSegment
            let toIndex = fromIndex + samplePerSegment
            
            var segmentLength = samplePerSegment
            if toIndex > strongSelf.pcmDatas.count {
                segmentLength = strongSelf.pcmDatas.count - fromIndex
            }
            
            let downsampleData = strongSelf.downsampleData(range: NSMakeRange(fromIndex, segmentLength), downsampleLength: Int(segmentDescription.imageSize.width))
            
            do {
                strongSelf.thumbnail = try SVWaveformDrawer.waveformImage(waveform: downsampleData, imageSize: segmentDescription.imageSize)
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
            let downsampledPCMDatas = strongSelf.downsampleData(length: Int(size.width))
            
            do {
                strongSelf.thumbnail = try SVWaveformDrawer.waveformImage(waveform: downsampledPCMDatas, imageSize: size)
            }catch {
                completion(nil, error)
                return
            }
            DispatchQueue.main.async {
                completion(strongSelf.thumbnail, nil)
            }
        }
    }
    
    
    func downsampleData(range:NSRange, downsampleLength:Int) -> [Float] {
        let partialSample = [Float](pcmDatas[range.location ..< (range.location + range.length)])
        let stride = Int(partialSample.count / downsampleLength)
        let filter = [Float](repeating:1.0 / Float(stride), count: stride)
        var downsampleBuffer = [Float](repeating: 0.0, count: downsampleLength)
        vDSP_desamp(partialSample, vDSP_Stride(stride), filter, &downsampleBuffer, vDSP_Length(downsampleLength), vDSP_Length(stride))

        vDSP_vsdiv(downsampleBuffer, 1, &maxLength, &downsampleBuffer, 1, vDSP_Length(downsampleLength))
        return downsampleBuffer

    }
    func downsampleData(length:Int) -> [Float] {
        
        let stride = Int(pcmDatas.count / length)
        let filter = [Float](repeating:1.0 / Float(stride), count: stride)
        var downsampleBuffer = [Float](repeating: 0.0, count: length)
        vDSP_desamp(self.pcmDatas, vDSP_Stride(stride), filter, &downsampleBuffer, vDSP_Length(length), vDSP_Length(stride))
        
        var maxPCMData:Float = 0.0
        var minPCMData:Float = 0.0
        vDSP_maxv(downsampleBuffer, 1, &maxPCMData, vDSP_Length(downsampleBuffer.count))
        vDSP_minv(downsampleBuffer, 1, &minPCMData, vDSP_Length(downsampleBuffer.count))
        var maxLength = fabs(minPCMData) > maxPCMData ? fabs(minPCMData) : maxPCMData
        
        vDSP_vsdiv(downsampleBuffer, 1, &maxLength, &downsampleBuffer, 1, vDSP_Length(length))
        
        return downsampleBuffer
        
    }
}

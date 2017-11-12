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
    var pcmDatas:[Float]!
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
    func waveformImage(segmentDescription: SVWaveformSegmentDescription,
                       completion:@escaping ((_ image:UIImage?, _ error:Error?) -> Void )) -> Operation {
        return BlockOperation { [weak self] in
            
            guard nil != self else {
                return
            }
            
            let samplePerSegment = Int(segmentDescription.imageSize.width) * segmentDescription.samplesPerPixel
            let fromIndex = samplePerSegment * segmentDescription.indexOfSegment
            var toIndex = fromIndex + samplePerSegment
            if toIndex > self!.pcmDatas.count {
                toIndex = self!.pcmDatas.count
            }
            let samplesForSegment = [Float](self!.pcmDatas[fromIndex ..< toIndex])
            let downsampleData = SVTrack.downsamplePCMDatas(pcmDatas: samplesForSegment, targetDownsampleLength: Int(segmentDescription.imageSize.width), maxLength: self!.maxLength)
            
            UIGraphicsBeginImageContextWithOptions(segmentDescription.imageSize, false, UIScreen.main.scale)
            guard let context = UIGraphicsGetCurrentContext() else {
                DispatchQueue.main.async {
                    completion(nil, SVWaveFormError.failedToCreateContextWhileCreatingWaveformThumbnail)
                }
                return
            }
            context.setAlpha(1.0)
            context.setLineWidth(0.5)
            let path = CGMutablePath()
            
            let centerY:CGFloat = segmentDescription.imageSize.height / 2.0
            let maxLength:CGFloat = segmentDescription.imageSize.height / 2.0
            
            path.move(to: CGPoint(x: 0, y: centerY))
            for (x, sample) in downsampleData.enumerated() {
                let nextPoint = CGPoint(x: CGFloat(x), y: centerY + (maxLength * CGFloat(sample)))
                path.addLine(to: nextPoint)
                path.move(to: nextPoint)
            }
            context.addPath(path)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.strokePath()
            
            let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self!.thumbnail = thumbnailImage
            DispatchQueue.main.async {
                completion(thumbnailImage, nil)
            }
            
            
        }
        
    }
    func thumbnail(size:CGSize, completion:@escaping((_ image:UIImage?, _ error:Error?) -> Void)) -> Operation! {
        
        return BlockOperation { [weak self] in
            
            guard nil != self else {
                return
            }
            
            guard nil == self!.thumbnail else {
                DispatchQueue.main.async {
                    completion(self!.thumbnail!, nil)
                }
                return
            }
            
            let downsampledPCMDatas = self!.downsamplePCMDatas(targetDownsampleLength: Int(size.width * 2))
            
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            guard let context = UIGraphicsGetCurrentContext() else {
                DispatchQueue.main.async {
                    completion(nil, SVWaveFormError.failedToCreateContextWhileCreatingWaveformThumbnail)
                }
                return
            }
            context.setAlpha(1.0)
            context.setLineWidth(0.5)
            let path = CGMutablePath()
            
            let centerY:CGFloat = size.height / 2.0
            let maxLength:CGFloat = size.height / 2.0
            
            path.move(to: CGPoint(x: 0, y: centerY))
            for (x, sample) in downsampledPCMDatas.enumerated() {
                let nextPoint = CGPoint(x: CGFloat(x), y: centerY + (maxLength * CGFloat(sample)))
                path.addLine(to: nextPoint)
                path.move(to: nextPoint)
            }
            context.addPath(path)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.strokePath()
            
            let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self!.thumbnail = thumbnailImage
            DispatchQueue.main.async {
                completion(thumbnailImage, nil)
            }
        }
    }
    class func downsamplePCMDatas(pcmDatas:[Float], targetDownsampleLength:Int, maxLength:Float) -> [Float] {

        let stride = Int(pcmDatas.count / targetDownsampleLength)
        let filter = [Float](repeating:1.0 / Float(stride), count: stride)
        var downsampleBuffer = [Float](repeating: 0.0, count: targetDownsampleLength)
        vDSP_desamp(pcmDatas, vDSP_Stride(stride), filter, &downsampleBuffer, vDSP_Length(targetDownsampleLength), vDSP_Length(stride))

        var maxLength = maxLength
        vDSP_vsdiv(downsampleBuffer, 1, &maxLength, &downsampleBuffer, 1, vDSP_Length(targetDownsampleLength))
        return downsampleBuffer

    }
    func downsamplePCMDatas(targetDownsampleLength:Int) -> [Float] {
        
        let stride = Int(pcmDatas.count / targetDownsampleLength)
        let filter = [Float](repeating:1.0 / Float(stride), count: stride)
        var downsampleBuffer = [Float](repeating: 0.0, count: targetDownsampleLength)
        vDSP_desamp(self.pcmDatas, vDSP_Stride(stride), filter, &downsampleBuffer, vDSP_Length(targetDownsampleLength), vDSP_Length(stride))
        
        vDSP_vsdiv(downsampleBuffer, 1, &self.maxLength, &downsampleBuffer, 1, vDSP_Length(targetDownsampleLength))
        return downsampleBuffer
        
    }
}

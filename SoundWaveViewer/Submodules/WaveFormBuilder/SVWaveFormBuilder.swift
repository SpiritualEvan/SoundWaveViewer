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

class SVTrack {
    
    var asset:AVAsset!
    var assetTrack:AVAssetTrack!
    var pcmDatas:[Float]!
    private var thumbnail:UIImage?
    
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
            
            guard let downsampledPCMDatas = SVWaveFormBuilder.downsamplePCMDatas(pcmDatas: self!.pcmDatas, targetDownsampleLength: Int(size.width)) else {
                DispatchQueue.main.async {
                    completion(nil, SVWaveFormError.failedToCreateDownsamplePCMData)
                }
                return
            }
            
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            guard let context = UIGraphicsGetCurrentContext() else {
                DispatchQueue.main.async {
                    completion(nil, SVWaveFormError.failedToCreateContextWhileCreatingWaveformThumbnail)
                }
                return
            }
            context.setAlpha(1.0)
            context.setFillColor(UIColor.yellow.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
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
}

final class SVWaveFormBuilder {
    class func buildPCMData(asset:AVAsset!, track:AVAssetTrack!) throws -> [Float]? {
        var pcmDatas = [Float32]()
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
                        let pcmBlockArray = [Float32](repeating:0.0, count:pcmBlockSize/4)
                        let blockPointer = UnsafeMutablePointer(mutating:pcmBlockArray)
                        CMBlockBufferCopyDataBytes(pcmBlock, 0, pcmBlockSize, blockPointer)
                        pcmDatas.append(contentsOf: pcmBlockArray)
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
        return pcmDatas.map{Float($0)}
    }
//    class func buildWaveform(asset:AVAsset!, track:AVAssetTrack!, briefWaveformWidth:Int, completion:@escaping((_ waveform:SVTrack?, _ error:Error?) -> Void)) {
//        
//        DispatchQueue.global().async {
//            var waveform = SVTrack()
//            waveform.asset = asset
//            waveform.assetTrack = track
//            waveform.pcmDatas = [Float]()
//            do {
//                guard let basicDesc = CMAudioFormatDescriptionGetStreamBasicDescription(track!.formatDescriptions[0] as! CMAudioFormatDescription) else {
//                    DispatchQueue.main.async {
//                        completion(nil, SVWaveFormError.failedToGetStreamBasicDescription)
//                    }
//                    return
//                }
//                let basicDescObj = basicDesc.pointee
//                let outputSettings:[String:Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
//                                                   AVSampleRateKey: basicDescObj.mSampleRate,
//                                                   AVNumberOfChannelsKey: basicDescObj.mChannelsPerFrame,
//                                                   AVLinearPCMBitDepthKey:32,
//                                                   AVLinearPCMIsBigEndianKey:false,
//                                                   AVLinearPCMIsFloatKey:true,
//                                                   AVLinearPCMIsNonInterleaved: true]
//                
//                let reader = try AVAssetReader(asset: asset)
//                let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
//                reader.add(trackOutput)
//                reader.startReading()
//                
//                
//                while AVAssetReaderStatus.completed != reader.status {
//                    switch reader.status {
//                    case .reading:
//                        if let nextSampleBuffer = trackOutput.copyNextSampleBuffer() {
//                            if let pcmBlock = CMSampleBufferGetDataBuffer(nextSampleBuffer) {
//                                let pcmBlockSize = CMBlockBufferGetDataLength(pcmBlock)
//                                let pcmBlockArray = [Float32](repeating:0.0, count:pcmBlockSize/4)
//                                let blockPointer = UnsafeMutablePointer(mutating:pcmBlockArray)
//                                CMBlockBufferCopyDataBytes(pcmBlock, 0, pcmBlockSize, blockPointer)
//                                waveform.pcmDatas.append(contentsOf: pcmBlockArray)
//                            }else {
//                                DispatchQueue.main.async {
//                                    completion(nil, SVWaveFormError.failedToGetCMSampleBufferGetDataBuffer)
//                                }
//                                
//                                return
//                            }
//                        }
//                        break
//                    case .cancelled, .unknown, .failed:
//                        DispatchQueue.main.async {
//                            completion(nil, SVWaveFormError.failedReadingAudioTrack(readerStaus: reader.status))
//                        }
//                        return
//                    case .completed:
//                        break
//                    }
//                    
//                }
//            } catch {
//                completion(nil, error)
//            }
//            
//            DispatchQueue.main.async {
//                completion(waveform, nil)
//            }
//        }
//        
//        
//    }
//    class func buildWaveform(mediaURL:URL!, briefWaveformWidth:Int, completion:@escaping((_ waveform:SVTrack?, _ error:Error?) -> Void)) {
//        
//        DispatchQueue.global().async {
//            var file:AVAudioFile!
//            do {
//                
//                file = try AVAudioFile(forReading: mediaURL)
//            } catch {
//                completion(nil, error)
//            }
//            guard nil != file else {
//                completion(nil, SVWaveFormError.failedToReadAudioFile(url: mediaURL))
//                return
//            }
//            
//            guard let pcmFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false) else {
//                completion(nil, SVWaveFormError.failedToCreatePCMFormatObject)
//                return
//            }
//            
//            guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: UInt32(file.length)) else {
//                completion(nil, SVWaveFormError.failedToAllocatePCMBufferObject)
//                return
//            }
//            do {
//                try file.read(into: pcmBuffer)
//            } catch {
//                completion(nil, error)
//            }
//            
//            guard let floatChannelData = pcmBuffer.floatChannelData else {
//                completion(nil, SVWaveFormError.cannotFoundFloatDataFromPCMBuffer)
//                return
//            }
//            var waveform = SVTrack()
//            waveform.pcmDatas = Array(UnsafeBufferPointer(start: floatChannelData[0], count:Int(pcmBuffer.frameLength)))
//            DispatchQueue.main.async {
//                completion(waveform, nil)
//            }
//        }
//        
//        
//    }
    class func downsamplePCMDatas(pcmDatas:[Float], targetDownsampleLength:Int) -> [Float]! {
        
        let stride = Int(pcmDatas.count / targetDownsampleLength)
        let filter = [Float](repeating:1.0 / Float(stride), count: stride)
        var downsampleBuffer = [Float](repeating: 0.0, count: targetDownsampleLength)
        vDSP_desamp(pcmDatas, vDSP_Stride(stride), filter, &downsampleBuffer, vDSP_Length(targetDownsampleLength), vDSP_Length(stride))
        
        var foundedMax:Float = 0.0
        var foundedMin:Float = 0.0
        vDSP_maxv(downsampleBuffer, 1, &foundedMax, vDSP_Length(downsampleBuffer.count))
        vDSP_minv(downsampleBuffer, 1, &foundedMin, vDSP_Length(downsampleBuffer.count))
        
        var maxLength = fabs(foundedMin) > foundedMax ? foundedMin : foundedMax
        vDSP_vsdiv(downsampleBuffer, 1, &maxLength, &downsampleBuffer, 1, vDSP_Length(targetDownsampleLength))
        return downsampleBuffer
        
    }
    
}

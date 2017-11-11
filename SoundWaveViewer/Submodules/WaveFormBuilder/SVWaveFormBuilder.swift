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

struct SVWaveForm {
    
    var pcmDatas:[Float32]!
    var downsampledPCMDatas:[Float32]?
    private var thumbnail:UIImage?
    
    func thumbnail(size:CGSize, completion:@escaping((_ image:UIImage?, _ error:Error?) -> Void)) -> BlockOperation! {
        
        return BlockOperation {
            var waveform = self
            guard nil == waveform.thumbnail else {
                DispatchQueue.main.async {
                    completion(waveform.thumbnail!, nil)
                }
                return
            }
            
            guard let downsampledPCMDatas = SVWaveFormBuilder.downsamplePCMDatas(pcmDatas: waveform.pcmDatas, targetDownsampleLength: Int(size.width)) else {
                completion(nil, SVWaveFormError.failedToCreateDownsamplePCMData)
                return
            }
            
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            guard let context = UIGraphicsGetCurrentContext() else {
                completion(nil, SVWaveFormError.failedToCreateContextWhileCreatingWaveformThumbnail)
                return
            }
            
            let path = CGMutablePath()
            
            let centerY:CGFloat = size.height / 2.0
            let maxLength:CGFloat = size.height / 2.0
            
            path.move(to: CGPoint(x: 0, y: centerY))
            for (x, sample) in downsampledPCMDatas.enumerated() {
                path.addLine(to: CGPoint(x: CGFloat(x), y: centerY + (maxLength * CGFloat(sample))))
            }
            context.addPath(path)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.strokePath()
            
            let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            waveform.downsampledPCMDatas = downsampledPCMDatas
            waveform.thumbnail = thumbnailImage
            DispatchQueue.main.async {
                completion(thumbnailImage, nil)
            }
        }
        

    }
}
final class SVWaveFormThumbnailBuilder {
    
}
final class SVWaveFormBuilder {
    
    class func buildWaveform(asset:AVAsset!, track:AVAssetTrack!, briefWaveformWidth:Int, completion:@escaping((_ waveform:SVWaveForm?, _ error:Error?) -> Void)) {
        
        DispatchQueue.global().async {
            
            let pcmDatas = [Float32](repeating:0.0, count:Int(track.totalSampleDataLength))
            
            do {
                guard let basicDesc = CMAudioFormatDescriptionGetStreamBasicDescription(track!.formatDescriptions[0] as! CMAudioFormatDescription) else {
                    completion(nil, SVWaveFormError.failedToGetStreamBasicDescription)
                    return
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
                
                var indexOfPCMData = 0
                while AVAssetReaderStatus.completed != reader.status {
                    switch reader.status {
                    case .reading:
                        if let nextSampleBuffer = trackOutput.copyNextSampleBuffer() {
                            if let pcmBlock = CMSampleBufferGetDataBuffer(nextSampleBuffer) {
                                let pcmBlockSize = CMBlockBufferGetDataLength(pcmBlock)
                                let blockPointer = UnsafeMutablePointer<Float32>(mutating: pcmDatas)
                                CMBlockBufferCopyDataBytes(pcmBlock, 0, pcmBlockSize, blockPointer.advanced(by: indexOfPCMData))
                                indexOfPCMData += pcmBlockSize / 32
                            }else {
                                completion(nil, SVWaveFormError.failedToGetCMSampleBufferGetDataBuffer)
                                return
                            }
                        }
                        
                    case .cancelled, .failed, .unknown:
                        DispatchQueue.main.async {
                            completion(nil, SVWaveFormError.failedReadingAudioTrack(readerStaus: reader.status))
                        }
                        return
                    case .completed:
                        break;
                    }
                }
            } catch {
                completion(nil, error)
            }
            var waveform = SVWaveForm()
            waveform.pcmDatas = pcmDatas
            waveform.downsampledPCMDatas = downsamplePCMDatas(pcmDatas:waveform.pcmDatas, targetDownsampleLength:briefWaveformWidth)
            DispatchQueue.main.async {
                completion(waveform, nil)
            }
        }
        
        
    }
    class func buildWaveform(mediaURL:URL!, briefWaveformWidth:Int, completion:@escaping((_ waveform:SVWaveForm?, _ error:Error?) -> Void)) {
        
        DispatchQueue.global().async {
            var file:AVAudioFile!
            do {
                
                file = try AVAudioFile(forReading: mediaURL)
            } catch {
                completion(nil, error)
            }
            guard nil != file else {
                completion(nil, SVWaveFormError.failedToReadAudioFile(url: mediaURL))
                return
            }
            
            guard let pcmFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false) else {
                completion(nil, SVWaveFormError.failedToCreatePCMFormatObject)
                return
            }
            
            guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: UInt32(file.length)) else {
                completion(nil, SVWaveFormError.failedToAllocatePCMBufferObject)
                return
            }
            do {
                try file.read(into: pcmBuffer)
            } catch {
                completion(nil, error)
            }
            
            guard let floatChannelData = pcmBuffer.floatChannelData else {
                completion(nil, SVWaveFormError.cannotFoundFloatDataFromPCMBuffer)
                return
            }
            var waveform = SVWaveForm()
            waveform.pcmDatas = Array(UnsafeBufferPointer(start: floatChannelData[0], count:Int(pcmBuffer.frameLength)))
            waveform.downsampledPCMDatas = downsamplePCMDatas(pcmDatas:waveform.pcmDatas, targetDownsampleLength:briefWaveformWidth)
            DispatchQueue.main.async {
                completion(waveform, nil)
            }
        }
        
        
    }
    class func downsamplePCMDatas(pcmDatas:[Float32], targetDownsampleLength:Int) -> [Float32]! {
        
        let stride = Int(pcmDatas.count / targetDownsampleLength)
        let filter = [Float](repeating:1.0 / Float(stride), count: stride)
        var downsampleBuffer = [Float](repeating: 0.0, count: targetDownsampleLength)
        
        vDSP_desamp(pcmDatas, vDSP_Stride(stride), filter, &downsampleBuffer, vDSP_Length(targetDownsampleLength), vDSP_Length(stride))
        return downsampleBuffer.map{Float32($0)}
        
    }
    
}

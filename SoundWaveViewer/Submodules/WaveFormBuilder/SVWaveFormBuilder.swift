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

enum SVWaveFormBuilderError:Error {
    case failedToReadAudioFile(url:URL)
    case failedToCreatePCMFormatObject
    case failedToAllocatePCMBufferObject
    case cannotFoundFloatDataFromPCMBuffer
}

struct SVWaveForm {
    
    var pcmDatas:[Float32]!
    var briefPCMDatas:[CGFloat]!
    
    private var thumbnail:UIImage?
    
    func thumbnail(size:CGSize, completion:@escaping((_ image:UIImage?, _ error:Error?) -> Void)) {
        
//        completion()
    }
}

final class SVWaveFormBuilder {
    
    class func buildWaveform(mediaURL:URL!, briefWaveformWidth:Int, completion:@escaping((_ waveform:SVWaveForm?, _ error:Error?) -> Void)) {
        
        DispatchQueue.global().async {
            var file:AVAudioFile!
            do {
                file = try AVAudioFile(forReading: mediaURL)
            } catch {
                completion(nil, error)
            }
            guard nil != file else {
                completion(nil, SVWaveFormBuilderError.failedToReadAudioFile(url: mediaURL))
                return
            }
            
            guard let pcmFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false) else {
                completion(nil, SVWaveFormBuilderError.failedToCreatePCMFormatObject)
                return
            }
            
            guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: UInt32(file.length)) else {
                completion(nil, SVWaveFormBuilderError.failedToAllocatePCMBufferObject)
                return
            }
            do {
                try file.read(into: pcmBuffer)
            } catch {
                completion(nil, error)
            }
            
            guard let floatChannelData = pcmBuffer.floatChannelData else {
                completion(nil, SVWaveFormBuilderError.cannotFoundFloatDataFromPCMBuffer)
                return
            }
            var waveform = SVWaveForm()
            waveform.pcmDatas = Array(UnsafeBufferPointer(start: floatChannelData[0], count:Int(pcmBuffer.frameLength)))
            waveform.briefPCMDatas = downsamplePCMDatas(pcmDatas:waveform.pcmDatas, targetDownsampleLength:briefWaveformWidth)
            DispatchQueue.main.async {
                completion(waveform, nil)
            }
        }
        
        
    }
    class func downsamplePCMDatas(pcmDatas:[Float32], targetDownsampleLength:Int) -> [CGFloat]! {
        
        let stride = Int(pcmDatas.count / targetDownsampleLength)
        let filter = [Float](repeating:1.0 / Float(stride), count: stride)
        var downsampleBuffer = [Float](repeating: 0.0, count: targetDownsampleLength)
        
        vDSP_desamp(pcmDatas, vDSP_Stride(stride), filter, &downsampleBuffer, vDSP_Length(targetDownsampleLength), vDSP_Length(stride))
        return downsampleBuffer.map{CGFloat($0)}
        
    }
    
}

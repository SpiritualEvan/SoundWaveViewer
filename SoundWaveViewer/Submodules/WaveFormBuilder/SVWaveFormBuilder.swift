//
//  SVWaveFormBuilder.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 9..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//
// reference
// drawing waveform in sound cloud : https://developers.soundcloud.com/blog/ios-waveform-rendering
// another blog : https://miguelsaldana.me/2017/03/13/how-to-create-a-soundcloud-like-waveform-in-swift-3/

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
    var normPCMDatas:[CGFloat]!
    var downsamNormPCMDatas:[CGFloat]!
}

final class SVWaveFormBuilder {
    
    class func  buildWaveform(mediaURL:URL!, completion:@escaping((_ waveform:SVWaveForm?, _ error:Error?) -> Void)) {
        
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
            normalizePCMDatas(pcmDatas:waveform.pcmDatas)
            DispatchQueue.main.async {
                completion(waveform, nil)
            }
        }
        
        
    }
    class func normalizePCMDatas(pcmDatas:[Float32]) -> [CGFloat]! {
        // find max with accelerate framework https://stackoverflow.com/questions/42128950/efficient-algorithm-for-maximum-value-and-its-index-in-swift-array
        var max:Float = 0.0
        var min:Float = 0.0
        var indexOfMax:vDSP_Length = vDSP_Length.max
        var indexOfMin:vDSP_Length = vDSP_Length.max
        vDSP_maxvi(pcmDatas, 1, &max, &indexOfMax, vDSP_Length(pcmDatas.count))
        vDSP_minvi(pcmDatas, 1, &min, &indexOfMin, vDSP_Length(pcmDatas.count))
        print("min \(min) max \(max)")
        return [1.1]
//        var processingBuffer = [Float](repeating: 0.0,
//                                       count: Int(readFile.arrayFloatValues.count))
//        let sampleCount = vDSP_Length(readFile.arrayFloatValues.count)
//        //print(sampleCount)
//        vDSP_vabs(readFile.arrayFloatValues, 1, &processingBuffer, 1, sampleCount);
//        // print(processingBuffer)
//
//        //THIS IS OPTIONAL
//        // convert do dB
//        //    var zero:Float = 1;
//        //    vDSP_vdbcon(floatArrPtr, 1, &zero, floatArrPtr, 1, sampleCount, 1);
//        //    //print(floatArr)
//        //
//        //    // clip to [noiseFloor, 0]
//        //    var noiseFloor:Float = -50.0
//        //    var ceil:Float = 0.0
//        //    vDSP_vclip(floatArrPtr, 1, &noiseFloor, &ceil,
//        //                   floatArrPtr, 1, sampleCount);
//        //print(floatArr)
//
//        var multiplier = 1.0
//        print(multiplier)
//        if multiplier < 1{
//            multiplier = 1.0
//
//        }
//
//        let samplesPerPixel = Int(150 * multiplier)
//        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel),
//                             count: Int(samplesPerPixel))
//        let downSampledLength = Int(readFile.arrayFloatValues.count / samplesPerPixel)
//        var downSampledData = [Float](repeating:0.0,
//                                      count:downSampledLength)
//        vDSP_desamp(processingBuffer,
//                    vDSP_Stride(samplesPerPixel),
//                    filter, &downSampledData,
//                    vDSP_Length(downSampledLength),
//                    vDSP_Length(samplesPerPixel))
//
//        // print(" DOWNSAMPLEDDATA: \(downSampledData.count)")
//
//        //convert [Float] to [CGFloat] array
//        readFile.points = downSampledData.map{CGFloat($0)}
        
    }
}

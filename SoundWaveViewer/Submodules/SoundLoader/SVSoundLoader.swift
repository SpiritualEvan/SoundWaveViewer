//
//  SVSoundLoader.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 8..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit
import AVFoundation

enum SVSoundLoaderError:Error {
    case NoAudioTracks
    
}

struct SVMedia {
    let tracks:[AVAssetTrack]!
}
class SVSoundLoader {
    class func loadMedia(mediaPath:String!, completion:((_ media:SVMedia?, _ error:Error?)->Void)) {
        let asset = AVURLAsset(url: URL(fileURLWithPath: mediaPath))
        let audioTracks = asset.tracks(withMediaType: .audio)
        let loadedMedia = SVMedia(tracks: audioTracks)
        completion(loadedMedia, nil)
    }
}

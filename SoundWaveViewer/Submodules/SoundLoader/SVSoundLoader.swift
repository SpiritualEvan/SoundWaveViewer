//
//  SVSoundLoader.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 8..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit
import AVFoundation

enum SVSoundLoaderError:CustomNSError {
    
    case UnknownError
    case NoAudioTracksFounded
    
    var localizedDescription: String {
        switch self {
        case .UnknownError: return "Unknown error"
        case .NoAudioTracksFounded: return "No Audio Tracks Founded"
        }
    }
}

struct SVMedia {
    let media:AVAsset!
    
}

final class SVSoundLoader {

    class func loadTracks(mediaURL:URL!, completion:@escaping ((_ medias:[SVMedia]?, _ error:Error?)->Void)) {
        
        DispatchQueue.global().async {
            
            let asset = AVURLAsset(url: mediaURL)
            let audioTracks = asset.tracks(withMediaType: .audio)
            guard 0 < audioTracks.count else {
                completion(nil, SVSoundLoaderError.NoAudioTracksFounded)
                return
            }
            var medias = [SVMedia]()
            for track in audioTracks {
                let composition = AVMutableComposition()
                let audioTrackComposition = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                do {
                    try audioTrackComposition.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: track, at: kCMTimeZero)
                    medias.append(SVMedia(media: composition))
                }catch {
                    completion(nil, error)
                }
            }
            
            DispatchQueue.main.async {
                completion(medias, nil)
            }
            
        }
        
    }
}

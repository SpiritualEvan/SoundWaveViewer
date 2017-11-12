//
//  SVSoundLoader.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 8..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit
import AVFoundation

enum SVTrackLoaderError:CustomNSError {
    
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
    let asset:AVAsset!
    let tracks:[SVTrack]!
}

final class SVTrackLoader {

    class func loadTracks(mediaURL:URL!, completion:@escaping ((_ media:SVMedia?, _ error:Error?)->Void)) {
        
        DispatchQueue.global().async {
            
            
            let asset = AVURLAsset(url: mediaURL)
            let audioTracks = asset.tracks(withMediaType: .audio)
            guard 0 < audioTracks.count else {
                completion(nil, SVTrackLoaderError.NoAudioTracksFounded)
                return
            }
            var tracks = [SVTrack]()
            for audioTrack in audioTracks {
                let track:SVTrack!
                do {
                    track = try SVTrack(asset: asset, track: audioTrack)
                }catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                tracks.append(track)
                
            }
            let loadedMedia = SVMedia(asset: asset, tracks: tracks)
            DispatchQueue.main.async {
                completion(loadedMedia, nil)
            }
            
        }
        
    }
}

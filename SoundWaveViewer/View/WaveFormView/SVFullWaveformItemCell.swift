//
//  SVWaveformItemCell.swift
//  SoundWaveViewer
//
//  Created by Won Cheul Seok on 2017. 11. 11..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit

final class SVFullWaveformItemCell: UICollectionViewCell {
    
    private static var waveformImageTaskQueue = OperationQueue()
    
    private var waveformImageTask:Operation?
    @IBOutlet weak var waveformImageView: UIImageView!
    
    func setup(track:SVTrack!, segmentDescription:SVWaveformSegmentDescription!) {
        
        waveformImageView.image = nil
        
        if nil != waveformImageTask {
            waveformImageTask!.cancel()
            waveformImageTask = nil
        }
        
        let waveformTask = track.requestWaveformSegmentImage(segmentDescription: segmentDescription) { [weak self] (image, error) in
            guard nil != self else {
                return
            }
            guard nil == error else {
                return
            }
            self!.waveformImageView.image = image
        }
        SVFullWaveformItemCell.waveformImageTaskQueue.addOperation(waveformTask)
    }
}

//
//  SVWaveformCell.swift
//  SoundWaveViewer
//
//  Created by Won Cheul Seok on 2017. 11. 11..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit

final class SVBriefWaveformCell: UITableViewCell {

    static var thumbnailTaskQueue:OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    
    @IBOutlet private var thumbnailView:UIImageView!
    private var thumbnailTask:Operation?
    
    func setup(waveform:SVTrack!) {
        
        if nil != thumbnailTask {
            thumbnailTask!.cancel()
        }
        
        let thumbnailLoadTask = waveform.requestThumbnail(size: self.frame.size, completion: { [weak self] (image, error) in
            
            guard nil != self else {
                return
            }
            
            guard nil == error else {
                return
            }
            
            self!.thumbnailView.image = image
            
        })
        SVBriefWaveformCell.thumbnailTaskQueue.addOperation(thumbnailLoadTask!)
    }
    
    deinit {
        if let thumbnailTask = self.thumbnailTask {
            thumbnailTask.cancel()
        }
    }
}

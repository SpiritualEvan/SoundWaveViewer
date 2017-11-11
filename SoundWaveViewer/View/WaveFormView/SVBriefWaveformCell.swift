//
//  SVWaveformCell.swift
//  SoundWaveViewer
//
//  Created by Won Cheul Seok on 2017. 11. 11..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit

final class SVBriefWaveformCell: UITableViewCell {

//    static let waveformLoadQueue:OperationQueue()
    
    @IBOutlet private var waveformImageView:UIImageView!
    private var waveformLoadOperation:Operation?
    
    func setup(waveform:SVWaveForm!) {
        
        if nil != waveformLoadOperation {
            waveformLoadOperation?.cancel()
        }
        
        waveform.thumbnail(size: frame.size) { (image, error) in
            guard nil == error else {
                return
            }
            
//            waveformImageView.image = image
        }
    }
}

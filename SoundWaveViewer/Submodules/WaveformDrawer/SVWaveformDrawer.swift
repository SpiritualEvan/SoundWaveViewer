//
//  SVWaveformDrawer.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 13..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit

class SVWaveformDrawer: NSObject {
    class func waveformImage(waveform:[MinMaxElement], imageSize:CGSize) throws -> UIImage {
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            throw SVWaveFormError.failedToCreateContextWhileCreatingWaveformThumbnail
        }
        context.setAlpha(1.0)
        context.setLineWidth(1.0)
        let path = CGMutablePath()
        
        let centerY:CGFloat = imageSize.height / 2.0
        let maxLength:CGFloat = imageSize.height / 2.0
        
        path.move(to: CGPoint(x: 0, y: centerY))
        for (x, (min, max)) in waveform.enumerated() {
            let maxPoint = CGPoint(x: CGFloat(x), y: centerY - (maxLength * CGFloat(max)))
            let minPoint = CGPoint(x: CGFloat(x), y: centerY - (maxLength * CGFloat(min) + 1))
            path.move(to: maxPoint)
            path.addLine(to: minPoint)
        }
        context.addPath(path)
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.strokePath()
        
        if let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return thumbnailImage
        }else {
            UIGraphicsEndImageContext()
            throw SVWaveFormError.failedToCreateContextWhileCreatingWaveformThumbnail
        }
        
    }
}

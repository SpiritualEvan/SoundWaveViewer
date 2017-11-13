//
//  SVWaveformDrawer.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 13..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit

class SVWaveformDrawer: NSObject {
    class func waveformImage(waveform:[Float], imageSize:CGSize) throws -> UIImage {
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            throw SVWaveFormError.failedToCreateContextWhileCreatingWaveformThumbnail
        }
        context.setAlpha(1.0)
        context.setLineWidth(1.0)
        let path = CGMutablePath()
        
        let centerY:CGFloat = imageSize.height / 2.0
        let maxLength:CGFloat = imageSize.height / 2.0
        
        path.move(to: CGPoint(x: 0, y: centerY))
        for (x, sample) in waveform.enumerated() {
            let nextPoint = CGPoint(x: CGFloat(x), y: centerY + (maxLength * CGFloat(sample)))
            path.addLine(to: nextPoint)
            path.move(to: nextPoint)
        }
        context.addPath(path)
        context.setStrokeColor(UIColor.blue.cgColor)
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

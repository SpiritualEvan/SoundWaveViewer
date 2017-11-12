//
//  SVMainViewController.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 9..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit
import MobileCoreServices

final class SVMainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var waveformViewController:SVWaveFormViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let indexOfWaveformVC = childViewControllers.index { (viewController) -> Bool in
            return viewController is SVWaveFormViewController
        }!
        waveformViewController = childViewControllers[indexOfWaveformVC] as! SVWaveFormViewController
        waveformViewController.loadTracks(mediaURL:URL(fileURLWithPath: Bundle.main.path(forResource: "4_tracks_audio", ofType: "mov")!))
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func newFilePressed(_ sender: Any) {
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let imagePickerVC = UIImagePickerController()
            imagePickerVC.sourceType = .savedPhotosAlbum
            imagePickerVC.mediaTypes = [kUTTypeMovie as String, kUTTypeAudio as String]
            imagePickerVC.delegate = self
            self.present(imagePickerVC, animated: true, completion: nil)
        }else {
            
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let mediaURL = info[UIImagePickerControllerMediaURL] as? URL {
            waveformViewController.loadTracks(mediaURL:mediaURL)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


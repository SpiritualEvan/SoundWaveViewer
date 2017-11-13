//
//  SVMainViewController.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 9..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer

final class SVMainViewController: UIViewController {
    
    var waveformViewController:SVWaveFormViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let indexOfWaveformVC = childViewControllers.index { (viewController) -> Bool in
            return viewController is SVWaveFormViewController
        }!
        waveformViewController = childViewControllers[indexOfWaveformVC] as! SVWaveFormViewController
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func newFilePressed(_ sender: Any) {
        
        let importSourceActionSheet = UIAlertController(title: "Import media from", message: nil, preferredStyle: .actionSheet)

        importSourceActionSheet.addAction(UIAlertAction(title: "Demo (4 tracks)", style: .default) { (action) in
            self.waveformViewController.loadTracks(mediaURL:URL(fileURLWithPath: Bundle.main.path(forResource: "4_tracks_audio", ofType: "mov")!))
        })
        
        importSourceActionSheet.addAction(UIAlertAction(title: "Demo (13 tracks)", style: .default) { (action) in
            self.waveformViewController.loadTracks(mediaURL:URL(fileURLWithPath: Bundle.main.path(forResource: "13_tracks_audio", ofType: "mov")!))
        })
        
        importSourceActionSheet.addAction(UIAlertAction(title: "Music Library", style: .default) { (action) in
            self.presentMediaPickerController()
        })
            
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let sourceButton = UIAlertAction(title: "Video Library", style: .default, handler: { (action) in
                self.presentImagePickerController(sourceType: .photoLibrary)
            })
            importSourceActionSheet.addAction(sourceButton)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let sourceButton = UIAlertAction(title: "Take a Video", style: .default, handler: { (action) in
                self.presentImagePickerController(sourceType: .camera)
            })
            importSourceActionSheet.addAction(sourceButton)
        }
        
        self.present(importSourceActionSheet, animated: true, completion: nil)
    }
}
extension SVMainViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentImagePickerController(sourceType:UIImagePickerControllerSourceType) {
        let imagePickerControler = UIImagePickerController()
        imagePickerControler.sourceType = sourceType
        imagePickerControler.mediaTypes = [kUTTypeMovie as String, kUTTypeAudio as String]
        imagePickerControler.delegate = self
        self.present(imagePickerControler, animated: true, completion: nil)
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
extension SVMainViewController : MPMediaPickerControllerDelegate {
    func presentMediaPickerController() {
        let mediaPickerController = MPMediaPickerController(mediaTypes: [.music])
        mediaPickerController.delegate = self
        mediaPickerController.allowsPickingMultipleItems = false
        present(mediaPickerController, animated: true, completion: nil)
    }
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        guard 0 < mediaItemCollection.items.count,
            let songURL = mediaItemCollection.items[0].value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {
                let errorAlert = UIAlertController(title: nil, message: "No url founded for this song, please choose another song", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                errorAlert.addAction(okAction)
                mediaPicker.present(errorAlert, animated: true, completion: nil)
            return
        }
        waveformViewController.loadTracks(mediaURL:songURL)
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}

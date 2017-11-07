//
//  ViewController.swift
//  SoundWaveViewer
//
//  Created by Won Cheul Seok on 2017. 11. 7..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit

class SVMainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func newFilePressed(_ sender: Any) {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .photoLibrary
        self.present(imagePickerVC, animated: true, completion: nil)
        
    }
    
}


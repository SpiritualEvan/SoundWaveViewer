//
//  SWWaveFormViewController.swift
//  SoundWaveViewer
//
//  Created by Evan Seok on 2017. 11. 8..
//  Copyright © 2017년 Evan Seok. All rights reserved.
//

import UIKit

final class SVWaveFormViewController: UIViewController {
    
    let SVWaveformCellIdentifier = "SVWaveformCellIdentifier"
    var tracks:[SVWaveForm]!
    
    @IBOutlet weak var tracksView: UITableView!
    @IBOutlet weak var waveFormView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tracks = [SVWaveForm]()
    }
    func loadTracks(mediaURL:URL!) {
        
//        SVSoundLoader.loadTracks(mediaURL: mediaURL) { [weak self] (medias, error) in
//            
//            guard nil != self else {
//                return
//            }
//            
//            guard nil != error, let loadedMedias = medias else {
//                let alertVC = UIAlertController(title: nil, message: error!.localizedDescription, preferredStyle: .alert)
//                alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                self!.present(alertVC, animated: true, completion: nil)
//                return
//            }
//            
//            SVWaveFormBuilder.buildWaveform(mediaURL: <#T##URL!#>, briefWaveformWidth: <#T##Int#>, completion: <#T##((SVWaveForm?, Error?) -> Void)##((SVWaveForm?, Error?) -> Void)##(SVWaveForm?, Error?) -> Void#>)
//            
//        }
//        
//        self.tracks = tracks
//        tracksView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
extension SVWaveFormViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier:SVWaveformCellIdentifier , for: indexPath) as! SVBriefWaveformCell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let waveformCell = cell as! SVBriefWaveformCell
        waveformCell.setup(waveform: tracks[indexPath.row])
    }
}

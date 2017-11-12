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
    var media:SVMedia?
    var tracks:[SVWaveForm]!
    @IBOutlet weak var tracksView: UITableView!
    @IBOutlet weak var waveFormView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tracks = [SVWaveForm]()
    }
    func loadTracks(mediaURL:URL!) {
        
        SVSoundLoader.loadTracks(mediaURL: mediaURL) { [weak self] (media, error) in

            guard let weakSelf = self else {
                return
            }
            
            guard nil != error, let loadedMedia = media else {
                let alertVC = UIAlertController(title: nil, message: error!.localizedDescription, preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self!.present(alertVC, animated: true, completion: nil)
                return
            }
            weakSelf.media = loadedMedia
            weakSelf.tracks = [SVWaveForm]()
//            for assetTrack in loadedMedia.assetTracks {
//                weakSelf.tracks.append(SVWaveForm(asset: loadedMedia.asset, assetTrack: assetTrack))
//            }
            
            weakSelf.tracksView.reloadData()
        }
        
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

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
    @IBOutlet weak var tracksView: UITableView!
    @IBOutlet weak var waveFormView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    func loadTracks(mediaURL:URL!) {
        
        SVSoundLoader.loadTracks(mediaURL: mediaURL) { [weak self] (media, error) in

            guard let weakSelf = self else {
                return
            }
            
            guard nil == error, let loadedMedia = media else {
                let alertVC = UIAlertController(title: nil, message: error!.localizedDescription, preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self!.present(alertVC, animated: true, completion: nil)
                return
            }
            weakSelf.media = loadedMedia
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
        let cell = tableView.dequeueReusableCell(withIdentifier:SVWaveformCellIdentifier , for: indexPath) as! SVBriefWaveformCell
        cell.setup(waveform: media!.tracks[indexPath.row])
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return media?.tracks.count ?? 0
    }
}

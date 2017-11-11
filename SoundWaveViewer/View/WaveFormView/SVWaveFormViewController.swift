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

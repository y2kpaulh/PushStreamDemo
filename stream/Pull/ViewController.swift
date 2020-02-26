//
//  ViewController.swift
//  VersaPlayerTest_ios
//
//  Created by Jose Quintero on 11/5/18.
//  Copyright © 2018 Quasar Studio. All rights reserved.
//

import UIKit
import VersaPlayer

class ViewController: UIViewController {

  @IBOutlet weak var playerView: VersaPlayerView!
  @IBOutlet weak var controls: VersaPlayerControls!

  override func viewDidLoad() {
    super.viewDidLoad()

    playerView.layer.backgroundColor = UIColor.black.cgColor
    playerView.use(controls: controls)

    if let url = URL.init(string: "http://wowtv.xst.kinxcdn.com/wowtv/livestream/playlist.m3u8") {
      let item = VersaPlayerItem(url: url)
      if #available(iOS 13.0, *) {
        item.automaticallyPreservesTimeOffsetFromLive = true
      }
      playerView.set(item: item)
    }
  }

  @IBAction func touchBtn(_ sender: Any) {
    print(#function)
  }
}

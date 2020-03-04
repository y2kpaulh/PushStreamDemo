//
//  ViewController.swift
//  TestPlayer
//
//  Created by Inpyo Hong on 2020/03/02.
//  Copyright © 2020 Inpyo Hong. All rights reserved.
//

import UIKit
import CoreMedia
import SnapKit
import Kingfisher
import Alamofire
import AVFoundation

class PullStreamViewController: UIViewController {
  @IBOutlet weak var profileBtn: UIButton!

  @IBOutlet weak var streamTypeLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var volumeBtn: UIButton!
  @IBOutlet weak var playerView: VersaPlayerView!
  @IBOutlet weak var controls: VersaPlayerControls!

  @IBOutlet weak var playbackProgressView: UIProgressView!
  @IBOutlet weak var bufferProgressView: UIProgressView!
  @IBOutlet weak var loadedProgressView: UIProgressView!

  @IBOutlet weak var bottomMenuView: UIView!
  @IBOutlet weak var topMenuView: UIView!
  @IBOutlet weak var stallTimeLabel: UILabel!

  var durationTime: Float64 = 0.0

  var playbackTime: Float64 = 0.0 {
    didSet {
      playbackProgress = Float(playbackTime/durationTime)
    }
  }

  var loadedTime: Float64 = 0.0 {
    didSet {
      loadedProgress = Float(loadedTime/durationTime)
    }
  }

  var loadedProgress: Float = 0 {
    didSet {
      self.bufferProgressView.progress = loadedProgress
      self.loadedProgressView.progress = loadedProgress
    }
  }

  var playbackProgress: Float = 0 {
    didSet {
      self.playbackProgressView.progress = playbackProgress
    }
  }

  var url: String = ""

  var playbackType: String = "" {
    didSet {
      guard oldValue != playbackType else { return }
      self.streamTypeLabel.text = playbackType

      switch playbackType {
      case "LIVE":
        self.streamTypeLabel.textColor = .red
        break

      case "VOD":
        self.streamTypeLabel.textColor = .yellow

      case "FILE":
        self.streamTypeLabel.textColor = .blue
        break

      default:
        self.streamTypeLabel.textColor = .darkGray
        break
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configPlayer(url: url)
    downloadUserInfo()
  }

  func configPlayer(url: String) {
    if let _url = URL.init(string: url) {
      let item = VersaPlayerItem(url: _url)
      playerView.set(item: item)
    }

    //self.navigationController?.navigationBar.isHidden = true

    playerView.layer.backgroundColor = UIColor.black.cgColor
    playerView.use(controls: controls)
    playerView.playbackDelegate = self

    self.setSliderThumbTintColor(.white)

    playerView.isUserInteractionEnabled = true
    let menuBgViewGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapPlayerView))
    playerView.addGestureRecognizer(menuBgViewGesture)
  }

  func downloadUserInfo() {
    KingfisherManager.shared.cache.clearMemoryCache()
    KingfisherManager.shared.cache.clearDiskCache()
    KingfisherManager.shared.cache.cleanExpiredDiskCache()

    let url = URL(string: "https://picsum.photos/200")

    self.profileBtn.kf.setBackgroundImage(with: url, for: .normal, placeholder: UIImage(named: "profile"), options: [.transition(.fade(0.2))]) { result in
      switch result {
      case .success(let value):
        print("Task done for: \(value.source.url?.absoluteString ?? "")")
      case .failure(let error):
        print("Job failed: \(error.localizedDescription)")
      }
    }
  }

  @objc func tapPlayerView() {
    UIView.animate(withDuration: 0.3) { [weak self] in
      guard let self = self else { return }

      if !self.topMenuView.isHidden {
        self.topMenuView.alpha = 0
        self.bottomMenuView.alpha = 0

        self.topMenuView.isHidden = true
        self.bottomMenuView.isHidden = true
      } else {
        self.topMenuView.alpha = 1
        self.bottomMenuView.alpha = 1

        self.topMenuView.isHidden = false
        self.bottomMenuView.isHidden = false
      }
    }
  }

  @IBAction private func onTapVolumeButton(_ sender: UIButton) {
    let isMuted = !sender.isSelected
    volumeBtn.isSelected = isMuted
    controls.isMuted = isMuted
  }

  @IBAction func tapLikeBtn(_ sender: Any) {
    for _ in 0...3 {
      SRFacebookAnimation.startPoint(CGPoint(x: self.view.frame.size.width - 30, y: self.view.frame.size.height - 80))

      SRFacebookAnimation.animate(image: #imageLiteral(resourceName: "6"))
      SRFacebookAnimation.animate(image: #imageLiteral(resourceName: "5"))

      // Amplitude of the path. Default value is 50
      SRFacebookAnimation.animationAmplitude(60)

      // Bouncing needed more than the amplitude , Default value is 5.
      SRFacebookAnimation.amplitudeBounce(5)

      // duration of the animation
      SRFacebookAnimation.animationDuration(5)

      //Uptrust true means first it will animate to +ve direction.Default value is true.
      SRFacebookAnimation.isUptrust(true)

      //Can change the demention of imageview.Default value is 20.
      SRFacebookAnimation.imageDimention(30)//30 means you will get an imageView of dimension 30x30
    }
  }

  fileprivate func makeCircleWith(size: CGSize, backgroundColor: UIColor) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(backgroundColor.cgColor)
    context?.setStrokeColor(UIColor.clear.cgColor)
    let bounds = CGRect(origin: .zero, size: size)
    context?.addEllipse(in: bounds)
    context?.drawPath(using: .fill)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }

  func setSliderThumbTintColor(_ color: UIColor) {
    let circleImage = makeCircleWith(size: CGSize(width: 10, height: 10),
                                     backgroundColor: color)
    controls.seekbarSlider?.setThumbImage(circleImage, for: .normal)
    controls.seekbarSlider?.setThumbImage(circleImage, for: .highlighted)
  }

}

extension PullStreamViewController: VersaPlayerPlaybackDelegate {
  func playbackRateTimeChanged(player: VersaPlayer, stallTime: CFTimeInterval) {
    DispatchQueue.main.async {
      self.stallTimeLabel.text = String(format: "Loading: %0.2f sec", stallTime)
    }
  }

  func timeDidChange(player: VersaPlayer, to time: CMTime) {
    let currentItem = player.currentItem
    let timeRangeArray = currentItem?.loadedTimeRanges

    guard let timeRange = timeRangeArray?.first?.timeRangeValue else { return }
    guard let accessLog: AVPlayerItemAccessLog = currentItem?.accessLog() else { return }
    let logEvent = accessLog.events[0]

    guard let type = logEvent.playbackType else { return }
    playbackType = type

    durationTime = CMTimeGetSeconds((currentItem?.asset.duration)!)
    playbackTime = CMTimeGetSeconds(player.currentTime())
    loadedTime = CMTimeGetSeconds(timeRange.duration)
  }
}

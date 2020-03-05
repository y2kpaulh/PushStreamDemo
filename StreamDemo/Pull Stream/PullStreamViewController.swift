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

  @IBOutlet weak var debugBtn: UIButton!
  @IBOutlet weak var playbackProgressView: UIProgressView!
  @IBOutlet weak var bufferProgressView: UIProgressView!
  @IBOutlet weak var loadedProgressView: UIProgressView!

  @IBOutlet weak var bottomMenuView: UIView!
  @IBOutlet weak var topMenuView: UIView!
  @IBOutlet weak var stallTimeLabel: UILabel!
  @IBOutlet weak var logMsgView: UITextView!
  var storageController: StorageController = StorageController()

  public var logMsg: String = ""{
    didSet {
      if logMsg.count > 0 {

        storageController.save(Log(msg: logMsg))
      }
    }
  }

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
      DispatchQueue.main.async {
        self.bufferProgressView.progress = self.loadedProgress
        self.loadedProgressView.progress = self.loadedProgress
      }
    }
  }

  var playbackProgress: Float = 0 {
    didSet {
      DispatchQueue.main.async {
        self.playbackProgressView.progress = self.playbackProgress
      }
    }
  }

  var url: String = ""

  var playbackType: String = "" {
    didSet {
      guard oldValue != playbackType else { return }

      storageController.save(Log(msg: "playback type: \(playbackType)"))

      DispatchQueue.main.async {
        self.streamTypeLabel.text = self.playbackType

        switch self.playbackType {
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
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configPlayer(url: url)
    //downloadUserInfo()
  }

  func configPlayer(url: String) {
    if let _url = URL.init(string: url) {
      let item = VersaPlayerItem(url: _url)
      playerView.set(item: item)
    }

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

  func playbackItemReady(player: VersaPlayer, item: VersaPlayerItem?) {
    print(#function)
  }

  func playbackRateTimeChanged(player: VersaPlayer, stallTime: CFTimeInterval) {
    DispatchQueue.main.async {
      self.stallTimeLabel.text = String(format: "Loading: %0.2f sec", stallTime)
    }
  }

  func timeDidChange(player: VersaPlayer, to time: CMTime) {
    guard let currentItem = player.currentItem else { return }
    let timeRangeArray = currentItem.loadedTimeRanges
    guard let timeRange = timeRangeArray.first?.timeRangeValue else { return }

    durationTime = CMTimeGetSeconds((currentItem.asset.duration))
    playbackTime = CMTimeGetSeconds(player.currentTime())
    loadedTime = CMTimeGetSeconds(timeRange.duration)

    guard let accessLog: AVPlayerItemAccessLog = currentItem.accessLog() else { return }
    guard let type = accessLog.events[0].playbackType else { return }

    playbackType = type

    if playbackType == "LIVE" {
      if #available(iOS 13.0, *) {
        // Discover and adjust distance from live
        let howFarNow = currentItem.configuredTimeOffsetFromLive
        let recommended = currentItem.recommendedTimeOffsetFromLive

        let howFarNowSecond = CMTimeGetSeconds(howFarNow)
        let recommendedSecond = CMTimeGetSeconds(recommended)

        print(#function, "howFarNow", String(format: "%.2f", howFarNowSecond), "recommended", String(format: "%.2f", recommendedSecond))

        if  howFarNow < recommended {
          currentItem.configuredTimeOffsetFromLive = recommended
          print(#function, "howFarNow < recommended, currentItem.configuredTimeOffsetFromLive = recommended")
          storageController.save(Log(msg: "\(storageController.currentTime()) howFarNow < recommended, currentItem.configuredTimeOffsetFromLive = recommended"))
        }
      }

      guard let livePosition = currentItem.seekableTimeRanges.last as? CMTimeRange else {
        return
      }

      let livePositionStartSecond = CMTimeGetSeconds(livePosition.start)
      let livePositionEndSecond = CMTimeGetSeconds(livePosition.end)

      print("livePositionStartSecond", livePositionStartSecond, "livePositionEndSecond", livePositionEndSecond)
    } else {
      guard let seekPosition = currentItem.seekableTimeRanges.last as? CMTimeRange else {
        return
      }

      let seekPositionStartSecond = CMTimeGetSeconds(seekPosition.start)
      let seekPositionEndSecond = CMTimeGetSeconds(seekPosition.end)

      print("seekPositionStartSecond", seekPositionStartSecond, "seekPositionEndSecond", seekPositionEndSecond)
    }
  }

  func playbackDidFailed(with error: VersaPlayerPlaybackError) {
    print(#function, "error occured:", error)
    storageController.save(Log(msg: "\(storageController.currentTime()) \(#function) error occured: \(error)\n"))

    switch error {
    case .notFound:
      let alert =  UIAlertController(title: "playback error", message: "error message:\(error)", preferredStyle: .alert)
      let ok = UIAlertAction(title: "OK", style: .default, handler: { (_) in
        self.dismiss(animated: true, completion: nil)
      })

      alert.addAction(ok)

      self.present(alert, animated: true, completion: {
        self.playerView.controls?.hideBuffering()
      })

    default:
      break
    }
  }
}

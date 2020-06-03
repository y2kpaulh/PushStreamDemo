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
import Alamofire
import Kingfisher
import AVKit
import AVFoundation
import RxSwift
import RxCocoa

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
  @IBOutlet weak var logMsgView: UITextView!

  var diplayErrorPopup = false

  var savedAvPlayer: AVPlayer?

  private var disposeBag = DisposeBag()

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

      storageController.save(Log(msg: "playback type: \(playbackType)\n"))

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

  override func loadView() {
    super.loadView()
    configPlayer(url: url)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    //configPlayer(url: url)
  }

  func configPlayer(url: String) {
    if let _url = URL.init(string: url) {
      let item = VersaPlayerItem(url: _url)
      playerView.player.rate = 1
      playerView.set(item: item)
    }

    playerView.layer.backgroundColor = UIColor.black.cgColor
    playerView.use(controls: controls)
    playerView.playbackDelegate = self

    playerView.isUserInteractionEnabled = true
    let menuBgViewGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapPlayerView))
    playerView.addGestureRecognizer(menuBgViewGesture)

    NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { _ in
        print("didEnterBackgroundNotification")
        self.savedAvPlayer = self.playerView.renderingView.playerLayer.player
        self.playerView.renderingView.playerLayer.player = nil
      })
      .disposed(by: disposeBag)

    NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { _ in
        print("didBecomeActiveNotification")
        self.playerView.renderingView.playerLayer.player = self.savedAvPlayer
      })
      .disposed(by: disposeBag)
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
    guard let accessLog = currentItem.accessLog() else { return }

    if accessLog.events.count > 0 {
      let event = accessLog.events[0]
      DispatchQueue.main.async {
        self.playbackType = event.playbackType!
      }
    }

    durationTime = CMTimeGetSeconds((currentItem.asset.duration))
    playbackTime = CMTimeGetSeconds(player.currentTime())

    if playbackType == "LIVE" {
      guard let livePosition = currentItem.seekableTimeRanges.last as? CMTimeRange else {
        return
      }

      let livePositionStartSecond = CMTimeGetSeconds(livePosition.start)
      let livePositionEndSecond = CMTimeGetSeconds(livePosition.end)

      storageController.save(Log(msg: "livePositionStartSecond:\(livePositionStartSecond) livePositionEndSecond:\(livePositionEndSecond)\n"))
    } else {
      guard let timeRange = currentItem.loadedTimeRanges.first?.timeRangeValue else { return }
      loadedTime = CMTimeGetSeconds(timeRange.duration)

      guard let seekPosition = currentItem.seekableTimeRanges.last as? CMTimeRange else {
        return
      }

      let seekPositionStartSecond = CMTimeGetSeconds(seekPosition.start)
      let seekPositionEndSecond = CMTimeGetSeconds(seekPosition.end)

      storageController.save(Log(msg: "seekPositionStartSecond:\(seekPositionStartSecond) seekPositionEndSecond: \(seekPositionEndSecond)\n"))
    }
  }

  func playbackDidFailed(with error: VersaPlayerPlaybackError) {
    print(#function, "error occured:", error)
    storageController.save(Log(msg: "\(storageController.currentTime()) \(#function) error occured: \(error)\n"))

    let alert =  UIAlertController(title: "Playback Error", message: "\(error)", preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .default, handler: { (_) in
      self.dismiss(animated: true, completion: nil)
    })

    alert.addAction(ok)
    self.present(alert, animated: true, completion: {
      self.playerView.controls?.hideBuffering()
    })

    //    switch error {
    //    case .notFound:
    //        break
    //
    //    default:
    //      break
    //    }
  }

  func startBuffering(player: VersaPlayer) {
    print(#function)
  }

  // isPlaybackLikelyToKeepUp == true
  func endBuffering(player: VersaPlayer) {
    print("AVPlayerItem.isPlaybackLikelyToKeepUp == true")
    print(#function)
  }

  func playbackNewErrorLogEntry(with error: AVPlayerItemErrorLog) {
    //    print(#function, "error occured:", error.events)
    for errLog in error.events {
      print(errLog.errorStatusCode, String(errLog.errorComment!))

      if errLog.errorStatusCode == -12884 && !diplayErrorPopup {
        diplayErrorPopup = true

        DispatchQueue.main.async {
          let alert =  UIAlertController(title: "Playback Error", message: String(errLog.errorComment!), preferredStyle: .alert)
          let ok = UIAlertAction(title: "OK", style: .default, handler: { (_) in
            self.diplayErrorPopup = false
            self.dismiss(animated: true, completion: nil)
          })

          alert.addAction(ok)
          self.present(alert, animated: true, completion: nil)
        }
      }
    }
  }

  func playbackDidEnd(player: VersaPlayer) {
    print(#function)
  }
}

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
import PiPhone

protocol PipViewControllerDelegate: class {
  func PipViewController(_ videoPlayerViewController: UIViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
}

class VodViewController: UIViewController {

  let chatView = ChatRoomViewController()

  /// Required for the `MessageInputBar` to be visible
  override var canBecomeFirstResponder: Bool {
    return chatView.canBecomeFirstResponder
  }

  /// Required for the `MessageInputBar` to be visible
  override var inputAccessoryView: UIView? {
    return chatView.inputAccessoryView
  }

  @IBOutlet weak var profileBtn: UIButton!

  @IBOutlet weak var streamTypeLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var volumeBtn: UIButton!
  @IBOutlet weak var playerView: VersaPlayerView!
  @IBOutlet weak var controls: VersaPlayerControls!

  @IBOutlet var pipToggleButton: UIButton!

  weak var delegate: PipViewControllerDelegate?
  //var player: AVPlayer?
  private var pictureInPictureController: AVPictureInPictureController!
  private var pictureInPictureObservations = [NSKeyValueObservation]()
  private var strongSelf: Any?

  deinit {
    // without this line vanilla AVPictureInPictureController will crash due to KVO issue
    pictureInPictureObservations = []
  }

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

  @IBAction func tapBgBtn(_ sender: Any) {
    chatView.messageInputBar.inputTextView.resignFirstResponder()
  }

  @IBAction func tapTestBtn(_ sender: Any) {
    chatView.messageInputBar.inputTextView.resignFirstResponder()
  }

  @IBAction func tapCloseBtn(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    //configPlayer(url: url)
    /// Add the `ConversationViewController` as a child view controller
    chatView.willMove(toParent: self)
    addChild(chatView)
    view.addSubview(chatView.view)
    chatView.didMove(toParent: self)
  }

  override func viewWillDisappear(_ animated: Bool) {
    //PIP 동작을 위해 현재 VC를 빠져나갈 경우 삭제되어야함.
    // playerView.player.replaceCurrentItem(with: nil)
  }

  func configPlayer(url: String) {
    setupPictureInPicture()

    if let _url = URL.init(string: url) {
      let item = VersaPlayerItem(url: _url)
      playerView.player.rate = 1
      //playerView.player.automaticallyWaitsToMinimizeStalling = false
      playerView.set(item: item)
    }

    playerView.layer.backgroundColor = UIColor.black.cgColor
    // playerView.use(controls: controls)
    playerView.playbackDelegate = self
    //
    //    if let result = playerView.pipController?.isPictureInPicturePossible, result == true {
    //      print("isPictureInPicturePossible", result)
    //    }

    playerView.renderingView.playerLayer.videoGravity = .resizeAspectFill
    playerView.layer.cornerRadius = 20

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

extension VodViewController: VersaPlayerPlaybackDelegate {

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

    } else {
      guard let timeRange = currentItem.loadedTimeRanges.first?.timeRangeValue else { return }
      loadedTime = CMTimeGetSeconds(timeRange.duration)

      guard let seekPosition = currentItem.seekableTimeRanges.last as? CMTimeRange else {
        return
      }

      let seekPositionStartSecond = CMTimeGetSeconds(seekPosition.start)
      let seekPositionEndSecond = CMTimeGetSeconds(seekPosition.end)

    }
  }

  func playbackDidFailed(with error: VersaPlayerPlaybackError) {
    print(#function, "error occured:", error)

    let alert =  UIAlertController(title: "AVPlayer Error", message: "\(error)", preferredStyle: .alert)
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

  func playbackFailInfo(with error: NSError, type: VersaPlayerPlaybackError) {
    print(#function, error, type)
  }

  func playbackNewErrorLogEntry(with error: AVPlayerItemErrorLog) {
    print(#function, "error occured:", error.events)

    for errLog in error.events {
      print("AVPlayerItem Error Log", errLog.errorStatusCode, String(errLog.errorComment!))
      if errLog.errorStatusCode == -12884 && !diplayErrorPopup {
        diplayErrorPopup = true

        DispatchQueue.main.async {
          let alert =  UIAlertController(title: "AVPlayerItem Error Log", message: String(errLog.errorComment!), preferredStyle: .alert)
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

  func playbackStalled(with item: AVPlayerItem) {
    print(#function, item.asset)
  }

  func playbackDidEnd(player: VersaPlayer) {
    print(#function)
  }

  // https://developer.apple.com/documentation/avkit/adopting_picture_in_picture_in_a_custom_player
  func setupPictureInPicture() {
    pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil), for: .normal)
    pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil), for: .selected)
    pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil), for: [.selected, .highlighted])

    guard AVPictureInPictureController.isPictureInPictureSupported(),
      let pictureInPictureController = AVPictureInPictureController(playerLayer: playerView.renderingView.playerLayer) else {
        pipToggleButton.isEnabled = false
        return
    }

    self.pictureInPictureController = pictureInPictureController
    pictureInPictureController.delegate = self
    pipToggleButton.isEnabled = pictureInPictureController.isPictureInPicturePossible

    pictureInPictureObservations.append(pictureInPictureController.observe(\.isPictureInPictureActive) { [weak self] pictureInPictureController, _ in
      guard let `self` = self else { return }

      self.pipToggleButton.isSelected = pictureInPictureController.isPictureInPictureActive
    })

    pictureInPictureObservations.append(pictureInPictureController.observe(\.isPictureInPicturePossible) { [weak self] pictureInPictureController, _ in
      guard let `self` = self else { return }

      self.pipToggleButton.isEnabled = pictureInPictureController.isPictureInPicturePossible
    })
  }

  // MARK: - Actions
  @IBAction func pipToggleButtonTapped() {
    if pipToggleButton.isSelected {
      pictureInPictureController.stopPictureInPicture()
    } else {
      pictureInPictureController.startPictureInPicture()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    //채팅창 화면 상단 하단 gradation
    let gradient = CAGradientLayer()
    gradient.frame = chatView.view.bounds
    gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
    gradient.locations = [0, 0.1, 0.9, 1]

    chatView.view.layer.mask = gradient

    chatView.view.backgroundColor = .clear
    chatView.messageInputBar.backgroundView.backgroundColor = .clear
    chatView.inputAccessoryView?.backgroundColor = .clear

    // 채팅창 화면 사이즈 및 위치
    chatView.view.frame = CGRect(x: 0, y: 200, width: view.bounds.width-100, height: view.bounds.height - 200)
  }
}

// MARK: - AVPictureInPictureControllerDelegate
extension VodViewController: AVPictureInPictureControllerDelegate {

  func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    strongSelf = self
  }

  func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    strongSelf = nil
  }

  func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
    if let delegate = delegate {
      delegate.PipViewController(self, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    } else {
      completionHandler(true)
    }
  }

}

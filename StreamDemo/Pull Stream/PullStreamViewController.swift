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
import IQKeyboardManager

class PullStreamViewController: UIViewController {

  @IBOutlet weak var profileBtn: UIButton!

  //  @IBOutlet weak var streamTypeLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var playerView: VersaPlayerView!
  // @IBOutlet weak var controls: VersaPlayerControls!

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

  @IBOutlet weak var topMenuView: UIView!

  var diplayErrorPopup = false

  var savedAvPlayer: AVPlayer?

  private var disposeBag = DisposeBag()

  var url: String = ""

  @IBOutlet weak var closeBtn: UIButton!

  let chatView = ChatRoomViewController()

  var startPointX: CGFloat = UIScreen.main.bounds.width - 20
  var startPointY: CGFloat = UIScreen.main.bounds.height
  var endPointX: CGFloat = UIScreen.main.bounds.width - 20
  var endPointY: CGFloat = -100.0

  /// Required for the `MessageInputBar` to be visible
  override var canBecomeFirstResponder: Bool {
    return chatView.canBecomeFirstResponder
  }

  /// Required for the `MessageInputBar` to be visible
  override var inputAccessoryView: UIView? {
    return chatView.inputAccessoryView
  }

  override func loadView() {
    super.loadView()

    let image = UIImage(named: "close")?.withRenderingMode(.alwaysTemplate)
    closeBtn.setImage(image, for: .normal)
    closeBtn.tintColor = .white

    configPlayer(url: url)
    configChatView()
  }

  @IBAction func tapCloseBtn(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    IQKeyboardManager.shared().isEnabled = false
    IQKeyboardManager.shared().isEnableAutoToolbar = false
  }

  override func viewWillDisappear(_ animated: Bool) {
    //playerView.player.replaceCurrentItem(with: nil)
    IQKeyboardManager.shared().isEnabled = true
    IQKeyboardManager.shared().isEnableAutoToolbar = true
  }

  func configChatView() {
    chatView.willMove(toParent: self)
    addChild(chatView)
    view.addSubview(chatView.view)
    chatView.didMove(toParent: self)

    self.titleLabel.text = chatView.userInfo.displayName
    self.profileBtn.setImage(UIImage(named: "Inpyo"), for: .normal)
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

    //video view round 처리
    playerView.renderingView.cornerRadius = 8

    playerView.renderingView.playerLayer.videoGravity = .resizeAspectFill

    playerView.isUserInteractionEnabled = false

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

  @objc func handleTap() {
    (0...10).forEach { (_) in
      generateAnimatedViews()
    }
  }

  fileprivate func generateAnimatedViews() {
    let image = drand48() > 0.5 ? #imageLiteral(resourceName: "thumbs_up") : #imageLiteral(resourceName: "heart")
    let imageView = UIImageView(image: image)
    let dimension = 20 + drand48() * 10
    imageView.frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)

    let animation = CAKeyframeAnimation(keyPath: "position")

    animation.path = customPath().cgPath
    animation.duration = 2 + drand48() * 3
    animation.fillMode = CAMediaTimingFillMode.forwards
    animation.isRemovedOnCompletion = false
    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)

    imageView.layer.add(animation, forKey: nil)
    self.view.addSubview(imageView)
  }

  func customPath() -> UIBezierPath {
    let path = UIBezierPath()

    path.move(to: CGPoint(x: self.startPointX, y: self.startPointY))

    let endPoint = CGPoint(x: self.endPointX, y: self.endPointY)

    let randomYShift = 200 + drand48() * 300
    let cp1 = CGPoint(x: self.startPointX, y: UIScreen.main.bounds.height )
    let cp2 = CGPoint(x: 10 + randomYShift, y: 0.0 )

    path.addCurve(to: endPoint, controlPoint1: cp1, controlPoint2: cp2)
    path.addLine(to: endPoint)

    return path
  }

}

extension PullStreamViewController: VersaPlayerPlaybackDelegate {

  func playbackItemReady(player: VersaPlayer, item: VersaPlayerItem?) {
    print(#function)
  }

  func playbackRateTimeChanged(player: VersaPlayer, stallTime: CFTimeInterval) {
    DispatchQueue.main.async {
      //self.stallTimeLabel.text = String(format: "Loading: %0.2f sec", stallTime)
    }
  }

  func timeDidChange(player: VersaPlayer, to time: CMTime) {
    //    guard let currentItem = player.currentItem else { return }
    //    guard let accessLog = currentItem.accessLog() else { return }
    //
    //    if accessLog.events.count > 0 {
    //      let event = accessLog.events[0]
    //      DispatchQueue.main.async {
    //        self.playbackType = event.playbackType!
    //      }
    //    }
    //
    //    durationTime = CMTimeGetSeconds((currentItem.asset.duration))
    //    playbackTime = CMTimeGetSeconds(player.currentTime())
    //
    //    if playbackType == "LIVE" {
    //      guard let livePosition = currentItem.seekableTimeRanges.last as? CMTimeRange else {
    //        return
    //      }
    //
    //      let livePositionStartSecond = CMTimeGetSeconds(livePosition.start)
    //      let livePositionEndSecond = CMTimeGetSeconds(livePosition.end)
    //
    //      storageController.save(Log(msg: "livePositionStartSecond:\(livePositionStartSecond) livePositionEndSecond:\(livePositionEndSecond)\n"))
    //    } else {
    //      guard let timeRange = currentItem.loadedTimeRanges.first?.timeRangeValue else { return }
    //      loadedTime = CMTimeGetSeconds(timeRange.duration)
    //
    //      guard let seekPosition = currentItem.seekableTimeRanges.last as? CMTimeRange else {
    //        return
    //      }
    //
    //      let seekPositionStartSecond = CMTimeGetSeconds(seekPosition.start)
    //      let seekPositionEndSecond = CMTimeGetSeconds(seekPosition.end)
    //
    //      storageController.save(Log(msg: "seekPositionStartSecond:\(seekPositionStartSecond) seekPositionEndSecond: \(seekPositionEndSecond)\n"))
    //    }
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

    DispatchQueue.main.async {
      self.pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil), for: .normal)
      self.pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil), for: .selected)
      self.pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil), for: [.selected, .highlighted])

      guard AVPictureInPictureController.isPictureInPictureSupported(),
            let pictureInPictureController = AVPictureInPictureController(playerLayer: self.playerView.renderingView.playerLayer) else {
        self.pipToggleButton.isEnabled = false
        return
      }

      self.pictureInPictureController = pictureInPictureController
      //      pictureInPictureController.delegate = self
      self.pipToggleButton.isEnabled = pictureInPictureController.isPictureInPicturePossible

      self.pictureInPictureObservations.append(pictureInPictureController.observe(\.isPictureInPictureActive) { [weak self] pictureInPictureController, _ in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.pipToggleButton.isSelected = pictureInPictureController.isPictureInPictureActive
        }
      })

      self.pictureInPictureObservations.append(pictureInPictureController.observe(\.isPictureInPicturePossible) { [weak self] pictureInPictureController, _ in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.pipToggleButton.isEnabled = pictureInPictureController.isPictureInPicturePossible
        }
      })
    }

    func handleTap() {
      (0...10).forEach { (_) in
        generateAnimatedViews()
      }
    }

    func generateAnimatedViews() {
      let image = drand48() > 0.5 ? #imageLiteral(resourceName: "thumbs_up") : #imageLiteral(resourceName: "heart")
      let imageView = UIImageView(image: image)
      let dimension = 20 + drand48() * 10
      imageView.frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)

      let animation = CAKeyframeAnimation(keyPath: "position")

      animation.path = customPath().cgPath
      animation.duration = 2 + drand48() * 3
      animation.fillMode = CAMediaTimingFillMode.forwards
      animation.isRemovedOnCompletion = false
      animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)

      imageView.layer.add(animation, forKey: nil)
      self.view.addSubview(imageView)
    }

    func customPath() -> UIBezierPath {
      let path = UIBezierPath()

      path.move(to: CGPoint(x: self.startPointX, y: self.startPointY))

      let endPoint = CGPoint(x: self.endPointX, y: self.endPointY)

      let randomYShift = 200 + drand48() * 300
      let cp1 = CGPoint(x: self.startPointX, y: UIScreen.main.bounds.height )
      let cp2 = CGPoint(x: 10 + randomYShift, y: 0.0 )

      path.addCurve(to: endPoint, controlPoint1: cp1, controlPoint2: cp2)
      path.addLine(to: endPoint)

      return path
    }
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
    gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.black.cgColor]
    gradient.locations = [0, 0.1, 0.8, 0.9, 1]

    chatView.view.layer.mask = gradient
    chatView.view.backgroundColor = .clear
    chatView.messageInputBar.backgroundView.backgroundColor = .clear
    chatView.inputAccessoryView?.backgroundColor = .clear

    // 채팅창 화면 사이즈 및 위치
    chatView.view.frame = CGRect(x: 0, y: 140, width: view.bounds.width, height: view.bounds.height - 200)
  }
}

// MARK: - AVPictureInPictureControllerDelegate
//extension PullStreamViewController: AVPictureInPictureControllerDelegate {
//
//  func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//    strongSelf = self
//  }
//
//  func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//    strongSelf = nil
//  }
//
//  private func PipViewController(_ pictureInPictureController: UIViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
//    if let delegate = delegate {
//      delegate.PipViewController(self, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
//    } else {
//      completionHandler(true)
//    }
//  }
//}

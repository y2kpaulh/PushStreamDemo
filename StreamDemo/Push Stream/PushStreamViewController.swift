import AVFoundation
import HaishinKit
import Photos
import UIKit
import VideoToolbox
import RxSwift
import RxCocoa
import ReplayKit
import VerticalSlider

final class PushStreamViewController: UIViewController {
  private static let maxRetryCount: Int = 5
  let preferences = UserDefaults.standard
  var uri = ""
  var streamName = "ShallWeShop-iOS"

  @IBOutlet weak var zoomSlider: VerticalSlider!
  @IBOutlet weak var publishStateView: UIView!
  @IBOutlet private weak var lfView: GLHKView?
  @IBOutlet weak var closeBtn: UIButton!

  @IBOutlet weak var publishTimeLabel: UILabel!
  private var rtmpConnection = RTMPConnection()
  private var rtmpStream: RTMPStream!
  private var sharedObject: RTMPSharedObject!
  private var currentEffect: VideoEffect?
  private var currentPosition: AVCaptureDevice.Position = .back
  private var retryCount: Int = 0
  private var disposeBag = DisposeBag()

  let hdResolution: CGSize = CGSize(width: 720, height: 1280)
  let fhdResolution: CGSize = CGSize(width: 1080, height: 1920)
  var currentResolution: CGSize!
  var publishTimer: Disposable?
  var isPublishStream = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.currentResolution = self.hdResolution

    let image = UIImage(named: "close")?.withRenderingMode(.alwaysTemplate)
    closeBtn.setImage(image, for: .normal)
    closeBtn.tintColor = .white

    zoomSlider.slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    zoomSlider.slider.thumbRect(forBounds: zoomSlider.slider.bounds, trackRect: CGRect(x: 0, y: 0, width: 10, height: 10), value: 0.0)
    zoomSlider.slider.setThumbImage(self.progressImage(with: self.zoomSlider.slider.value), for: UIControl.State.normal)
    zoomSlider.slider.setThumbImage(self.progressImage(with: self.zoomSlider.slider.value), for: UIControl.State.selected)

    configStreaming()
  }

  func progressImage(with progress: Float) -> UIImage {
    let layer = CALayer()
    layer.backgroundColor = UIColor.white.cgColor
    layer.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
    layer.cornerRadius = 15

    let label = UILabel(frame: layer.frame)
    label.text = String(format: "%dx", Int(progress))//String(format: "%.1fx", progress)
    label.font = UIFont.systemFont(ofSize: 12)
    layer.addSublayer(label.layer)
    label.textAlignment = .center
    label.tag = 100
    label.transform = CGAffineTransform(rotationAngle: .pi/2)
    UIGraphicsBeginImageContext(layer.frame.size)
    layer.render(in: UIGraphicsGetCurrentContext()!)

    let degrees = 30.0
    let radians = CGFloat(degrees * .pi / 180)
    layer.transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }

  func configStreaming() {
    guard let pushUrl =  preferences.string(forKey: "pushUrl") else { return }
    guard let streamKey =  preferences.string(forKey: "streamKey") else { return }

    uri = pushUrl
    streamName = streamKey

    let session = AVAudioSession.sharedInstance()
    do {
      try session.setPreferredSampleRate(44_100)
      // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
      try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true)
    } catch {
    }

    rtmpStream = RTMPStream(connection: rtmpConnection)

    if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
      rtmpStream.orientation = orientation
    }

    self.configResolution(resolution: self.currentResolution)

    NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { _ in
        guard let orientation = DeviceUtil.videoOrientation(by: (UIApplication.shared.windows
                                                                  .first?
                                                                  .windowScene!
                                                                  .interfaceOrientation)!) else {
          return
        }

        print("orientationDidChangeNotification", orientation.rawValue)

        self.rtmpStream.orientation = orientation
      })
      .disposed(by: disposeBag)

    NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { _ in
        print("didEnterBackgroundNotification")
        self.rtmpStream.receiveVideo = false
      })
      .disposed(by: disposeBag)

    NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { _ in
        print("didBecomeActiveNotification")
        self.rtmpStream.receiveVideo = true
      })
      .disposed(by: disposeBag)
  }

  override func viewWillAppear(_ animated: Bool) {
    //logger.info("viewWillAppear")
    super.viewWillAppear(animated)

    rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
      print(error.description)

    }
    rtmpStream.attachCamera(DeviceUtil.device(withPosition: currentPosition)) { error in
      print(error.description)
    }
    rtmpStream.rx.observeWeakly(UInt16.self, "currentFPS", options: .new)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] fps in
        guard let self = self else { return }
        guard let currentFps = fps else { return }
        //        self.currentFPSLabel?.text = "\(currentFps) fps"
      })
      .disposed(by: disposeBag)

    lfView?.attachStream(rtmpStream)
    lfView?.videoGravity = .resizeAspect
    lfView?.cornerRadius = 8
  }

  override func viewWillDisappear(_ animated: Bool) {
    //logger.info("viewWillDisappear")
    super.viewWillDisappear(animated)
    publishTimer?.dispose()

    rtmpStream.close()
    rtmpStream.dispose()
  }

  @IBAction func tapCloseBtn(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func rotateCamera(_ sender: UIButton) {
    //logger.info("rotateCamera")
    let position: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
    rtmpStream.attachCamera(DeviceUtil.device(withPosition: position)) { error in
      print(error.description)
    }
    currentPosition = position
  }

  @IBAction func toggleTorch(_ sender: UIButton) {
    rtmpStream.torch.toggle()
  }

  @objc internal func sliderChanged() {
    print(#function, zoomSlider.value)
    zoomSlider.slider.setThumbImage(self.progressImage(with: self.zoomSlider.slider.value), for: UIControl.State.normal)
    zoomSlider.slider.setThumbImage(self.progressImage(with: self.zoomSlider.slider.value), for: UIControl.State.selected)

    rtmpStream.setZoomFactor(CGFloat(zoomSlider.value), ramping: true, withRate: 2.0)
  }

  @IBAction func on(pause: UIButton) {
    if UIApplication.shared.isIdleTimerDisabled != true && pause.isSelected != true {
      let alert =  UIAlertController(title: nil, message: "cannot pause event. current state is recording state.", preferredStyle: .alert)
      let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
      alert.addAction(ok)
      self.present(alert, animated: true, completion: nil)
      return
    }

    pause.isSelected = !pause.isSelected

    if pause.isSelected {
      pause.backgroundColor = .gray
    } else {
      pause.backgroundColor = .systemBlue
    }

    rtmpStream.paused.toggle()
  }

  @IBAction func on(publish: UIButton) {
    if publish.isSelected {
      UIApplication.shared.isIdleTimerDisabled = false
      rtmpConnection.close()
      rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
      rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
      self.publishStateView.backgroundColor = .red
      self.stopPublishTimer()
      //      if pauseButton!.isSelected {
      //        self.on(pause: pauseButton!)
      //      }
      //self.stopRecording()
    } else {
      UIApplication.shared.isIdleTimerDisabled = true
      rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
      rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
      rtmpConnection.connect(uri)
      self.publishStateView.backgroundColor = .lightGray
      self.startPublishTimer()
      //self.startRecording()
    }

    publish.isSelected.toggle()
  }

  @objc
  private func rtmpStatusHandler(_ notification: Notification) {
    let e = Event.from(notification)
    guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
      return
    }
    //logger.info(code)
    switch code {
    case RTMPConnection.Code.connectSuccess.rawValue:
      retryCount = 0
      rtmpStream!.publish(streamName)
    // sharedObject!.connect(rtmpConnection)

    case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
      guard retryCount <= PushStreamViewController.maxRetryCount else {
        return
      }
      Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
      rtmpConnection.connect(uri)
      retryCount += 1

    default:
      break
    }
  }

  @objc
  private func rtmpErrorHandler(_ notification: Notification) {
    let e = Event.from(notification)
    print("rtmpErrorHandler: \(e)")

    DispatchQueue.main.async {
      self.rtmpConnection.connect(self.uri)
    }
  }

  func tapScreen(_ gesture: UIGestureRecognizer) {
    if let gestureView = gesture.view, gesture.state == .ended {
      let touchPoint: CGPoint = gesture.location(in: gestureView)
      let pointOfInterest = CGPoint(x: touchPoint.x / gestureView.bounds.size.width, y: touchPoint.y / gestureView.bounds.size.height)
      print("pointOfInterest: \(pointOfInterest)")
      rtmpStream.setPointOfInterest(pointOfInterest, exposure: pointOfInterest)
    }
  }

  @IBAction private func resolutionValueChanged(_ segment: UISegmentedControl) {
    switch segment.selectedSegmentIndex {
    case 0:
      self.configResolution(resolution: hdResolution)
    case 1:
      self.configResolution(resolution: fhdResolution)
    default:
      break
    }
  }

  @IBAction private func onEffectValueChanged(_ segment: UISegmentedControl) {
    if let currentEffect: VideoEffect = currentEffect {
      _ = rtmpStream.unregisterVideoEffect(currentEffect)
    }
    switch segment.selectedSegmentIndex {
    case 1:
      currentEffect = CurrentTimeEffect()
      _ = rtmpStream.registerVideoEffect(currentEffect!)
    case 2:
      currentEffect = PsyEffect()
      _ = rtmpStream.registerVideoEffect(currentEffect!)
    default:
      break
    }
  }
}

extension PushStreamViewController {
  func configResolution(resolution: CGSize) {
    let captureSize = resolution.width == 720 ? AVCaptureSession.Preset.hd1280x720 : AVCaptureSession.Preset.hd1920x1080

    print(#function, captureSize, resolution.width, resolution.height)

    rtmpStream.captureSettings = [
      .sessionPreset: captureSize,
      .continuousAutofocus: true,
      .continuousExposure: true,
      .isVideoMirrored: true,
      .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
    ]

    rtmpStream.videoSettings = [
      .width: resolution.width,
      .height: resolution.height,
      .profileLevel: kVTProfileLevel_H264_High_AutoLevel
    ]

    if resolution.width == 720 {
      rtmpStream.videoSettings[.bitrate] = 1024 * 1000
      rtmpStream.captureSettings[.fps] = 29.97
    } else {
      rtmpStream.videoSettings[.bitrate] = 1024 * 1000
      rtmpStream.captureSettings[.fps] = 60
    }

    rtmpStream.audioSettings[.bitrate] = 128 * 1000
    rtmpStream.audioSettings[.muted] = false
  }

  func startPublishTimer() {
    isPublishStream = true

    publishTimer = Observable<Int>
      .interval(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance)
      .map { $0 + 1 }
      .map { self.convertToHMS(number: $0) }
      .bind(to: publishTimeLabel.rx.text)
    //      .subscribe(onNext: { sec in
    //        print(self.convertToHMS(number: sec))
    //        self.publishTimeLabel.text = self.convertToHMS(number: sec)
    //      })
  }

  func stopPublishTimer() {
    publishTimer?.dispose()
    publishTimeLabel.text = ""
  }

  func convertToHMS(number: Int) -> String {
    let hour    = number / 3600
    let minute  = (number % 3600) / 60
    let second = (number % 3600) % 60

    var h = String(hour)
    var m = String(minute)
    var s = String(second)

    if h.count == 1 {
      h = "0\(hour)"
    }
    if m.count == 1 {
      m = "0\(minute)"
    }
    if s.count == 1 {
      s = "0\(second)"
    }

    return "\(h):\(m):\(s)"
  }
}

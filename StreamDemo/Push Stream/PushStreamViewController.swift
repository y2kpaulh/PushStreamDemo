import AVFoundation
import HaishinKit
import Photos
import UIKit
import VideoToolbox
import RxSwift
import RxCocoa
import ReplayKit

final class ExampleRecorderDelegate: DefaultAVRecorderDelegate {
  static let `default` = ExampleRecorderDelegate()

  override func didFinishWriting(_ recorder: AVRecorder) {
    guard let writer: AVAssetWriter = recorder.writer else { return }
    PHPhotoLibrary.shared().performChanges({() -> Void in
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: writer.outputURL)
    }, completionHandler: { _, error -> Void in
      do {
        try FileManager.default.removeItem(at: writer.outputURL)
      } catch {
        print(error)
      }
    })
  }
}

final class PushStreamViewController: UIViewController {
  private static let maxRetryCount: Int = 5
  let preferences = UserDefaults.standard
  var uri = ""
  var streamName = "ShallWeShop-iOS"
  var storageController: StorageController = StorageController()
  let controller = RPBroadcastController()
  let recorder = RPScreenRecorder.shared()

  @IBOutlet private weak var lfView: GLHKView?
  @IBOutlet private weak var currentFPSLabel: UILabel?
  @IBOutlet private weak var publishButton: UIButton?
  @IBOutlet private weak var pauseButton: UIButton?
  @IBOutlet private weak var videoBitrateLabel: UILabel?
  @IBOutlet private weak var videoBitrateSlider: UISlider?
  @IBOutlet private weak var audioBitrateLabel: UILabel?
  @IBOutlet private weak var zoomSlider: UISlider?
  @IBOutlet private weak var audioBitrateSlider: UISlider?
  @IBOutlet private weak var fpsControl: UISegmentedControl?
  @IBOutlet private weak var effectSegmentControl: UISegmentedControl?

  private var rtmpConnection = RTMPConnection()
  private var rtmpStream: RTMPStream!
  private var sharedObject: RTMPSharedObject!
  private var currentEffect: VideoEffect?
  private var currentPosition: AVCaptureDevice.Position = .back
  private var retryCount: Int = 0
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

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

    rtmpStream.captureSettings = [
      .sessionPreset: AVCaptureSession.Preset.hd1920x1080,
      .continuousAutofocus: true,
      .continuousExposure: true,
      .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
    ]

    rtmpStream.videoSettings = [
      .width: 1080,
      .height: 1920,
      .profileLevel: kVTProfileLevel_H264_High_AutoLevel
    ]

    rtmpStream.mixer.recorder.delegate = ExampleRecorderDelegate.shared

    videoBitrateSlider?.value = Float(RTMPStream.defaultVideoBitrate) / 1024
    audioBitrateSlider?.value = Float(RTMPStream.defaultAudioBitrate) / 1024

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
        // rtmpStream.receiveVideo = false
      })
      .disposed(by: disposeBag)

    NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { _ in
        print("didBecomeActiveNotification")
        // rtmpStream.receiveVideo = true
      })
      .disposed(by: disposeBag)
  }

  override func viewWillAppear(_ animated: Bool) {
    logger.info("viewWillAppear")
    super.viewWillAppear(animated)
    rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
      logger.warn(error.description)
    }
    rtmpStream.attachCamera(DeviceUtil.device(withPosition: currentPosition)) { error in
      logger.warn(error.description)
    }

    rtmpStream.rx.observeWeakly(UInt16.self, "currentFPS", options: .new)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] fps in
        guard let self = self else { return }
        guard let currentFps = fps else { return }
        self.currentFPSLabel?.text = "\(currentFps) fps"
      })
      .disposed(by: disposeBag)

    lfView?.attachStream(rtmpStream)
  }

  override func viewWillDisappear(_ animated: Bool) {
    logger.info("viewWillDisappear")
    super.viewWillDisappear(animated)
    rtmpStream.close()
    rtmpStream.dispose()
  }

  @IBAction func rotateCamera(_ sender: UIButton) {
    logger.info("rotateCamera")
    let position: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
    rtmpStream.attachCamera(DeviceUtil.device(withPosition: position)) { error in
      logger.warn(error.description)
    }
    currentPosition = position
  }

  @IBAction func toggleTorch(_ sender: UIButton) {
    rtmpStream.torch.toggle()
  }

  @IBAction func on(slider: UISlider) {
    if slider == audioBitrateSlider {
      audioBitrateLabel?.text = "audio \(Int(slider.value))/kbps"
      rtmpStream.audioSettings[.bitrate] = slider.value * 1024
    }
    if slider == videoBitrateSlider {
      videoBitrateLabel?.text = "video \(Int(slider.value))/kbps"
      rtmpStream.videoSettings[.bitrate] = slider.value * 1024
    }
    if slider == zoomSlider {
      rtmpStream.setZoomFactor(CGFloat(slider.value), ramping: true, withRate: 5.0)
    }
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

  @IBAction func on(close: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func on(publish: UIButton) {
    if publish.isSelected {
      UIApplication.shared.isIdleTimerDisabled = false
      rtmpConnection.close()
      rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
      rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
      publish.setTitle("●", for: [])
      publish.backgroundColor = .red

      if pauseButton!.isSelected {
        self.on(pause: pauseButton!)
      }
      self.stopRecording()
    } else {
      UIApplication.shared.isIdleTimerDisabled = true
      rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
      rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
      rtmpConnection.connect(uri)
      publish.setTitle("■", for: [])
      publish.backgroundColor = .gray

      self.startRecording()
    }

    publish.isSelected.toggle()
  }

  @objc
  private func rtmpStatusHandler(_ notification: Notification) {
    let e = Event.from(notification)
    guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
      return
    }
    logger.info(code)
    storageController.save(Log(msg: "\(storageController.currentTime())\(#function) \(code)"))

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
    storageController.save(Log(msg: "\(storageController.currentTime()) rtmpErrorHandler: \(e)"))

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

  @IBAction private func onFPSValueChanged(_ segment: UISegmentedControl) {
    switch segment.selectedSegmentIndex {
    case 0:
      rtmpStream.captureSettings[.fps] = 15.0
    case 1:
      rtmpStream.captureSettings[.fps] = 30.0
    case 2:
      rtmpStream.captureSettings[.fps] = 60.0
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
      currentEffect = RotationEffect()
      _ = rtmpStream.registerVideoEffect(currentEffect!)
    case 2:
      currentEffect = PsyEffect()
      _ = rtmpStream.registerVideoEffect(currentEffect!)
    default:
      break
    }
  }
}

extension PushStreamViewController: RPPreviewViewControllerDelegate {
  //  @objc func startRecording() {
  func startRecording() {
    recorder.startRecording { [unowned self] (error) in
      if let unwrappedError = error {
        print(unwrappedError.localizedDescription)
      } else {
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop", style: .plain, target: self, action: #selector(self.stopRecording))
      }
    }
  }

  //  @objc func stopRecording() {
  func stopRecording() {
    recorder.stopRecording { [unowned self] (preview, _) in
      // self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(self.startRecording))

      if let unwrappedPreview = preview {
        unwrappedPreview.previewControllerDelegate = self
        self.present(unwrappedPreview, animated: true)
      }
    }
  }

  func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
    dismiss(animated: true)
  }
}

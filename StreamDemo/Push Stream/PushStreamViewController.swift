import AVFoundation
import HaishinKit
import Photos
import UIKit
import VideoToolbox

let sampleRate: Double = 44_100

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

  override func viewDidLoad() {
    super.viewDidLoad()

    rtmpStream = RTMPStream(connection: rtmpConnection)

    rtmpStream.captureSettings = [
      .sessionPreset: AVCaptureSession.Preset.hd1920x1080,
      .continuousAutofocus: true,
      .continuousExposure: true
      // .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
    ]
    rtmpStream.videoSettings = [
      .width: 1920,
      .height: 1080,
      .maxKeyFrameIntervalDuration: 1
    ]
    rtmpStream.audioSettings = [
      .sampleRate: sampleRate
    ]
    rtmpStream.mixer.recorder.delegate = ExampleRecorderDelegate.shared

    videoBitrateSlider?.value = Float(RTMPStream.defaultVideoBitrate) / 1024
    audioBitrateSlider?.value = Float(RTMPStream.defaultAudioBitrate) / 1024
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
    rtmpStream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)
    lfView?.attachStream(rtmpStream)
  }

  override func viewWillDisappear(_ animated: Bool) {
    logger.info("viewWillDisappear")
    super.viewWillDisappear(animated)
    rtmpStream.removeObserver(self, forKeyPath: "currentFPS")
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
    } else {
      UIApplication.shared.isIdleTimerDisabled = true
      rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
      rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
      rtmpConnection.connect(Preference.defaultInstance.uri!)
      publish.setTitle("■", for: [])
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
    switch code {
    case RTMPConnection.Code.connectSuccess.rawValue:
      retryCount = 0
      rtmpStream!.publish(Preference.defaultInstance.streamName!)
    // sharedObject!.connect(rtmpConnection)
    case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
      guard retryCount <= PushStreamViewController.maxRetryCount else {
        return
      }
      Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
      rtmpConnection.connect(Preference.defaultInstance.uri!)
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
      self.rtmpConnection.connect(Preference.defaultInstance.uri!)
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
      currentEffect = MonochromeEffect()
      _ = rtmpStream.registerVideoEffect(currentEffect!)
    case 2:
      currentEffect = PronamaEffect()
      _ = rtmpStream.registerVideoEffect(currentEffect!)
    default:
      break
    }
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    if Thread.isMainThread {
      currentFPSLabel?.text = "\(rtmpStream.currentFPS)"
    }
  }
}

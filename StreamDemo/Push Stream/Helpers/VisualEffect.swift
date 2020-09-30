import AVFoundation
import HaishinKit
import UIKit

//final class CurrentTimeEffect: VideoEffect {
//  let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
//
//  let label: UILabel = {
//    let label = UILabel()
//    label.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
//    return label
//  }()
//
//  override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
//    let now = Date()
//    label.text = now.description
//
//    UIGraphicsBeginImageContext(image.extent.size)
//    label.drawText(in: CGRect(x: 0, y: 0, width: 200, height: 200))
//    let result = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)!
//    UIGraphicsEndImageContext()
//
//    filter!.setValue(result, forKey: "inputImage")
//    filter!.setValue(image, forKey: "inputBackgroundImage")
//
//    return filter!.outputImage!
//  }
//}

final class CurrentTimeEffect: VideoEffect {
  let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
  var dateImg: CIImage?

  override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
    let now = Date()
    UIGraphicsBeginImageContext(image.extent.size)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    let attrs: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 36),
      .paragraphStyle: paragraphStyle
    ]

    let attributedString = NSAttributedString(string: now.description, attributes: attrs)

    attributedString.draw(with: CGRect(x: 0, y: 100, width: 500, height: 448), options: .usesLineFragmentOrigin, context: nil)

    dateImg = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)

    UIGraphicsEndImageContext()

    filter!.setValue(dateImg, forKey: "inputImage")
    filter!.setValue(image, forKey: "inputBackgroundImage")

    return filter!.outputImage!
  }
}

final class PsyEffect: VideoEffect {

  let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
  var currIndex = 0

  var extent = CGRect.zero {
    didSet {
      let imgArr = [UIImage(named: "win_1.png"), UIImage(named: "win_2.png"), UIImage(named: "win_3.png"), UIImage(named: "win_4.png"), UIImage(named: "win_5.png"), UIImage(named: "win_6.png"), UIImage(named: "win_7.png"), UIImage(named: "win_8.png"), UIImage(named: "win_9.png"), UIImage(named: "win_10.png"), UIImage(named: "win_11.png"), UIImage(named: "win_12.png"), UIImage(named: "win_13.png"), UIImage(named: "win_14.png"), UIImage(named: "win_15.png"), UIImage(named: "win_16.png")]

      if imgArr.count == currIndex + 1 {
        currIndex = 0
      } else {
        currIndex = currIndex + 1
      }

      let image: UIImage = imgArr[currIndex]!

      UIGraphicsBeginImageContext(extent.size)

      image.draw(at: CGPoint(x: 50, y: 100))
      gangnam = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)
      UIGraphicsEndImageContext()
    }
  }
  var gangnam: CIImage?

  override init() {
    super.init()
  }

  override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
    guard let filter: CIFilter = filter else {
      return image
    }
    extent = image.extent
    filter.setValue(gangnam!, forKey: "inputImage")
    filter.setValue(image, forKey: "inputBackgroundImage")
    return filter.outputImage!
  }

  func getSequence(gifNamed: String) -> [UIImage]? {

    guard let bundleURL = Bundle.main
            .url(forResource: gifNamed, withExtension: "gif") else {
      print("This image named \"\(gifNamed)\" does not exist!")
      return nil
    }

    guard let imageData = try? Data(contentsOf: bundleURL) else {
      print("Cannot turn image named \"\(gifNamed)\" into NSData")
      return nil
    }

    let gifOptions = [
      kCGImageSourceShouldAllowFloat as String: true as NSNumber,
      kCGImageSourceCreateThumbnailWithTransform as String: true as NSNumber,
      kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSNumber
    ] as CFDictionary

    guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, gifOptions) else {
      debugPrint("Cannot create image source with data!")
      return nil
    }

    let framesCount = CGImageSourceGetCount(imageSource)
    var frameList = [UIImage]()

    for index in 0 ..< framesCount {

      if let cgImageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) {
        let uiImageRef = UIImage(cgImage: cgImageRef)
        frameList.append(uiImageRef)
      }

    }

    return frameList // Your gif frames is ready
  }
}

final class PronamaEffect: VideoEffect {

  let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
  var currIndex = 0

  var extent = CGRect.zero {
    didSet {
      guard let imgArr = self.getSequence(gifNamed: "adventure-time") else { return }
      print("currIndex", currIndex, imgArr.count)

      if imgArr.count == currIndex + 1 {
        currIndex = 0
      } else {
        currIndex = currIndex + 1
      }

      let image: UIImage = imgArr[currIndex]

      UIGraphicsBeginImageContext(extent.size)

      image.draw(at: CGPoint(x: 50, y: 50))
      gangnam = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)
      UIGraphicsEndImageContext()
    }
  }
  var gangnam: CIImage?

  override init() {
    super.init()
  }

  override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
    guard let filter: CIFilter = filter else {
      return image
    }
    extent = image.extent
    filter.setValue(gangnam!, forKey: "inputImage")
    filter.setValue(image, forKey: "inputBackgroundImage")
    return filter.outputImage!
  }

  func getSequence(gifNamed: String) -> [UIImage]? {

    guard let bundleURL = Bundle.main
            .url(forResource: gifNamed, withExtension: "gif") else {
      print("This image named \"\(gifNamed)\" does not exist!")
      return nil
    }

    guard let imageData = try? Data(contentsOf: bundleURL) else {
      print("Cannot turn image named \"\(gifNamed)\" into NSData")
      return nil
    }

    let gifOptions = [
      kCGImageSourceShouldAllowFloat as String: true as NSNumber,
      kCGImageSourceCreateThumbnailWithTransform as String: true as NSNumber,
      kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSNumber
    ] as CFDictionary

    guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, gifOptions) else {
      debugPrint("Cannot create image source with data!")
      return nil
    }

    let framesCount = CGImageSourceGetCount(imageSource)
    var frameList = [UIImage]()

    for index in 0 ..< framesCount {

      if let cgImageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) {
        let uiImageRef = UIImage(cgImage: cgImageRef)
        frameList.append(uiImageRef)
      }

    }

    return frameList // Your gif frames is ready
  }
}

final class MonochromeEffect: VideoEffect {
  let filter: CIFilter? = CIFilter(name: "CIColorMonochrome")

  override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
    guard let filter: CIFilter = filter else {
      return image
    }
    filter.setValue(image, forKey: "inputImage")
    filter.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: "inputColor")
    filter.setValue(1.0, forKey: "inputIntensity")
    return filter.outputImage!
  }
}

final class RotationEffect: VideoEffect {
  override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
    guard #available(iOS 11.0, *),
          let info = info,
          let orientationAttachment = CMGetAttachment(info, key: "RPVideoSampleOrientationKey" as CFString, attachmentModeOut: nil) as? NSNumber,
          let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) else {
      return image
    }
    switch orientation {
    case .left:
      return image.oriented(.right)
    case .right:
      return image.oriented(.left)
    default:
      return image
    }
  }
}

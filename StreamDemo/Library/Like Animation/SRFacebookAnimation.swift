//
//  SRFacebookAnimation.swift
//  Pods-SRFacebookAnimation_Example
//
//  Created by Shamshir on 09/01/18.
//

import UIKit

public enum animationDirections {
  case rightToLeft
  case leftToRight
}
public class SRFacebookAnimation: NSObject, CAAnimationDelegate {

  var startPoint = CGPoint(x: 0, y: 200)
  var amplitude: CGFloat = 50
  var animationImage = UIImage()
  var imageDimention: Double = 20.0
  var direction = animationDirections.leftToRight
  var animationDuration: Double = 5
  var amplitudeBounce: CGFloat = 100
  var isUptrust: Bool = true

  private var imageView = UIImageView()

  public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {

    if let imageView = anim.value(forKey: "imageTag") as? UIImageView {
      imageView.removeFromSuperview()
    }

  }

  fileprivate static let shared: SRFacebookAnimation = {
    let instance = SRFacebookAnimation()
    return instance
  }()

  fileprivate func currentWindow() -> UIWindow {
    let presentedWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })

    return presentedWindow!
  }

  fileprivate func currentViewController() -> UIViewController? {
    var presentedWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let pWindow = presentedWindow?.presentedViewController {
      presentedWindow = pWindow
    }

    return presentedWindow
  }

  open class func animate(image: UIImage) {

    self.shared.animationImage = image

    let image =  self.shared.animationImage
    self.shared.imageView = UIImageView(image: image)
    let dimension = self.shared.imageDimention + drand48() * 10
    self.shared.imageView.frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)

    var endPosition = CGPoint()
    let xPos: CGFloat =  UIScreen.main.bounds.size.width - 30
    endPosition = CGPoint(x: xPos, y: 0)

    let animation = CAKeyframeAnimation(keyPath: "position")
    animation.path = self.shared.customPath(startPoint: self.shared.startPoint, endPoint: endPosition).cgPath
    animation.duration = self.shared.animationDuration + drand48() * 3
    animation.fillMode = CAMediaTimingFillMode.forwards
    animation.isRemovedOnCompletion = false
    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    animation.delegate = self.shared
    animation.setValue(self.shared.imageView, forKey: "imageTag")

    self.shared.imageView.layer.add(animation, forKey: nil)
    self.shared.currentViewController()?.view.addSubview(self.shared.imageView)
  }

  fileprivate func customPath(startPoint: CGPoint, endPoint: CGPoint) -> UIBezierPath {
    let path = UIBezierPath()

    path.move(to: startPoint)
    path.addLine(to: endPoint)

    return path
  }

  public static func startPoint(_ startPoint: CGPoint) {
    self.shared.startPoint = startPoint
  }

  public static func animationAmplitude(_ amplitude: CGFloat) {
    self.shared.amplitude = amplitude
  }

  public static func animationImage(_ image: UIImage) {
    self.shared.animationImage = image
  }

  public static func animationDirection(_ direction: animationDirections) {
    self.shared.direction = direction
  }

  public static func imageDimention(_ imageDimention: Double) {
    self.shared.imageDimention = imageDimention
  }

  public static func animationDuration(_ duration: Double) {
    self.shared.animationDuration = duration
  }

  public static func amplitudeBounce(_ magnitude: CGFloat) {
    self.shared.amplitudeBounce = magnitude
  }

  public static func isUptrust(_ flag: Bool) {
    self.shared.isUptrust = flag
  }

}

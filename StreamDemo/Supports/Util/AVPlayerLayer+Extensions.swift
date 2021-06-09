//
//  AVPlayerLayer+Extensions.swift
//  StreamDemo
//
//  Created by Inpyo Hong on 2021/06/09.
//  Copyright © 2021 Inpyo Hong. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension CGAffineTransform {
  static let ninetyDegreeRotation = CGAffineTransform(rotationAngle: .pi/2)
  static let minusNinetyDegreeRotation = CGAffineTransform(rotationAngle: -.pi/2)
}

extension AVPlayerLayer {
  var fullScreenAnimationDuration: TimeInterval {
    return 0.15
  }

  func minimizeToFrame(_ frame: CGRect) {
    UIView.animate(withDuration: fullScreenAnimationDuration) {
      self.setAffineTransform(.identity)
      self.frame = frame
    }
  }

  func goLeftFullscreen() {
    UIView.animate(withDuration: fullScreenAnimationDuration) {
      self.setAffineTransform(.ninetyDegreeRotation)
      self.frame = UIScreen.main.bounds
    }
  }

  func goRightFullscreen() {
    UIView.animate(withDuration: fullScreenAnimationDuration) {
      self.setAffineTransform(.minusNinetyDegreeRotation)
      self.frame = UIScreen.main.bounds
    }
  }
}

//
//  UIView+Extension.swift
//  Home2
//
//  Created by Kang Byeonghak on 08/11/2018.
//  Copyright © 2018 ImGATE, Inc. All rights reserved.
//

import UIKit

// MARK: - CALayer
extension UIView {
  @IBInspectable var borderWidth: CGFloat {
    get {
      return layer.borderWidth
    }
    set {
      layer.borderWidth = newValue
    }
  }

  @IBInspectable var borderColor: UIColor? {
    get {
      guard let color = layer.borderColor else { return nil }
      return UIColor(cgColor: color)
    }
    set {
      layer.borderColor = newValue?.cgColor
    }
  }

  @IBInspectable var cornerRadius: CGFloat {
    get {
      return layer.cornerRadius
    }
    set {
      layer.cornerRadius = newValue
      layer.masksToBounds = newValue > 0
    }
  }

  @IBInspectable var isCircular: Bool {
    get {
      let radius = self.frame.width/2
      return layer.cornerRadius == radius
    }
    set {
      if newValue {
        let radius = self.frame.width/2
        layer.cornerRadius = radius
      } else {
        layer.cornerRadius = 0
      }

      layer.masksToBounds = newValue
    }
  }
}

// MARK: - Reusable & Nib Loadable
protocol ReusableView: class {}

extension ReusableView where Self: UIView {
  static var reuseIdentifier: String {
    return String(describing: self)
  }
}

protocol NibLoadableView: class {}

extension NibLoadableView where Self: UIView {
  static var nibName: String {
    return String(describing: self)
  }
}

// MARK: - Generates instance of view from nib
extension UIView {
  class func instance(_ name: String? = nil, owner: Any? = nil, options: [UINib.OptionsKey: Any]? = nil) -> Self? {
    return instanceHelper(name ?? String(describing: self),
                          owner: owner,
                          options: options)
  }

  fileprivate class func instanceHelper<T>(_ name: String, owner: Any?, options: [UINib.OptionsKey: Any]? = nil) -> T? {
    guard let views = Bundle.main.loadNibNamed(name, owner: owner, options: options) else { return nil }
    return views.first as? T
  }
}

// MARK: - Animation
extension UIView {
  func setHidden(_ hidden: Bool, animated: Bool) {
    if isHidden == hidden { return }

    alpha = hidden ? 1 : 0
    isHidden = false

    UIView.animate(
      withDuration: animated ? Animations.duration : 0,
      animations: { [weak self] in
        guard let self = self else { return }
        self.alpha = hidden ? 0 : 1
      },
      completion: { [weak self] _ in
        guard let self = self else { return }
        self.isHidden = hidden
        self.alpha = 1
      }
    )
  }
}

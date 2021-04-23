//
//  UIImage+Extension.swift
//  ShallWeShop
//
//  Created by Inpyo Hong on 2020/02/27.
//  Copyright © 2020 Epiens Corp. All rights reserved.
//

import UIKit

extension UIImage {
  convenience init?(color: UIColor, size: CGSize) {
    guard let image = UIGraphicsImageRenderer(size: size).image(actions: { context in
      color.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }).cgImage else { return nil }

    self.init(cgImage: image)
  }
}

extension UIImage {
  func flipHorizontally() -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(self.size, true, self.scale)
    let context = UIGraphicsGetCurrentContext()!

    context.translateBy(x: self.size.width/2, y: self.size.height/2)
    context.scaleBy(x: -1.0, y: 1.0)
    context.translateBy(x: -self.size.width/2, y: -self.size.height/2)

    self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))

    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
  }
}

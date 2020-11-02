//
//  Utils.swift
//  ShallWeShop
//
//  Created by Inpyo Hong on 2020/07/06.
//  Copyright © 2020 Epiens Corp. All rights reserved.
//

import Foundation
import SwiftHEXColors
import SwiftyAttributes

class Utils {
  static let shared = Utils()

  struct Animations {
    static let duration = 0.25
    static let delay = 1.0
  }

  enum PagingMode: Int {
    case load = 0
    case loadMore
  }
  static let tableViewRowCount = 10

  static var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    return encoder
  }

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }

  func attributedText(_ str: String, font: UIFont, color: UIColor = .white, dropShadow: Bool = false) -> NSAttributedString {
    return str.withAttributes([
      .font(font),
      .textColor(color),
      .shadow({
        let shadow = Shadow()
        if dropShadow {
          shadow.shadowBlurRadius = 2
          shadow.shadowColor = UIColor(white: 20.0 / 255.0, alpha: 0.4)
          shadow.shadowOffset = CGSize(width: 0, height: 1)
        }
        return shadow
      }())
    ])
  }

}

//extension Utils {
//  convenience init() {
//    self.init()
//  }
//}

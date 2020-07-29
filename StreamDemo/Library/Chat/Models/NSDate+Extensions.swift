//
//  NSDate+Extensions.swift
//  ChatTest
//
//  Created by Inpyo Hong on 2020/06/22.
//  Copyright © 2020 Inpyo Hong. All rights reserved.
//

import Foundation
import UIKit

extension String {
  func localized(comment: String = "", tableName: String? = nil) -> String {
    if let value = NSLocalizedString(self, tableName: tableName, bundle: Bundle.main, value: "", comment: comment) as String? {
      return value
    }

    return self
  }

  func toDate(format: String = "yyyy-MM-dd HH:mm:ss") -> NSDate! {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    guard let date = formatter.date(from: self) else {
      return nil
    }
    return date as NSDate
  }
}

extension NSDate {
  func toLocalTimeString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
    let formatter = DateFormatter()
    formatter.timeZone = NSTimeZone.local
    formatter.dateFormat = format
    return formatter.string(from: self as Date)
  }

  func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = NSTimeZone.local
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter.string(from: self as Date)
  }

  func toRelativeString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
    let s = Int(-self.timeIntervalSinceNow)
    switch s {
    case 0...20:
      return "Now".localized()

    case 21...59:
      return "1 minute ago".localized()

    case 60...3599:
      return NSString(format: "%d minutes ago".localized() as NSString, s / 60) as String

    case 3600...7199:
      return "1 hour ago".localized()

    case 7200...86399:
      return NSString(format: "%d hours ago".localized() as NSString, s / 3600) as String

    default:
      let formatter = DateFormatter()
      formatter.timeZone = NSTimeZone.local
      formatter.dateFormat = format
      return formatter.string(from: self as Date)
    }
  }
}

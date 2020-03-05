//
//  StorageController.swift
//  StreamDemo
//
//  Created by Inpyo Hong on 2020/03/05.
//  Copyright © 2020 Inpyo Hong. All rights reserved.
//

import Foundation

class StorageController {
  private let logFileURL = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)
    .first!
    .appendingPathComponent("Log")
    .appendingPathExtension("plist")

  init() {
    guard fetchLog() == nil else {
      return
    }
  }

  public func currentTime() -> String {
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let stringDate = dateFormatter.string(from: date)

    return stringDate
  }

  func fetchLog() -> Log? {
    guard let data = try? Data(contentsOf: logFileURL) else {
      return nil
    }
    let decoder = PropertyListDecoder()
    return try? decoder.decode(Log.self, from: data)
  }

  func save(_ log: Log) {
    var totalLog: String = ""

    totalLog.append(log.msg)

    if let pastLog = fetchLog() {
      totalLog.append(pastLog.msg)
    }

    let encoder = PropertyListEncoder()
    if let data = try? encoder.encode(Log(msg: totalLog)) {
      try? data.write(to: logFileURL)
    }
  }

  func deleteAll() {
    let encoder = PropertyListEncoder()
    if let data = try? encoder.encode(Log(msg: "")) {
      try? data.write(to: logFileURL)
    }
  }
}

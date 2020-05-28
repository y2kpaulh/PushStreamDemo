//
//  RxPlayer.swift
//  RxSwiftAVPlayer
//
//  Created by Dimitrios Kalaitzidis on 24/04/2019.
//  Copyright © 2019 Dimitrios Kalaitzidis. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AVKit

struct RxPlayerItem {
  var title: String?
  var artist: String?
  var url: URL?
}

enum RxPlayerState {
  case Playing
  case Paused
  case Failed
  case Unknown
}

class RxPlayer {

  private var state = BehaviorRelay<RxPlayerState>(value: .Unknown)
  private var currentItem = BehaviorSubject<RxPlayerItem?>(value: nil)
  private var player = AVPlayer()
  private let bag = DisposeBag()

  /// RxPlayer init method
  init() {
    subscibeToState()
    subscribeToCurrentItem()
    subscribeToPlayerStatus()
  }

  private func subscibeToState() {
    state.subscribe(onNext: { [weak self] value in
      switch value {
      case .Playing:
        self?.player.play()
      case .Paused:
        self?.player.pause()
      case .Failed:
        print("Failed")
      default:
        break
      }
    }).disposed(by: bag)
  }

  private func subscribeToCurrentItem() {
    currentItem.subscribe(onNext: { [weak self] item in
      guard let url = item?.url else {
        return
      }

      self?.player.replaceCurrentItem(with: AVPlayerItem(url: url))

    }).disposed(by: bag)
  }

  private func subscribeToPlayerStatus() {
    player.rx.status.subscribe(onNext: { status in
      switch status {
      case .unknown:
        self.state.accept(.Unknown)
      case .failed:
        self.state.accept(.Failed)
      case .readyToPlay:
        self.state.accept(.Playing)
      default:
        break
      }
    }).disposed(by: bag)
  }

  /// Receive an RxPlayerItem in order to play it
  ///
  /// - Parameter item: An RxPlayerItem
  ///
  /// A comparison is made first in order to see if there is
  /// an item already on the player.
  /// If the getRxPlayerCurrentItemURL returns nil, we pass the RxPlayerItem
  /// to currentIten.onNext
  /// If the getRxPlayerCurrentItemURL returns a URL, a comparison of the URL's is made
  /// in order to change the state value
  func playItem(_ item: RxPlayerItem) {
    compareCurrentItemURL(currentItemURL: getRxPlayerCurrentItemURL(),
                          item: item)
  }

  private func getRxPlayerCurrentItemURL() -> URL? {
    return (player.currentItem?.asset as? AVURLAsset)?.url
  }

  /// Checks the player currentItemURL with the new one
  /// If the urls are the same, the state changes to .Paused or .Playing
  /// depending the previous one
  ///
  /// - Parameters:
  ///   - currentItemURL: URL?
  ///   - item: RxPlayerItem
  private func compareCurrentItemURL(currentItemURL: URL?, item: RxPlayerItem) {
    if currentItemURL != item.url {
      currentItem.onNext(item)
    }

    if currentItemURL == item.url {
      switch state.value {
      case .Paused:
        state.accept(.Playing)
      case .Playing:
        state.accept(.Paused)
      default:
        break
      }
    }
  }

}

extension Reactive where Base: AVPlayer {
  public var status: Observable<AVPlayer.Status> {
    return self.observe(AVPlayer.Status.self, #keyPath(AVPlayer.status))
      .map { $0 ?? .unknown }
  }
}

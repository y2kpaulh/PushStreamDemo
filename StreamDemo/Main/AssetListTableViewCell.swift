/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 `AssetListTableViewCell` is the `UITableViewCell` subclass that represents an `Asset`
 visually in `AssetListTableViewController`.  This cell handles responding to user
 events as well as updating itself to reflect the state of the `Asset` if it has been
 downloaded, deleted, or is actively downloading.
 */

import UIKit

class AssetListTableViewCell: UITableViewCell {
  // MARK: Properties

  static let reuseIdentifier = "AssetListTableViewCellIdentifier"

  @IBOutlet weak var assetNameLabel: UILabel!

  @IBOutlet weak var downloadStateLabel: UILabel!

  @IBOutlet weak var downloadProgressView: UIProgressView!

  weak var delegate: AssetListTableViewCellDelegate?

  var asset: Asset? {
    didSet {
      if let asset = asset {
        let downloadState = AssetPersistenceManager.sharedManager.downloadState(for: asset)

        switch downloadState {
        case .downloaded:

          downloadProgressView.isHidden = true

        case .downloading:
          downloadProgressView.isHidden = false

        case .notDownloaded:
          break
        }

        assetNameLabel.text = asset.stream.name
        downloadStateLabel.text = asset.stream.playlistURL

      } else {
        downloadProgressView.isHidden = false
        assetNameLabel.text = ""
        downloadStateLabel.text = ""
      }
    }
  }
}

protocol AssetListTableViewCellDelegate: class {

  func assetListTableViewCell(_ cell: AssetListTableViewCell, downloadStateDidChange newState: Asset.DownloadState)
}

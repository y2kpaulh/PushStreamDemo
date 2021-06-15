/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 `AssetListTableViewController` is the main interface of this sample.  It provides
 a list of the assets the sample can play, download, cancel download, and delete.
 To play an item, tap on the tableViewCell, to interact with the download APIs,
 long press on the cell and you will be provided options based on the download
 state associated with the Asset on the cell.
 */

import UIKit
import AVFoundation
import AVKit
import PictureInPicture
import FloatingPanel
import Combine

/// - Tag: AssetListTableViewController
class AssetListTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  // MARK: Properties
  @IBOutlet weak var tableView: UITableView!

  let preferences = UserDefaults.standard
  var fpc: FloatingPanelController!
  var subscriptions = Set<AnyCancellable>()

  private let contentHeightSubject = CurrentValueSubject<CGFloat, Never>(UIScreen.main.bounds.height)

  var contentHeight: AnyPublisher<CGFloat, Never> {
    return contentHeightSubject.eraseToAnyPublisher()
  }

  // MARK: Deinitialization

  deinit {
    NotificationCenter.default.removeObserver(self,
                                              name: .AssetListManagerDidLoad,
                                              object: nil)
  }

  // MARK: UIViewController

  let sb = UIStoryboard(name: "Main", bundle: nil)

  override func viewDidLoad() {
    super.viewDidLoad()

    // General setup for auto sizing UITableViewCells.
    self.tableView.estimatedRowHeight = 75.0
    self.tableView.rowHeight = UITableView.automaticDimension
    self.tableView.tableFooterView = nil

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleAssetListManagerDidLoad(_:)),
                                           name: .AssetListManagerDidLoad, object: nil)
    self.tableView.tableFooterView = UIView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  // MARK: - Table view data source

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return AssetListManager.sharedManager.numberOfAssets()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: AssetListTableViewCell.reuseIdentifier, for: indexPath)

    let asset = AssetListManager.sharedManager.asset(at: indexPath.row)

    if let cell = cell as? AssetListTableViewCell {
      cell.asset = asset
      cell.delegate = self

      if !asset.stream.name.contains("Epiens") {
        cell.accessoryType = .none
      }

      if asset.stream.name.contains("Epiens Push") {
        cell.downloadStateLabel.text = preferences.string(forKey: "pushUrl")
      } else if asset.stream.name.contains("Epiens Pull") {
        cell.downloadStateLabel.text = preferences.string(forKey: "pullUrl")
      }

    }

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? AssetListTableViewCell, let asset = cell.asset
    else { return }
    print(asset.stream.playlistURL)

    if asset.stream.name.contains("Push") {
      let vc: PushStreamViewController = sb.instantiateViewController(withIdentifier: "PushStreamViewController") as! PushStreamViewController
      //self.navigationController?.pushViewController(vc, animated: true)
      vc.modalPresentationStyle = .fullScreen
      self.present(vc, animated: true, completion: nil)
    } else {

      if indexPath.row == 1 {
        let vc: PullStreamViewController = sb.instantiateViewController(withIdentifier: "PullStreamViewController") as! PullStreamViewController
        vc.modalPresentationStyle = .fullScreen
        let urlStr = asset.stream.playlistURL
        vc.url = urlStr
        //  vc.delegate = self
        //      self.navigationController?.pushViewController(vc, animated: true)
        PictureInPicture.shared.present(with: vc)
      } else {

        //        setupFpcView()
        let vc: LandspacePullStreamViewController = sb.instantiateViewController(withIdentifier: "LandspacePullStreamViewController") as! LandspacePullStreamViewController
        let urlStr = asset.stream.playlistURL
        vc.url = urlStr
        //  vc.delegate = self
        //      self.navigationController?.pushViewController(vc, animated: true)

        // Set a content view controller.
        //        let contentVC = ContentViewController()
        //
        //        self.contentHeight
        //            .assign(to: \.viewHeight, on: contentVC)
        //            .store(in: &subscriptions)
        // fpc.set(contentViewController: vc)

        vc.modalPresentationStyle = .fullScreen

        self.present(vc, animated: true, completion: {
          self.tableView.deselectRow(at: indexPath, animated: true)
        })
      }

    }
  }

  func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? AssetListTableViewCell, let asset = cell.asset else { return }

    print(asset.stream.name)

    if asset.stream.name.contains("Epiens") {

      let vc: PreferenceViewController = sb.instantiateViewController(withIdentifier: "PreferenceViewController") as! PreferenceViewController

      if asset.stream.name.contains("Push") {
        vc.urlType = "Push"
      } else if asset.stream.name.contains("Pull") {
        vc.urlType = "Pull"
      }

      self.present(vc, animated: true, completion: nil)
    }

  }

  // MARK: Notification handling

  @objc
  func handleAssetListManagerDidLoad(_: Notification) {
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }

  @IBAction func tapDebugBtn(_ sender: Any) {

  }

  func setupFpcView() {
    // Initialize a `FloatingPanelController` object.
    fpc = FloatingPanelController(delegate: self)
    fpc.layout = LandscapeVideoVcFloatingPanelLayout()

    // Assign self as the delegate of the controller.
    fpc.delegate = self

    fpc.changePanelStyle()

    // Track a scroll view(or the siblings) in the content view controller.
    //fpc.track(scrollView: contentVC.tableView)

    // Add and show the views managed by the `FloatingPanelController` object to self.view.
    fpc.addPanel(toParent: self)
    fpc.changePanelStyle()

    // setUpSecondPanel()
  }
}

/**
 Extend `AssetListTableViewController` to conform to the `AssetListTableViewCellDelegate` protocol.
 */
extension AssetListTableViewController: AssetListTableViewCellDelegate {

  func assetListTableViewCell(_ cell: AssetListTableViewCell, downloadStateDidChange newState: Asset.DownloadState) {
    guard let indexPath = self.tableView.indexPath(for: cell) else { return }

    tableView.reloadRows(at: [indexPath], with: .automatic)
  }
}

// MARK: - VideoPlayerViewControllerDelegate
extension AssetListTableViewController: PipViewControllerDelegate {
  func PipViewController(_ videoPlayerViewController: UIViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
    if navigationController!.viewControllers.firstIndex(of: videoPlayerViewController) != nil {
      completionHandler(true)
    } else {
      //      navigationController!.pushViewController(videoPlayerViewController, animated: true)
      //      completionHandler(true)
      self.present(videoPlayerViewController, animated: true)
      completionHandler(true)
    }
  }
}

extension AssetListTableViewController: FloatingPanelControllerDelegate {
  func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
    print(#function, fpc.state)

    switch fpc.state {
    case .full:
      print("full state")
    case .tip:
      print("tip state")

    default: break
    }
  }

  func floatingPanel(_ vc: FloatingPanelController, layoutFor size: CGSize) -> FloatingPanelLayout {
    print(#function, size)
    return LandscapeVideoVcFloatingPanelLayout()
  }

  func floatingPanelDidMove(_ fpc: FloatingPanelController) {
    guard fpc.surfaceLocation.y > 0 && UIScreen.main.bounds.height - fpc.surfaceLocation.y >= 100 else { return }
    print(#function, UIScreen.main.bounds.height - fpc.surfaceLocation.y)

    self.contentHeightSubject.send(UIScreen.main.bounds.height - fpc.surfaceLocation.y)
  }
}

extension FloatingPanelController {
  func changePanelStyle() {
    let appearance = SurfaceAppearance()
    let shadow = SurfaceAppearance.Shadow()
    shadow.color = UIColor.black
    shadow.offset = CGSize(width: 0, height: -1.0)
    shadow.opacity = 0.15
    shadow.radius = 2
    appearance.shadows = [shadow]
    appearance.cornerRadius = 0//15.0

    appearance.backgroundColor = .clear
    appearance.borderColor = .clear
    appearance.borderWidth = 0

    surfaceView.grabberHandle.isHidden = true

    surfaceView.appearance = appearance
  }
}

class LandscapeVideoVcFloatingPanelLayout: FloatingPanelLayout {
  let position: FloatingPanelPosition = .bottom
  let initialState: FloatingPanelState = .full
  var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
    return [
      .full: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .superview),
      //            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
      .tip: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .bottom, referenceGuide: .safeArea)
    ]
  }
}

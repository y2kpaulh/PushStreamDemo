import UIKit

final class PreferenceViewController: UIViewController {
  var urlType = ""
  var url = ""
  var stream = ""
  let preferences = UserDefaults.standard

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var urlField: UITextField?
  @IBOutlet weak var streamLabel: UILabel!
  @IBOutlet weak var streamNameField: UITextField?
  @IBOutlet weak var saveBtn: UIButton!

  override func viewDidLoad() {

    saveBtn.addTarget(self, action: #selector(tapSaveBtn(sender:)), for: .touchUpInside)

    titleLabel.text = "Epiens \(urlType) URL Setting"

    switch urlType {
    case "Push":
      guard let pushUrl = preferences.string(forKey: "pushUrl") else { return }
      guard let streamKey = preferences.string(forKey: "streamKey") else { return }
      urlField!.text = pushUrl
      streamNameField!.text = streamKey

    case "Pull":
      guard let pullUrl = preferences.string(forKey: "pullUrl") else { return }
      urlField!.text = pullUrl
      streamLabel.isHidden = true
      streamNameField?.isHidden = true

    default: break
    }
  }

  @objc public func tapSaveBtn(sender: UIButton) {
    print(#function)

    switch urlType {
    case "Push":
      preferences.set(urlField!.text, forKey: "pushUrl")
      preferences.set(streamNameField!.text, forKey: "streamKey")

    case "Pull":
      preferences.set(urlField!.text, forKey: "pullUrl")

    default: break
    }

    preferences.synchronize()
  }
}

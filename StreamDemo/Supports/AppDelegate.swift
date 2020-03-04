import AVFoundation
import HaishinKit
import Logboard
import UIKit

let logger = Logboard.with("com.epiens.livestream")

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

    Logboard.with(HaishinKitIdentifier).level = .trace

    AssetPersistenceManager.sharedManager.restorePersistenceManager()

    return true
  }
}

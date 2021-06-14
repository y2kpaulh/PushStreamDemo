import AVFoundation
import HaishinKit
import Logboard
import UIKit
import IQKeyboardManager
import Combine

//let logger = Logboard.with("com.epiens.livestream")

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

  var orientationLock = CurrentValueSubject<UIInterfaceOrientationMask, Never>(.portrait)

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

    //Logboard.with(HaishinKitIdentifier).level = .trace

    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
    } catch {
      //TODO
      print("AVAudioSessionCategoryPlayback error")
    }

    AssetPersistenceManager.sharedManager.restorePersistenceManager()

    let preferences = UserDefaults.standard

    if preferences.string(forKey: "pushUrl") == nil {
      preferences.set("rtmp://epiensup1.xst.kinxcdn.com/epiens/", forKey: "pushUrl")
      preferences.set("test1", forKey: "streamKey")
      preferences.set("http://epiens.xst.kinxcdn.com/epiens/test1/playlist.m3u8", forKey: "pullUrl")

      preferences.synchronize()
    }

    // IQKeyboardManager
    IQKeyboardManager.shared().isEnabled = true
    IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    IQKeyboardManager.shared().keyboardDistanceFromTextField = 15
    IQKeyboardManager.shared().overrideKeyboardAppearance = true
    IQKeyboardManager.shared().keyboardAppearance = .light

    return true
  }

  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return self.orientationLock.value
  }

}

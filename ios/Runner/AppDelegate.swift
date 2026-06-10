import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let path = Bundle.main.path(forResource: "flutter_assets/.env", ofType: nil),
       let content = try? String(contentsOfFile: path, encoding: .utf8) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count >= 2, parts[0].trimmingCharacters(in: .whitespacesAndNewlines) == "GOOGLE_MAPS_API_KEY" {
                let apiKey = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                GMSServices.provideAPIKey(apiKey)
                break
            }
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

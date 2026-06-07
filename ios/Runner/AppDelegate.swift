import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = googleMapsApiKeyFromEnv() {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Reads GOOGLE_MAPS_API_KEY from the bundled .env Flutter asset so the key
  // stays out of source — the Maps SDK needs it before the Dart engine (and
  // thus flutter_dotenv) starts, so we parse the same .env file natively here.
  private func googleMapsApiKeyFromEnv() -> String? {
    let assetKey = FlutterDartProject.lookupKey(forAsset: ".env")
    guard let path = Bundle.main.path(forResource: assetKey, ofType: nil),
      let contents = try? String(contentsOfFile: path, encoding: .utf8)
    else {
      return nil
    }
    for line in contents.split(separator: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("GOOGLE_MAPS_API_KEY=") {
        return String(trimmed.dropFirst("GOOGLE_MAPS_API_KEY=".count))
      }
    }
    return nil
  }
}

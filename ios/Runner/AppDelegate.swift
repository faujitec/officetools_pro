import Flutter
import UIKit

/// Root VC so we can react to light/dark mode changes (not available on FlutterAppDelegate).
@objc class HostBackgroundFlutterViewController: FlutterViewController {
  var onColorAppearanceChange: (() -> Void)?

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      onColorAppearanceChange?()
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let hostVC = window?.rootViewController as? HostBackgroundFlutterViewController {
      hostVC.onColorAppearanceChange = { [weak self] in
        self?.applyHostBackground()
      }
    }
    applyHostBackground()
    return ok
  }

  /// Match Flutter scaffold so gaps under the Metal layer are not bright white / pure black.
  private func applyHostBackground() {
    let style = window?.traitCollection.userInterfaceStyle ?? .unspecified
    let bg: UIColor
    switch style {
    case .dark:
      bg = UIColor(red: 18 / 255, green: 18 / 255, blue: 18 / 255, alpha: 1)
    default:
      bg = UIColor(red: 242 / 255, green: 242 / 255, blue: 247 / 255, alpha: 1)
    }
    window?.backgroundColor = bg
    if let flutterVC = window?.rootViewController as? FlutterViewController {
      flutterVC.view.backgroundColor = bg
    }
  }
}

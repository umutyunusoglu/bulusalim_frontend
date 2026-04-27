import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let instagramStoryChannelName = "outnest/share/instagram_story"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: instagramStoryChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "shareToInstagramStory" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let args = call.arguments as? [String: Any],
          let message = args["message"] as? String,
          let link = args["link"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "Missing message or link",
              details: nil
            )
          )
          return
        }

        result(self?.shareToInstagramStory(message: message, link: link) ?? false)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func shareToInstagramStory(message: String, link: String) -> Bool {
    guard let linkUrl = URL(string: link) else { return false }

    let instagramUrl = URL(string: "instagram-stories://share")!
    guard UIApplication.shared.canOpenURL(instagramUrl) else {
      return false
    }

    guard let stickerData = makeStickerImageData(message: message, link: link) else {
      return false
    }

    let pasteboardItems: [[String: Any]] = [
      [
        "com.instagram.sharedSticker.stickerImage": stickerData,
        "com.instagram.sharedSticker.contentURL": linkUrl,
        "com.instagram.sharedSticker.backgroundTopColor": "#102A43",
        "com.instagram.sharedSticker.backgroundBottomColor": "#243B53",
      ]
    ]

    UIPasteboard.general.setItems(
      pasteboardItems,
      options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
    )

    UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
    return true
  }

  private func makeStickerImageData(message: String, link: String) -> Data? {
    let size = CGSize(width: 1080, height: 1080)
    let renderer = UIGraphicsImageRenderer(size: size)

    let image = renderer.image { context in
      UIColor.clear.setFill()
      context.fill(CGRect(origin: .zero, size: size))

      let cardRect = CGRect(x: 80, y: 240, width: size.width - 160, height: 600)
      let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 42)
      UIColor.white.withAlphaComponent(0.92).setFill()
      cardPath.fill()

      let paragraph = NSMutableParagraphStyle()
      paragraph.alignment = .center

      let titleText = "Outnest"
      let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 66),
        .foregroundColor: UIColor.black,
        .paragraphStyle: paragraph,
      ]
      titleText.draw(
        in: CGRect(x: 120, y: 320, width: size.width - 240, height: 90),
        withAttributes: titleAttributes
      )

      let bodyText = "\(message)\n\n\(link)"
      let bodyAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 40, weight: .medium),
        .foregroundColor: UIColor.darkGray,
        .paragraphStyle: paragraph,
      ]
      bodyText.draw(
        in: CGRect(x: 140, y: 450, width: size.width - 280, height: 340),
        withAttributes: bodyAttributes
      )
    }

    return image.pngData()
  }
}

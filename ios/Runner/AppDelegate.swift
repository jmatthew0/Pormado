import Flutter
import UIKit
import Vision
import CoreImage

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "pormado/cutout",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "cutout", let args = call.arguments as? FlutterStandardTypedData else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let out = AppDelegate.cutout(args.data)
        DispatchQueue.main.async {
          result(out.map { FlutterStandardTypedData(bytes: $0) })
        }
      }
    }
  }

  /// Lifts the foreground subject out of the photo (iOS 17+). Returns a cropped PNG, or nil.
  static func cutout(_ data: Data) -> Data? {
    guard #available(iOS 17.0, *) else { return nil }
    guard let src = UIImage(data: data) else { return nil }

    // Normalise orientation and cap the size.
    let maxSide: CGFloat = 1600
    let scale = min(1, maxSide / max(src.size.width, src.size.height))
    let size = CGSize(width: src.size.width * scale, height: src.size.height * scale)
    let fmt = UIGraphicsImageRendererFormat()
    fmt.scale = 1
    let upright = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
      src.draw(in: CGRect(origin: .zero, size: size))
    }
    guard let cg = upright.cgImage else { return nil }

    let handler = VNImageRequestHandler(cgImage: cg, options: [:])
    let request = VNGenerateForegroundInstanceMaskRequest()
    do {
      try handler.perform([request])
      guard let obs = request.results?.first else { return nil }
      let buffer = try obs.generateMaskedImage(
        ofInstances: obs.allInstances,
        from: handler,
        croppedToInstancesExtent: true
      )
      let ci = CIImage(cvPixelBuffer: buffer)
      guard let out = CIContext().createCGImage(ci, from: ci.extent) else { return nil }
      return UIImage(cgImage: out).pngData()
    } catch {
      return nil
    }
  }
}
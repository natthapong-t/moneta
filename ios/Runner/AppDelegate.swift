import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      AppleVisionPlugin.registerWithMessenger(controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    AppleVisionPlugin.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "AppleVisionPlugin"))
  }
}

public class AppleVisionPlugin: NSObject, FlutterPlugin {
  private static var shared: AppleVisionPlugin?

  public static func register(with registrar: FlutterPluginRegistrar) {
    guard shared == nil else { return }
    let channel = FlutterMethodChannel(name: "moneta/apple_vision", binaryMessenger: registrar.messenger())
    let instance = AppleVisionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    shared = instance
  }

  public static func registerWithMessenger(_ messenger: FlutterBinaryMessenger) {
    guard shared == nil else { return }
    let channel = FlutterMethodChannel(name: "moneta/apple_vision", binaryMessenger: messenger)
    let instance = AppleVisionPlugin()
    channel.setMethodCallHandler { (call, result) in
      instance.handle(call, result: result)
    }
    shared = instance
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "recognizeSlip" {
      guard let args = call.arguments as? [String: Any],
            let filePath = args["filePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "filePath is required", details: nil))
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        self.processSlip(filePath: filePath, result: result)
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  private func processSlip(filePath: String, result: @escaping FlutterResult) {
    let fileUrl = URL(fileURLWithPath: filePath)
    guard FileManager.default.fileExists(atPath: filePath) else {
      DispatchQueue.main.async {
        result(FlutterError(code: "FILE_NOT_FOUND", message: "File does not exist: \(filePath)", details: nil))
      }
      return
    }

    let barcodeRequest = VNDetectBarcodesRequest()
    barcodeRequest.symbologies = [.qr]

    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = .accurate
    textRequest.usesLanguageCorrection = true

    if #available(iOS 16.0, *) {
      textRequest.revision = VNRecognizeTextRequestRevision3
      textRequest.recognitionLanguages = ["th-TH", "en-US"]
    } else {
      textRequest.recognitionLanguages = ["en-US"]
    }

    let handler = VNImageRequestHandler(url: fileUrl, options: [:])

    do {
      try handler.perform([barcodeRequest, textRequest])

      // 1. Extract QR payload
      var qrCodes: [String] = []
      if let barcodes = barcodeRequest.results {
        for barcode in barcodes {
          if let payload = barcode.payloadStringValue, !payload.isEmpty {
            qrCodes.append(payload)
          }
        }
      }

      // 2. Extract OCR text lines sorted top-to-bottom
      var textLines: [String] = []
      if let observations = textRequest.results {
        // Vision coordinates: (0,0) is bottom-left, (1,1) is top-right.
        // Higher midY means higher up on the slip image.
        let sortedObservations = observations.sorted { (a, b) -> Bool in
          let yDiff = abs(a.boundingBox.midY - b.boundingBox.midY)
          if yDiff > 0.015 {
            return a.boundingBox.midY > b.boundingBox.midY
          }
          return a.boundingBox.minX < b.boundingBox.minX
        }

        for obs in sortedObservations {
          if let candidate = obs.topCandidates(1).first {
            let str = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !str.isEmpty {
              textLines.append(str)
            }
          }
        }
      }

      let fullText = textLines.joined(separator: "\n")

      DispatchQueue.main.async {
        result([
          "qrCodes": qrCodes,
          "text": fullText
        ])
      }
    } catch {
      DispatchQueue.main.async {
        result(FlutterError(code: "VISION_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }
}


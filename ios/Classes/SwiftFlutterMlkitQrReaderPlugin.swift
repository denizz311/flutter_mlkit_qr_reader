import Flutter
import UIKit

public class SwiftFlutterMlkitQrReaderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_mlkit_qr_reader", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMlkitQrReaderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}

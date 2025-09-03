import Foundation
import Flutter

@objc class PluginRegistrantWrapper: NSObject {
    @objc static func register(with registry: FlutterPluginRegistry) {
        // We need to call the Objective-C method from here
        // This will be done through direct symbol linking
    }
}

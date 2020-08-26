import Flutter
import UIKit

import MAMapKit
import AMapLocationKit

public class SwiftXhamapPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    var locationDelegate: AMapLocationDelegate?
    var viewFactory: AMapViewFactory?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let initialChannel = FlutterMethodChannel(name: "com.pgy/amap_initial", binaryMessenger: registrar.messenger())
        let locationChannel = FlutterMethodChannel(name: "com.pgy/amap_location", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.pgy/amap_location_stream", binaryMessenger: registrar.messenger())
        let mapViewChannel = FlutterMethodChannel(name: "xh.zero/amap_view_method", binaryMessenger: registrar.messenger())
        let instance = SwiftXhamapPlugin()
        registrar.addMethodCallDelegate(instance, channel: initialChannel)
        registrar.addMethodCallDelegate(instance, channel: locationChannel)
        registrar.addMethodCallDelegate(instance, channel: mapViewChannel)
        eventChannel.setStreamHandler(instance)
        
        // 注册高德地图定位插件
        instance.locationDelegate = AMapLocationDelegate()
    
        // 注册高德地图
        let controller = (UIApplication.shared.delegate?.window?!.rootViewController)!
        instance.viewFactory = AMapViewFactory(mapViewChannel, vc: controller)
        if let viewFactory = instance.viewFactory {
            registrar.register(viewFactory, withId: "xh.zero/amap_view")
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initial":
            if let arguments = call.arguments as? Dictionary<String, Any?>,
                let apiKey = arguments["apiKey"] as? String {
                AMapServices.shared()?.apiKey = apiKey
                print("initial location: \(apiKey)")
                result(nil)
            } else {
                result(FlutterError(code: "100", message: "初始化失败", details: nil))
            }
        case "startLocation":
            locationDelegate?.startLocation()
            result(nil)
        case "locateMyLocation":
            viewFactory?.locateMyPosition()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    //MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        locationDelegate?.setEventSink(sink: events)
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationDelegate?.setEventSink(sink: nil)
        return nil
    }
}

import Flutter
import UIKit

import MAMapKit
import AMapLocationKit

public class SwiftXhamapPlugin: NSObject, FlutterPlugin, AMapLocationManagerDelegate, FlutterStreamHandler {
    
    lazy var locationManager = AMapLocationManager()
    var eventSink: FlutterEventSink!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let initialChannel = FlutterMethodChannel(name: "com.pgy/amap_initial", binaryMessenger: registrar.messenger())
        let locationChannel = FlutterMethodChannel(name: "com.pgy/amap_location", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.pgy/amap_location_stream", binaryMessenger: registrar.messenger())
        let instance = SwiftXhamapPlugin()
        registrar.addMethodCallDelegate(instance, channel: initialChannel)
        registrar.addMethodCallDelegate(instance, channel: locationChannel)
        eventChannel.setStreamHandler(instance)
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
            locationManager.delegate = self
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.allowsBackgroundLocationUpdates = true
            
            locationManager.distanceFilter = 200
            locationManager.locatingWithReGeocode = true
            
            locationManager.startUpdatingLocation()
            
            print("start location")
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
        result("iOS " + UIDevice.current.systemVersion)
    }
    
    //MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    //MARK: - AMapLocationManagerDelegate
    public func amapLocationManager(_ manager: AMapLocationManager!, doRequireLocationAuth locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
    
    public func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
        let error = error as NSError
        NSLog("didFailWithError:{\(error.code) - \(error.localizedDescription)};")
    }
    
    public func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!, reGeocode: AMapLocationReGeocode!) {
        
        NSLog("location:{lat:\(location.coordinate.latitude); lon:\(location.coordinate.longitude); accuracy:\(location.horizontalAccuracy)};");
        if let reGeocode = reGeocode {
            NSLog("reGeocode: %@", reGeocode)
            eventSink([
                "address": reGeocode.formattedAddress ?? "",
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude
            ])
        } else {
            eventSink(FlutterError(code: "102", message: "获取地址失败", details: nil))
        }
    }
}

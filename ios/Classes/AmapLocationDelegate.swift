//
//  Test.swift
//  Pods-Runner
//
//  Created by xionghao on 2020/7/24.
//

import MAMapKit
import AMapLocationKit

// 高德定位
class AMapLocationDelegate: NSObject, AMapLocationManagerDelegate {
    
    lazy var locationManager = AMapLocationManager()
    var eventSink: FlutterEventSink!
    private var methodChannel: FlutterMethodChannel
    
    private let defaultLocationTimeout = 6
    private let defaultReGeocodeTimeout = 3
    
    init(channel: FlutterMethodChannel) {
        methodChannel = channel
        super.init()
        initial()
    }
    
    public func setEventSink(sink: FlutterEventSink?) {
        eventSink = sink;
    }
    
    public func initial() {
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 200
        locationManager.locatingWithReGeocode = true
        
        locationManager.locationTimeout = defaultLocationTimeout
        locationManager.reGeocodeTimeout = defaultReGeocodeTimeout
//        locationManager.startUpdatingLocation()
    }
    
    public func startLocation() {
        locationManager.startUpdatingLocation()
    }
    
    public func locateOnce() {
        locationManager.requestLocation(withReGeocode: true, completionBlock: { [weak self] (location: CLLocation?, regeocode: AMapLocationReGeocode?, error: Error?) in
            if let error = error {
                let error = error as NSError
                
                if error.code == AMapLocationErrorCode.locateFailed.rawValue {
                    //定位错误：此时location和regeocode没有返回值，不进行annotation的添加
                    NSLog("定位错误:{\(error.code) - \(error.localizedDescription)};")
                    return
                }
                else if error.code == AMapLocationErrorCode.reGeocodeFailed.rawValue
                    || error.code == AMapLocationErrorCode.timeOut.rawValue
                    || error.code == AMapLocationErrorCode.cannotFindHost.rawValue
                    || error.code == AMapLocationErrorCode.badURL.rawValue
                    || error.code == AMapLocationErrorCode.notConnectedToInternet.rawValue
                    || error.code == AMapLocationErrorCode.cannotConnectToHost.rawValue {
                    
                    //逆地理错误：在带逆地理的单次定位中，逆地理过程可能发生错误，此时location有返回值，regeocode无返回值，进行annotation的添加
                    NSLog("逆地理错误:{\(error.code) - \(error.localizedDescription)};")
                }
                else {
                    //没有错误：location有返回值，regeocode是否有返回值取决于是否进行逆地理操作，进行annotation的添加
                }
            }
            
            //根据定位信息，添加annotation
            if let location = location {
                self?.methodChannel.invokeMethod("onOnceLocation", arguments: [
                    "lat": location.coordinate.latitude,
                    "lng": location.coordinate.longitude,
                    "province": regeocode?.province ?? "",
                    "district": regeocode?.district ?? "",
                    "city": regeocode?.city ?? "",
                    "address": regeocode?.formattedAddress ?? ""
                ])
            }
        })
    }
    
    public func stopLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    //MARK: - AMapLocationManagerDelegate
    public func amapLocationManager(_ manager: AMapLocationManager!, doRequireLocationAuth locationManager: CLLocationManager!) {
        // 定位权限申请
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

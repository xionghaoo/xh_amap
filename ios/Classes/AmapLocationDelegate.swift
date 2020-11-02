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
    
    public func setEventSink(sink: FlutterEventSink?) {
        eventSink = sink;
    }
    
    public func startLocation() {
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        
        locationManager.distanceFilter = 200
        locationManager.locatingWithReGeocode = true
        
        locationManager.startUpdatingLocation()
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

//
//  MapViewFactory.swift
//  Pods-Runner
//
//  Created by xionghao on 2020/7/24.
//

import UIKit
import SwiftyJSON

class AMapViewFactory: NSObject, FlutterPlatformViewFactory {
    
    let methodChannel: FlutterMethodChannel
//    let eventChannel: FlutterEventChannel
    let viewController: UIViewController
    private var mapView: AMapView?
//    private var eventSink: FlutterEventSink!
//    private var addressMapView: ClusterMapView?
    
    init(_ channel: FlutterMethodChannel, vc: UIViewController) {
        self.methodChannel = channel
        self.viewController = vc
        super.init()
        
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        print("args: \(args!)")
        var amapParam: AMapParam? = nil
        do {
            if let param = args! as? String,
                let jsonData = param.data(using: .utf8, allowLossyConversion: false) {
                amapParam = try JSONDecoder().decode(AMapParam.self, from: jsonData)
            }
        } catch let e {
            print("has error: \(e)")
        }
        mapView = AMapView(viewController, param: amapParam, channel: methodChannel)
        return mapView!
//        if amapParam?.mapType == AMapParam.addressDescriptionMap {
//            addressMapView = ClusterMapView(viewController, param: amapParam, channel: methodChannel)
//            return addressMapView!
//        } else {
//            mapView = AMapView(viewController, param: amapParam, channel: methodChannel)
//            return mapView!
//        }
    }
    
    // 为地图创建消息解码器，和dart端保持一致
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    func locateMyPosition() {
        mapView?.reLocate()
//        addressMapView?.reLocate()
    }
    
    func zoomIn() {
        mapView?.zoomIn()
    }
    
    func zoomOut() {
        mapView?.zoomOut()
    }
    
    func updateMarkers(addressList: Array<AddressInfo>?) {
        mapView?.updateMarkers(addressList: addressList)
    }
    
    func clickMarker(_ id: Int, _ showType: Int) {
        mapView?.clickMarker(id: id, showType: showType)
    }

//    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//        eventSink = events
//        return nil
//    }
//
//    func onCancel(withArguments arguments: Any?) -> FlutterError? {
//        eventSink = nil
//        return nil
//    }
}

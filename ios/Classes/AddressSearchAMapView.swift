//
//  AddressSearchAMapView.swift
//  xhamap
//
//  Created by xionghao on 2020/10/28.
//

import UIKit
import AMapLocationKit
import Toast_Swift

class AddressSearchAMapView: NSObject, FlutterPlatformView, MAMapViewDelegate, AMapSearchDelegate, AMapLocationManagerDelegate {
    
    private var mapView: MAMapView!
    private let viewController: UIViewController
    private let param: AMapParam?
    var search: AMapSearchAPI!
    
    private let defaultLocationTimeout = 6
    private let defaultReGeocodeTimeout = 3
    private lazy var locationManager = AMapLocationManager()
    
    private var myPositionAnnotation: MAPointAnnotation?
    
    private let methodChannel: FlutterMethodChannel
    
    init(_ viewController: UIViewController, param: AMapParam?, channel: FlutterMethodChannel) {
        self.viewController = viewController
        self.param = param
        self.methodChannel = channel
        super.init()
        
        initMapView()
        initSearch()
        configMap()
        configLocationManager()
        addMyMarker()
        
    }
    
    func view() -> UIView {
        mapView
    }
    
    // MARK: - 初始化
    func initMapView() {
        mapView = MAMapView(frame: self.viewController.view.bounds)
        mapView.delegate = self
        self.viewController.view.addSubview(mapView!)
    }
    
    func initSearch() {
        search = AMapSearchAPI()
        search.delegate = self
    }
    
    func configMap() {
        // 设置缩放等级
        if let param = param {
            mapView.setZoomLevel(param.initialZoomLevel, animated: true)
        }
        // 设置地图中心
        if let centerPoint = param?.initialCenterPoint {
            self.mapView.setCenter(CLLocationCoordinate2D(latitude: centerPoint[0], longitude: centerPoint[1]), animated: true)
        }
        // 禁止3D旋转
        self.mapView.isRotateEnabled = false
        // 禁止2D旋转
        self.mapView.isRotateCameraEnabled = false
        
    }
    
    func configLocationManager() {
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.allowsBackgroundLocationUpdates = true
        
        locationManager.locationTimeout = defaultLocationTimeout
        
        locationManager.reGeocodeTimeout = defaultReGeocodeTimeout
    }
    
    func addMyMarker() {
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "my_location_lat")
        let lng = defaults.double(forKey: "my_location_lng")
        if lat != 0 && lng != 0 {
            myPositionAnnotation = MAPointAnnotation()
            myPositionAnnotation?.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            myPositionAnnotation?.title = "我的位置"
            self.mapView.addAnnotation(myPositionAnnotation)
        } else {
            reLocate(isInitial: true)
        }
    }
    
    // MARK: - 保存本地位置坐标
    private func saveCurrentPosition(location: CLLocation!) {
        let defaults = UserDefaults.standard
        defaults.set(location.coordinate.latitude, forKey: "my_location_lat")
        defaults.set(location.coordinate.longitude, forKey: "my_location_lng")
    }
    
    // MARK: - 定位相关
    func reLocate(isInitial: Bool = false) {
        locationManager.requestLocation(withReGeocode: false, completionBlock: { [weak self] (location: CLLocation?, regeocode: AMapLocationReGeocode?, error: Error?) in
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
                if (self?.myPositionAnnotation == nil) {
                    self?.myPositionAnnotation = MAPointAnnotation()
                    self?.myPositionAnnotation?.coordinate = location.coordinate
                    self?.myPositionAnnotation?.title = "我的位置"
                    self?.mapView.addAnnotation(self?.myPositionAnnotation!)
                } else {
                    self?.myPositionAnnotation?.coordinate = location.coordinate
                }
                // 更新本地缓存的位置信息
                self?.saveCurrentPosition(location: location)
                self?.mapView.setCenter(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), animated: true)
//                if (isInitial) {
//                    // 初始化我的位置，并和门店位置一起显示在屏幕上
//                    self?.addMerchantMarkers()
//                } else {
//                    self?.mapView.setCenter(location.coordinate, animated: true)
//                }
            }
        })
    }
    
    func addAnnotationsToMapView(_ annotation: MAAnnotation) {
        mapView.addAnnotation(annotation)
        
        mapView.selectAnnotation(annotation, animated: true)
        mapView.setCenter(annotation.coordinate, animated: true)
    }
    
    //MARK: - AMapLocationManagerDelegate
    
    func amapLocationManager(_ manager: AMapLocationManager!, doRequireLocationAuth locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
    
    //MARK: - MAMapViewDelegate
    // marker渲染回调
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation.isKind(of: MAPointAnnotation.self) {
            let pointReuseIndetifier = "pointReuseIndetifier"
            var annotationView: MAAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier)
            
            if annotationView == nil {
                annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
                annotationView!.canShowCallout = true
                annotationView!.isDraggable = false
            }
            
            annotationView!.image = nil
            
            // 渲染我的位置Marker
            if annotation.title == "我的位置" {
                if let image = UIImage(named: "ic_my_position") {
//                        annotationView!.image = scaleImage(inImage: image, scaleWidth: 50, scaleHeight: 50 / 140 * 112)
                    annotationView!.image = image
                }
            }
            return annotationView!
        }
        
        return nil
    }
}

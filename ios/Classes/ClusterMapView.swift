//
//  AddressSearchAMapView.swift
//  xhamap
//
//  Created by xionghao on 2020/10/28.
//

import UIKit
import AMapLocationKit
import Toast_Swift

class ClusterMapView: NSObject, FlutterPlatformView, MAMapViewDelegate, AMapSearchDelegate, AMapLocationManagerDelegate, CustomCalloutViewTapDelegate {
    
    private var mapView: MAMapView!
    private let viewController: UIViewController
    private let param: AMapParam?
    var search: AMapSearchAPI!
    
    private let defaultLocationTimeout = 6
    private let defaultReGeocodeTimeout = 3
    private lazy var locationManager = AMapLocationManager()
    
    private var myPositionAnnotation: MAPointAnnotation?
    
    private var annotationMap: [MAPointAnnotation:AddressInfo] = [:]
    
    private let methodChannel: FlutterMethodChannel
    
    private var circle: MACircle?
    
    // 点聚合
    var coordinateQuadTree = CoordinateQuadTree()
    var shouldRegionChangeReCalculate = false
    
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
        self.mapView.showsScale = true
        
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
            
            addMerchantMarkers()
        } else {
            reLocate(isInitial: true)
        }
    }
    
    func addMerchantMarkers() {
        if let merchantAddrList = param?.merchantAddressList {
            //            var lats = Array<Double>()
            //            var lngs = Array<Double>()
            var annoList = Array<MAPointAnnotation>()
            if let anno = myPositionAnnotation {
                annoList.append(anno)
            }
            var pois = Array<AMapPOI>()
            merchantAddrList.forEach({ addr in
                if let lat = addr.geo?.lat,
                    let lng = addr.geo?.lng {
                    
                    let anno = MAPointAnnotation()
                    anno.coordinate = CLLocationCoordinate2DMake(lat, lng)
                    anno.title = addr.address
                    annotationMap[anno] = addr
                    
                    self.mapView.addAnnotation(anno)
                    
                    annoList.append(anno)
                    let poi = AMapPOI()
                    poi.location = AMapGeoPoint()
                    poi.location.latitude = CGFloat(lat)
                    poi.location.longitude = CGFloat(lng)
                    pois.append(poi)
                }
            })
            coordinateQuadTree.build(withPOIs: pois)
            shouldRegionChangeReCalculate = true
            addAnnotations(toMapView: (mapView)!)
            // 显示所有的marker点
            self.mapView.showAnnotations(annoList, edgePadding: UIEdgeInsets(top: 100, left: 40, bottom: 100, right: 40), animated: true)
            
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
            
                if (isInitial) {
                    // 初始化我的位置，并和门店位置一起显示在屏幕上
                    self?.addMerchantMarkers()
                } else {
                    self?.mapView.setCenter(location.coordinate, animated: true)
                }
            }
        })
    }
    
//    func addAnnotationsToMapView(_ annotation: MAAnnotation) {
//        mapView.addAnnotation(annotation)
//
//        mapView.selectAnnotation(annotation, animated: true)
//        mapView.setCenter(annotation.coordinate, animated: true)
//
//
//    }
    
    //MARK: - AMapLocationManagerDelegate
    func amapLocationManager(_ manager: AMapLocationManager!, doRequireLocationAuth locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
    
    //MARK: - MAMapViewDelegate
    
    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        addAnnotations(toMapView: self.mapView)
    }
    
    func mapView(_ mapView: MAMapView!, mapDidZoomByUser wasUserAction: Bool) {
        let zoomLevel = mapView.zoomLevel
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "my_location_lat")
        let lng = defaults.double(forKey: "my_location_lng")
    
        if (zoomLevel > 11) {
            // 门店级别
            if circle != nil {
                mapView.remove(circle)
                circle = nil
            }
        } else if (zoomLevel > 10 && zoomLevel <= 11) {
            if circle == nil {
                circle = MACircle(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: 10000)
            }
            // 县域级别
            mapView.add(circle)
        } else if (zoomLevel > 8 && zoomLevel <= 10) {
            // 片区级别
        } else if (zoomLevel <= 8) {
            // 区域级别
        }
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: MACircle.self) {
            let renderer: MACircleRenderer = MACircleRenderer(overlay: overlay)
            renderer.lineWidth = 1.0
//            renderer.strokeColor = UIColor.blue
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.5)
            
            
            return renderer
        }
        return nil
    }
    
    // marker渲染回调
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation is ClusterAnnotation {
            let pointReuseIndetifier = "pointReuseIndetifier"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as? ClusterAnnotationView
            
            if annotationView == nil {
                annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
            
            annotationView?.annotation = annotation
            annotationView?.count = UInt((annotation as! ClusterAnnotation).count)
            
            return annotationView
        } else if annotation.isKind(of: MAPointAnnotation.self) {
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
            } else {
                if let origin = UIImage(named: "ic_merchant_position") {
                    // 单个数字居中和两位数字居中
                    let addr = annotationMap[annotation as! MAPointAnnotation]!
                    let txt: String = addr.indexName ?? "-"
                    var txtWidth = 6
                    if txt.count > 1 {
                        txtWidth = 13
                    }
        
                    annotationView!.image = textToImage(drawText: txt, inImage: origin, atPoint: CGPoint(x: (30 - txtWidth) / 2, y: 5))
                    
                }
            }
            return annotationView!
        }
        
        return nil
    }
    
    private func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let iconSize = CGSize(width: 30, height: 30)
        let textColor = UIColor.white
        let textFont = UIFont(name: "Helvetica Bold", size: 12)!
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(iconSize, false, scale)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: iconSize))
        
        let rect = CGRect(origin: point, size: iconSize)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // MARK: - CustomCalloutViewTapDelegate
    func didDetailButtonTapped(_ index: Int) {
        
    }
    
    //MARK: - Update Annotation
    
    func updateMapViewAnnotations(annotations: Array<ClusterAnnotation>) {
        
        /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
        let before = NSMutableSet(array: mapView.annotations)
        before.remove(mapView.userLocation!)
        let after: Set<NSObject> = NSSet(array: annotations) as Set<NSObject>
        
        /* 保留仍然位于屏幕内的annotation. */
        var toKeep: Set<NSObject> = NSMutableSet(set: before) as Set<NSObject>
        toKeep = toKeep.intersection(after)
        
        /* 需要添加的annotation. */
        let toAdd = NSMutableSet(set: after)
        toAdd.minus(toKeep)
        
        /* 删除位于屏幕外的annotation. */
        let toRemove = NSMutableSet(set: before)
        toRemove.minus(after)
        
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
//            self?.mapView.addAnnotation(self?.myPositionAnnotation)
            self?.mapView.addAnnotations(toAdd.allObjects)
            self?.mapView.removeAnnotations(toRemove.allObjects)
        })
    }
    
    func addAnnotations(toMapView mapView: MAMapView) {
        synchronized(lock: self) { [weak self] in
            
            guard (self?.coordinateQuadTree.root != nil) || self?.shouldRegionChangeReCalculate != false else {
                NSLog("tree is not ready.")
                return
            }
            
            guard let aMapView = self?.mapView else {
                return
            }
            
            let visibleRect = aMapView.visibleMapRect
            let zoomScale = Double(aMapView.bounds.size.width) / visibleRect.size.width
            let zoomLevel = Double(aMapView.zoomLevel)
            
            DispatchQueue.global(qos: .default).async(execute: { [weak self] in
                
                let annotations = self?.coordinateQuadTree.clusteredAnnotations(within: visibleRect, withZoomScale: zoomScale, andZoomLevel: zoomLevel)
                
                self?.updateMapViewAnnotations(annotations: annotations as! Array<ClusterAnnotation>)
            })
        }
    }
    
    func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    deinit {
        coordinateQuadTree.clean()
    }

}

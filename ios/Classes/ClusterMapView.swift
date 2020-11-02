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
    private var currentClickMarker: MAPointAnnotation?
    
    private var annotationMap: [MAPointAnnotation:AddressInfo] = [:]
    
    private let methodChannel: FlutterMethodChannel
    
    private var circle: MACircle?
    
    // 路线规划
    var naviRoute: MANaviRoute?
    //    var route: AMapRoute?
    var currentSearchType: AMapRoutePlanningType = AMapRoutePlanningType.drive
    
    // 点聚合
    var coordinateQuadTree = CoordinateQuadTree()
    var shouldRegionChangeReCalculate = false
    
    private var annoShowType: Int = 0
    
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
    
    // 地图缩放级别监听
    func mapView(_ mapView: MAMapView!, mapDidZoomByUser wasUserAction: Bool) {
        let zoomLevel = mapView.zoomLevel
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "my_location_lat")
        let lng = defaults.double(forKey: "my_location_lng")

        print("mapDidZoomByUser: \(zoomLevel)")
        
        
        if (zoomLevel > 11) {
            annoShowType = 0
            // 门店级别
//            if circle != nil {
//                mapView.remove(circle)
//                circle = nil
//            }
//            mapView.removeAnnotation()
        } else if (zoomLevel > 10 && zoomLevel <= 11) {
            annoShowType = 1
//            if circle == nil {
//                circle = MACircle(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: 10000)
//            }
            // 县域级别
//            mapView.add(circle)
        } else if (zoomLevel > 8 && zoomLevel <= 10) {
            annoShowType = 2
            // 片区级别
        } else if (zoomLevel <= 8) {
            annoShowType = 3
            // 区域级别
        }
        
//        mapView.removeAnnotations(mapView.annotations)
//        switch annoShowType {
//        case 0:
//            addMyMarker()
//        case 1:
//        case 2:
//        case 3:
//        default:
//            break;
//        }

    }

//    // 渲染覆盖物，这里是圆形
//    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
//        if overlay.isKind(of: MACircle.self) {
//            let renderer: MACircleRenderer = MACircleRenderer(overlay: overlay)
//            renderer.lineWidth = 1.0
//            renderer.fillColor = UIColor.blue.withAlphaComponent(0.5)
//
//
//            return renderer
//        }
//        return nil
//    }
    
    // MARK: - marker点渲染回调
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation is ClusterAnnotation {
            // 聚合marker点
            let pointReuseIndetifier = "pointReuseIndetifier"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as? ClusterAnnotationView
            
            if annotationView == nil {
                annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
//                annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
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
    
    // marker点击事件
    func mapView(_ mapView: MAMapView!, didAnnotationViewTapped view: MAAnnotationView!) {
        if view.annotation.isKind(of: MAPointAnnotation.self) {
            self.currentClickMarker = view.annotation as? MAPointAnnotation
            // 点击marker时过滤我的位置
            if view.annotation.title == "我的位置" {
                return
            }
            
            let defaults = UserDefaults.standard
            let lat = defaults.double(forKey: "my_location_lat")
            let lng = defaults.double(forKey: "my_location_lng")
            currentSearchType = AMapRoutePlanningType.drive
            searchRoutePlanningDrive(startCoordinate: CLLocationCoordinate2DMake(lat, lng), destinationCoordinate: CLLocationCoordinate2DMake(view.annotation.coordinate.latitude, view.annotation.coordinate.longitude))
            self.view().makeToast("正在查询路线", duration: 1.0)
        } else if view.annotation.isKind(of: ClusterAnnotation.self) {
            let anno = view.annotation as! ClusterAnnotation
            if anno.count == 1 {
                self.view().makeToast("点击Marker", duration: 1.0)
            }
        }
    }
    
    // MARK: - 路线规划
    func searchRoutePlanningDrive(startCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        let request = AMapDrivingRouteSearchRequest()
        request.origin = AMapGeoPoint.location(withLatitude: CGFloat(startCoordinate.latitude), longitude: CGFloat(startCoordinate.longitude))
        request.destination = AMapGeoPoint.location(withLatitude: CGFloat(destinationCoordinate.latitude), longitude: CGFloat(destinationCoordinate.longitude))
        
        request.requireExtension = true
        
        search.aMapDrivingRouteSearch(request)
    }
    
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        // 检索失败
        //        let nsErr:NSError? = error as NSError
        //        NSLog("Error:\(error) - \(ErrorInfoUtility.errorDescription(withCode: (nsErr?.code)!))")
        print("Error: \(error)")
    }
    
    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
        // 当检索成功时，会进到 onRouteSearchDone 回调函数中
        //        mapView.removeAnnotations(mapView.annotations)
        
        mapView.removeOverlays(mapView.overlays)
        
        //        addDefaultAnnotations()
        
        if response.count > 0 {
            if let marker = self.currentClickMarker {
                print("click marker: \(response.route.paths.first?.distance)")
                self.methodChannel.invokeMethod("clickMarker", arguments: [
                    "index": annotationMap[marker]?.index!,
                    "distance": self.getFriendlyLength(lenMeter: response.route.paths.first?.distance)
                ])
            }
            // TODO: 资源未引入
//            presentCurrentCourse(route: response.route)
        }
    }
    
    /* 展示当前路线方案. */
    func presentCurrentCourse(route: AMapRoute?) {
        
        //        let start = AMapGeoPoint.location(withLatitude: CGFloat(startCoordinate.latitude), longitude: CGFloat(startCoordinate.longitude))
        //        let end = AMapGeoPoint.location(withLatitude: CGFloat(destinationCoordinate.latitude), longitude: CGFloat(destinationCoordinate.longitude))
        
        let start: AMapGeoPoint? = nil
        let end: AMapGeoPoint? = nil
        
        if currentSearchType == .bus || currentSearchType == .busCrossCity {
            naviRoute = MANaviRoute(for: route?.transits.first, start: start, end: end)
        } else {
            let type = MANaviAnnotationType(rawValue: currentSearchType.rawValue)
            naviRoute = MANaviRoute(for: route?.paths.first, withNaviType: type!, showTraffic: true, start: start, end: end)
        }
        
        naviRoute?.add(to: mapView)
        
        mapView.showOverlays(naviRoute?.routePolylines, edgePadding: UIEdgeInsets(top: 100, left: 40, bottom: 100, right: 40), animated: true)
    }
    
    // 渲染路径
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: LineDashPolyline.self) {
            let naviPolyline: LineDashPolyline = overlay as! LineDashPolyline
            let renderer: MAPolylineRenderer = MAPolylineRenderer(overlay: naviPolyline.polyline)
            renderer.lineWidth = 8.0
            renderer.strokeColor = UIColor.red
            renderer.lineDashType = MALineDashType.square
            
            return renderer
        }
        if overlay.isKind(of: MANaviPolyline.self) {
            
            let naviPolyline: MANaviPolyline = overlay as! MANaviPolyline
            let renderer: MAPolylineRenderer = MAPolylineRenderer(overlay: naviPolyline.polyline)
            renderer.lineWidth = 8.0
            
            if naviPolyline.type == MANaviAnnotationType.walking {
                renderer.strokeColor = naviRoute?.walkingColor
            }
            else if naviPolyline.type == MANaviAnnotationType.railway {
                renderer.strokeColor = naviRoute?.railwayColor;
            }
            else {
                renderer.strokeColor = naviRoute?.routeColor;
            }
            
            return renderer
        }
        if overlay.isKind(of: MAMultiPolyline.self) {
            let renderer: MAMultiColoredPolylineRenderer = MAMultiColoredPolylineRenderer(multiPolyline: overlay as! MAMultiPolyline?)
            renderer.lineWidth = 8.0
            renderer.strokeColors = naviRoute?.multiPolylineColors
            
            return renderer
        }
        
        return nil
    }
    
    private func textToImage(
        drawText text: String,
        inImage image: UIImage,
        atPoint point: CGPoint,
        width: Int = 30,
        height: Int = 30,
        fontSize: Int = 12
    ) -> UIImage {
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
    
    func getFriendlyLength(lenMeter: Int?) -> String {
        guard let lenMeter = lenMeter else {
            return ""
        }
        if lenMeter > 1000 {
            let dis = Float(lenMeter) / 1000
            return String(format: "%.2fkm", dis)
        }
        if lenMeter > 100 {
            let dis = lenMeter / 50 * 50
            return String(format: "%dm", dis)
        }
        var dis = lenMeter / 10 * 10
        if dis == 0 {
            dis = 10
        }
        return String(format: "%dm", dis)
    }
    
    // MARK: - CustomCalloutViewTapDelegate
    func didDetailButtonTapped(_ index: Int) {
        
    }
    
    //MARK: - 点聚合
    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
//        addAnnotations(toMapView: self.mapView)
    }
    
    // 添加聚合点
    func updateMapViewAnnotations(annotations: Array<ClusterAnnotation>) {
        
        /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
        let before = NSMutableSet(array: mapView.annotations)
//        before.remove(mapView.userLocation!)
        let after: Set<NSObject> = NSSet(array: annotations) as Set<NSObject>
        
        /* 保留仍然位于屏幕内的annotation. */
        var toKeep: Set<NSObject> = NSMutableSet(set: before) as Set<NSObject>
        toKeep = toKeep.intersection(after)
        
        /* 删除位于屏幕外的annotation. */
        let toRemove = NSMutableSet(set: before)
        toRemove.minus(after)
        
        /* 需要添加的annotation. */
        let toAdd = NSMutableSet(set: after)
        toAdd.minus(toKeep)
        
        // 保留我的位置
        if let myPosition = myPositionAnnotation {
            toAdd.add(myPosition)
            toRemove.remove(myPosition)
        }
        
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
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

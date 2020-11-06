//
//  AMapView.swift
//  Pods-Runner
//
//  Created by xionghao on 2020/7/24.
//

import UIKit
import AMapLocationKit
import Toast_Swift

class AMapView: NSObject, FlutterPlatformView, MAMapViewDelegate, AMapSearchDelegate, AMapLocationManagerDelegate {
    
    private var mapView: MAMapView!
    private let viewController: UIViewController
    private let param: AMapParam?
    var search: AMapSearchAPI!
    
    //    var startCoordinate: CLLocationCoordinate2D!
    //    var destinationCoordinate: CLLocationCoordinate2D!
    
    var naviRoute: MANaviRoute?
    //    var route: AMapRoute?
    var currentSearchType: AMapRoutePlanningType = AMapRoutePlanningType.drive
    
    private let defaultLocationTimeout = 6
    private let defaultReGeocodeTimeout = 3
    private lazy var locationManager = AMapLocationManager()
    private var myPositionAnnotation: MAPointAnnotation?
    
    private var annotationMap: [MAPointAnnotation:AddressInfo] = [:]
    private let methodChannel: FlutterMethodChannel
    private var currentClickMarker: MAPointAnnotation?
    private var annoShowType: Int = 0
    private var lastAnnoShowType: Int = 0
    
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
        return mapView
    }
    
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
    
    // 我的位置
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
            self.methodChannel.invokeMethod("onLocate", arguments: [
                "lat": lat,
                "lng": lng
            ])
            
        } else {
            reLocate(isInitial: true)
        }
    }
    
    // 各个门店的位置
    func addMerchantMarkers() {
        if let merchantAddrList = param?.merchantAddressList {
            //            var lats = Array<Double>()
            //            var lngs = Array<Double>()
            var annoList = Array<MAPointAnnotation>()
            if let anno = myPositionAnnotation {
                annoList.append(anno)
            }
            merchantAddrList.forEach({ addr in
                if let lat = addr.geo?.lat,
                    let lng = addr.geo?.lng {
                    
                    let anno = MAPointAnnotation()
                    anno.coordinate = CLLocationCoordinate2DMake(lat, lng)
                    anno.title = addr.address
                    annotationMap[anno] = addr
                    
                    self.mapView.addAnnotation(anno)
                    
                    annoList.append(anno)
                }
            })
            // 显示所有的marker点
            self.mapView.showAnnotations(annoList, edgePadding: UIEdgeInsets(top: 100, left: 40, bottom: 100, right: 40), animated: true)
            
        }
    }
    
    private func saveCurrentPosition(location: CLLocation!) {
        let defaults = UserDefaults.standard
        defaults.set(location.coordinate.latitude, forKey: "my_location_lat")
        defaults.set(location.coordinate.longitude, forKey: "my_location_lng")
    }
    
    // MARK: - 地图缩放
    func zoomIn() {
        mapView.setZoomLevel(mapView.zoomLevel + 0.5, animated: true)
    }
    
    func zoomOut() {
        mapView.setZoomLevel(mapView.zoomLevel - 0.5, animated: true)
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
                self?.methodChannel.invokeMethod("onLocate", arguments: [
                    "lat": location.coordinate.latitude,
                    "lng": location.coordinate.longitude
                ])
                if (isInitial) {
                    // 初始化我的位置，并和门店位置一起显示在屏幕上
                    self?.addMerchantMarkers()
                } else {
                    self?.mapView.setCenter(location.coordinate, animated: true)
                }
            }
        })
    }
    
    func addAnnotationsToMapView(_ annotation: MAAnnotation) {
        mapView.addAnnotation(annotation)
        
        mapView.selectAnnotation(annotation, animated: true)
        mapView.setCenter(annotation.coordinate, animated: true)
    }
    
    func configLocationManager() {
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.allowsBackgroundLocationUpdates = true
        
        locationManager.locationTimeout = defaultLocationTimeout
        
        locationManager.reGeocodeTimeout = defaultReGeocodeTimeout
    }
    
    //MARK: - AMapLocationManagerDelegate
    
    func amapLocationManager(_ manager: AMapLocationManager!, doRequireLocationAuth locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - 路线规划相关
    //    func addDefaultAnnotations() {
    //
    //        let anno = MAPointAnnotation()
    //        anno.coordinate = startCoordinate
    //        anno.title = "起点"
    //
    //        mapView.addAnnotation(anno)
    //
    //        let annod = MAPointAnnotation()
    //        annod.coordinate = destinationCoordinate
    //        annod.title = "终点"
    //
    //        mapView.addAnnotation(annod)
    //    }
    
    func searchRoutePlanningDrive(startCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        let request = AMapDrivingRouteSearchRequest()
        request.origin = AMapGeoPoint.location(withLatitude: CGFloat(startCoordinate.latitude), longitude: CGFloat(startCoordinate.longitude))
        request.destination = AMapGeoPoint.location(withLatitude: CGFloat(destinationCoordinate.latitude), longitude: CGFloat(destinationCoordinate.longitude))
        
        request.requireExtension = true
        
        search.aMapDrivingRouteSearch(request)
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
    
    // MARK: - MAMapViewDelegate
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
    
    // MARK: - 渲染marker点
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
            
            if annotation.isKind(of: MANaviAnnotation.self) {
                let naviAnno = annotation as! MANaviAnnotation
                
                switch naviAnno.type {
                case MANaviAnnotationType.railway:
                    annotationView!.image = UIImage(named: "railway_station")
                    break
                case MANaviAnnotationType.drive:
                    annotationView!.image = UIImage(named: "car")
                    break
                case MANaviAnnotationType.riding:
                    annotationView!.image = UIImage(named: "ride")
                    break
                case MANaviAnnotationType.walking:
                    annotationView!.image = UIImage(named: "man")
                    break
                case MANaviAnnotationType.bus:
                    annotationView!.image = UIImage(named: "bus")
                    break
                case .truck:
                    annotationView!.image = UIImage(named: "truck")
                    break
                case .futureDrive:
                    annotationView!.image = UIImage(named: "car")
                    break
                @unknown default:
                    print("unkown type")
                }
            }
            else if annotation.isKind(of: MAPointAnnotation.self) {
                if annotation.title == "起点" {
                    annotationView!.image = UIImage(named: "startPoint")
                }
                else if annotation.title == "终点" {
                    annotationView!.image = UIImage(named: "endPoint")
                }
                else if annotation.title == "我的位置" {
                    if let image = UIImage(named: "ic_my_position") {
//                        annotationView!.image = scaleImage(inImage: image, scaleWidth: 50, scaleHeight: 50 / 140 * 112)
                        annotationView!.image = image
                    }
                }
                else {
                    let addr = annotationMap[annotation as! MAPointAnnotation]!
                    switch addr.showType {
                    case 0:
                        if let origin = UIImage(named: "ic_merchant_position") {
                            // 单个数字居中和两位数字居中
                            let txt: String = "\(addr.indexName!)"
                            annotationView!.image = textToImage(drawText: txt, inImage: origin)
                            
                        }
                    case 1:
                        if let origin = UIImage(named: "ic_merchant_statistic") {
                            // 单个数字居中和两位数字居中
//                            let txt: String = "\(addr.address!)\n\(addr.indexName!)"
                            annotationView!.image = textToImage(drawText: addr.address!, secondText: addr.indexName!, inImage: origin, width: 65, height: 65)
                            
                        }
                    case 2:
                        if let origin = UIImage(named: "ic_merchant_statistic") {
                            annotationView!.image = textToImage(drawText: addr.address!, secondText: addr.indexName!, inImage: origin, width: 80, height: 80)
                            
                        }
                    case 3:
                        if let origin = UIImage(named: "ic_merchant_statistic") {
                            // 单个数字居中和两位数字居中
//                            let txt: String = "\(addr.address!)\n\(addr.indexName!)"
                            annotationView!.image = textToImage(drawText: addr.address!, secondText: addr.indexName!, inImage: origin, width: 110, height: 110)
                            
                        }
                    default:
                        break;
                    }
                    
                }
            }
            return annotationView!
        }
        
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, mapDidZoomByUser wasUserAction: Bool) {
        let zoomLevel = mapView.zoomLevel
        if (zoomLevel > 12) {
            // 门店级别
            annoShowType = 0
        } else if (zoomLevel > 10 && zoomLevel <= 12) {
            // 县域级别
            annoShowType = 1
        } else if (zoomLevel > 8 && zoomLevel <= 10) {
            // 片区级别
            annoShowType = 2
        } else if (zoomLevel <= 8) {
            // 区域级别
            annoShowType = 3
        }
        if annoShowType != lastAnnoShowType {
            self.methodChannel.invokeMethod("onMapZoom", arguments: ["zoomLevel": annoShowType])
            lastAnnoShowType = annoShowType
        }
    }
    
    func updateMarkers(addressList: Array<AddressInfo>?) {
        mapView.removeAnnotations(mapView.annotations)
        var annoList = Array<MAPointAnnotation>()
        annotationMap.removeAll()
        addressList?.forEach({ addr in
            if let lat = addr.geo?.lat,
                let lng = addr.geo?.lng {
                
                let anno = MAPointAnnotation()
                anno.coordinate = CLLocationCoordinate2DMake(lat, lng)
                anno.title = addr.address
                annoList.append(anno)
                annotationMap[anno] = addr
            }
        })
        self.mapView.addAnnotations(annoList)
    }
    
    // marker点击事件
    func mapView(_ mapView: MAMapView!, didAnnotationViewTapped view: MAAnnotationView!) {
        if view.annotation.isKind(of: MAPointAnnotation.self) {
            self.currentClickMarker = view.annotation as? MAPointAnnotation
        }
        // 点击marker时过滤我的位置
        if view.annotation.title == "我的位置" {
            return
        }
        // 查询门店到司机当前位置的路径
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "my_location_lat")
        let lng = defaults.double(forKey: "my_location_lng")
        currentSearchType = AMapRoutePlanningType.drive
        searchRoutePlanningDrive(startCoordinate: CLLocationCoordinate2DMake(lat, lng), destinationCoordinate: CLLocationCoordinate2DMake(view.annotation.coordinate.latitude, view.annotation.coordinate.longitude))
        self.view().makeToast("正在查询路线", duration: 1.0)
    }
    
    // marker选择事件
    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
    }
    
//    func mapView(_ mapView: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) {
//        print("map clicked");
//        let v = UIImageView()
//        v.image = UIImage(named: "AMapBundle.bundle/ic_car")
//        print("image: \(v.image)")
//        v.backgroundColor = .red
//        v.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        mapView?.addSubview(v)
//    }
//    
//    func getBundle() -> Bundle? {
//        var bundle: Bundle?
//        if let urlString = Bundle.main.path(forResource: "AMapBundle", ofType: "bundle", inDirectory: "xhamap") {
//            bundle = (Bundle(url: URL(fileURLWithPath: urlString)))
//        }
//        return bundle
//    }

    
    // MARK: - AMapSearchDelegate
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
                    "distance": getFriendlyLength(lenMeter: response.route.paths.first?.distance)
                ])
            }
            // TODO: 资源未引入
//            presentCurrentCourse(route: response.route)
        }
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
    
    func image(with view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
    
    func textToImage(
        drawText text: String,
        secondText: String? = nil,
        inImage image: UIImage,
        width: CGFloat = 30,
        height: CGFloat = 30,
        textSize: CGFloat = 12
    ) -> UIImage {
        let iconSize = CGSize(width: width, height: height)
        let textColor = UIColor.white
        let textFont = UIFont(name: "Helvetica Bold", size: textSize)!

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(iconSize, false, scale)

        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: iconSize))

        let text_h = textFont.lineHeight
        let textWidth = text.width(withConstrainedHeight: width, font: textFont)
        let textHeight = text.height(withConstrainedWidth: height, font: textFont)
        var text_y: CGFloat = 0
        var secondText_x: CGFloat = 0
        var secondText_y: CGFloat = 0
        if secondText == nil {
            text_y = (height - textHeight) / 2
        } else {
            text_y = (height - textHeight * 2) / 2
            secondText_y = (height - textHeight * 2) / 2 + textHeight
            let secondTextWidth = secondText!.width(withConstrainedHeight: width, font: textFont)
            secondText_x = (width - secondTextWidth) / 2
        }
        let text_x = (width - textWidth) / 2
        let text_rect = CGRect(x: text_x, y: text_y, width: width, height: text_h)
        text.draw(in: text_rect, withAttributes: textFontAttributes)
        if secondText != nil {
            let secondText_rect = CGRect(x: secondText_x, y: secondText_y, width: width, height: text_h)
            secondText?.draw(in: secondText_rect, withAttributes: textFontAttributes)
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    func scaleImage(inImage image: UIImage, scaleWidth: CGFloat, scaleHeight: CGFloat) -> UIImage {
        let iconSize = CGSize(width: scaleWidth, height: scaleHeight)
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(iconSize, false, scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: iconSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

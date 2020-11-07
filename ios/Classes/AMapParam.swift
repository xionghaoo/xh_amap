//
//  AMapParam.swift
//  Runner
//
//  Created by xionghao on 2020/5/7.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

class AMapParam: Codable {
    
    static let routeMap: Int = 0
    static let addressDescriptionMap: Int = 1
    
    let initialCenterPoint: Array<Double>
    let initialZoomLevel: CGFloat
    let enableMyLocation: Bool?
    let enableMyMarker: Bool?
    let mapType: Int
    let startAddressList: Array<AddressInfo>?
    let endAddressList: Array<AddressInfo>?
    let merchantAddressList: Array<AddressInfo>?
    
    init(
        initialCenterPoint: Array<Double>,
        initialZoomLevel: CGFloat,
        enableMyLocation: Bool? = false,
        enableMyMarker: Bool? = false,
        mapType: Int = routeMap,
        startAddressList: Array<AddressInfo>? = [],
        endAddressList: Array<AddressInfo>? = [],
        merchantAddressList: Array<AddressInfo>? = []
    ) {
        self.initialCenterPoint = initialCenterPoint
        self.initialZoomLevel = initialZoomLevel
        self.enableMyLocation = enableMyLocation
        self.enableMyMarker = enableMyMarker
        self.mapType = mapType
        self.startAddressList = startAddressList
        self.endAddressList = endAddressList
        self.merchantAddressList = merchantAddressList
    }
}

class MarkerParam: Codable {
    let markerList: Array<AddressInfo>?
    
    init(markerList: Array<AddressInfo>? = []) {
        self.markerList = markerList
    }
}

struct AddressInfo: Codable {
    let geo: GeoPoint?
    let address: String?
    let index: Int?
    let indexName: String?
    let showType: Int?
    let id: Int?
    
}

struct GeoPoint: Codable {
    let lat: Double?
    let lng: Double?
}

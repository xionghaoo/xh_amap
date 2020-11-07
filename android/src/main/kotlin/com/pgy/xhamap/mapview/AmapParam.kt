package com.pgy.xhamap.mapview

class AmapParam {
    val initialCenterPoint: ArrayList<Double>? = null
    val initialZoomLevel: Float? = null
    val enableMyLocation: Boolean = false
    val enableMyMarker: Boolean = false
    val mapType: Int? = ROUTE_MAP

    val startAddressList: ArrayList<AddressInfo>? = null
    val endAddressList: ArrayList<AddressInfo>? = null

    val merchantAddressList: ArrayList<AddressInfo>? = null

    class AddressInfo {
        var geo: GeoPoint? = null
        var address: String? = null
        var index: Int = 0
        var indexName: String? = null
        var showType: Int? = null
        var id: Int? = null
    }

    class GeoPoint(val lat: Double, val lng: Double)

    companion object {
        const val ROUTE_MAP: Int = 0
        const val ADDRESS_DESCRIPTION_MAP: Int = 1
    }
}
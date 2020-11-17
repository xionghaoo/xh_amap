package com.pgy.xhamap.mapview

class AmapParam {
    val initialCenterPoint: ArrayList<Double>? = null
    val initialZoomLevel: Float? = null
    val enableMyLocation: Boolean = false
    val enableMyMarker: Boolean = false
    val mapType: Int? = ROUTE_MAP
    val markerClickable: Boolean = true

    val startAddressList: ArrayList<AddressInfo>? = null
    val endAddressList: ArrayList<AddressInfo>? = null

    val merchantAddressList: ArrayList<AddressInfo>? = null

    val fixToLevel0: Boolean = true

    class AddressInfo {
        var geo: GeoPoint? = null
        var address: String? = null
        var index: Int = 0
        var indexName: String? = null
        var showType: Int? = null
        var id: Int? = null
        var parentId: Int? = null

        override fun hashCode(): Int {
            return id ?: 0
        }

        override fun equals(other: Any?): Boolean {
            if (other is AddressInfo) {
                return id == other.id
            } else {
                return false
            }
        }
    }

    class GeoPoint(val lat: Double, val lng: Double)

    companion object {
        const val ROUTE_MAP: Int = 0
        const val ADDRESS_DESCRIPTION_MAP: Int = 1
    }
}
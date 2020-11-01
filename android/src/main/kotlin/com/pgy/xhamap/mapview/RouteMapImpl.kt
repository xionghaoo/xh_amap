package com.pgy.xhamap.mapview

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.view.LayoutInflater
import android.widget.TextView
import android.widget.Toast
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.model.*
import com.amap.api.services.core.AMapException
import com.amap.api.services.route.*
import com.pgy.xhamap.R
import io.flutter.plugin.common.MethodChannel

class RouteMapImpl(
    private val context: Context?,
    private val aMap: AMap?,
    private val param: AmapParam,
    private val methodChannel: MethodChannel
) : IActualMap {

    private val rideRouteOverlayList = ArrayList<RideRouteOverlay>()
    private val driverRouteOverlayList = ArrayList<DrivingRouteOverlay>()

//    private var lat: Double = 0.0
//    private var lng: Double = 0.0

    private var merchantMap = HashMap<Marker, Int>()

    override fun onCreate() {


//        addMerchantMarkers()
    }
    
    override fun addMerchantMarkers() {
        var lat: Double = 0.0
        var lng: Double = 0.0
        if (context != null) {
            val prefs: SharedPreferences = context.applicationContext.getSharedPreferences(
                "pgy_native_cache", Context.MODE_PRIVATE
            )
            lat = prefs.getFloat("my_location_lat", 0f).toDouble()
            lng = prefs.getFloat("my_location_lng", 0f).toDouble()
        }

        val lats = ArrayList<Double>()
        val lngs = ArrayList<Double>()
        lats.add(lat)
        lngs.add(lng)
        param.merchantAddressList?.forEach { address ->
            if (address.geo != null && address.geo?.lat != null && address.geo?.lng != null) {
                lats.add(address.geo?.lat!!)
                lngs.add(address.geo?.lng!!)

                val v = LayoutInflater.from(context).inflate(R.layout.marker_merchant_location, null)
                v.findViewById<TextView>(R.id.tv_merchant_index).text = address.indexName.toString()
                val marker = aMap?.addMarker(
                    MarkerOptions()
                        .position(LatLng(address.geo!!.lat, address.geo!!.lng))
                        .title(address.address)
                        .icon(BitmapDescriptorFactory.fromView(v))
                )
                if (marker != null) {
                    merchantMap.put(marker, address.index)
                }
            }
        }

        val maxLat = lats.max()
        val maxlng = lngs.max()
        val minLat = lats.min()
        val minLng = lngs.min()
        val builder = LatLngBounds.builder();
        builder.include(LatLng(maxLat!!, maxlng!!))
        builder.include(LatLng(minLat!!, minLng!!))
        aMap?.animateCamera(CameraUpdateFactory.newLatLngBounds(builder.build(), 300))

        aMap?.setOnMarkerClickListener { marker ->
            if (marker.title != "MyPosition") {
                Toast.makeText(context, "正在查询路线", Toast.LENGTH_SHORT).show()

                if (lat != 0.0 && lng != 0.0) {
                    val start = AmapParam.AddressInfo()
                    start.geo = AmapParam.GeoPoint(lat, lng)
                    val end = AmapParam.AddressInfo()
                    end.geo = AmapParam.GeoPoint(marker.position.latitude, marker.position.longitude)

                    // 清除所有路线
                    driverRouteOverlayList.forEach { overlay -> overlay.removeFromMap() }

                    driveRoute(start, end) { distance ->
                        val arguments = HashMap<String, Any?>()
                        arguments.put("index", merchantMap[marker])
                        arguments.put("distance", distance)
                        methodChannel.invokeMethod("clickMarker", arguments)
                    }
                }
                marker.showInfoWindow()
            }
            true
        }

        aMap?.setOnMapClickListener {
            aMap.mapScreenMarkers.forEach { marker ->
                if (marker.isInfoWindowShown) {
                    marker.hideInfoWindow()
                }
            }
        }
    }

    private fun drawRoutePaths() {
        val startAddrList = param.startAddressList
        val endAddrList = param.endAddressList
        if (startAddrList == null
            || endAddrList == null
            || startAddrList.size != endAddrList.size
            || startAddrList.size == 0 || endAddrList.size == 0
        ) {
//            CommonUtils.showToast(context, "地址信息不完整")
            return
        }

        rideRouteOverlayList.clear()
        driverRouteOverlayList.clear()

        startAddrList.mapIndexed { index, startAddr ->
            val endAddr = endAddrList[index]
//            if (configuration?.lineType == LineType.ROUTE) {
//                if (startAddr.routeType == AddressInfo.ROUTE_DRIVE) {
//                    driveRoute(startAddr, endAddr)
//                } else {
//                    rideRoute(startAddr, endAddr)
//                }
//            } else {
//                drawOrderLines(index, startAddr, endAddr)
//            }
            driveRoute(startAddr, endAddr)
        }

    }

    private fun driveRoute(startAddr: AmapParam.AddressInfo, endAddr: AmapParam.AddressInfo, success: (String) -> Unit = {}) {
        val routeSearch = RouteSearch(context)
        routeSearch.setRouteSearchListener(MapRouteSearchListener(
            context = context,
            aMap = aMap,
            startAddr = startAddr,
            endAddr = endAddr,
            rideOverlayList = rideRouteOverlayList,
            driverOverlayList = driverRouteOverlayList,
            success = success
        ))

        val fromAndTo = RouteSearch.FromAndTo(
            MapUtil.convertGeoPointToLatLonPoint(startAddr.geo),
            MapUtil.convertGeoPointToLatLonPoint(endAddr.geo)
        )
        fromAndTo.plateProvince = "粤"
        fromAndTo.plateNumber = "B6BN05"
        // RouteSearch.DRIVING_SINGLE_DEFAULT 驾车
        // RouteSearch.RIDING_DEFAULT 骑行 时间最少
        // DRIVING_PURE_ELECTRIC_VEHICLE 纯电动车(小汽车)
        // DRIVEING_PLAN_FASTEST_SHORTEST 不考虑路况，返回速度最优、耗时最短的路
        // 文档
        // http://a.amap.com/lbs/static/unzip/Android_Map_Doc/Search/index.html?com/amap/api/services/route/RouteSearch.RideRouteQuery.html
        // DRIVING_SINGLE_SHORTEST: 最短距离
        val query = RouteSearch.DriveRouteQuery(fromAndTo, RouteSearch.DRIVING_SINGLE_SHORTEST, null, null, "")
        routeSearch.calculateDriveRouteAsyn(query)
    }

    internal class MapRouteSearchListener(
        private val context: Context?,
        private val aMap: AMap?,
        private val startAddr: AmapParam.AddressInfo,
        private val endAddr: AmapParam.AddressInfo,
        private val rideOverlayList: ArrayList<RideRouteOverlay>,
        private val driverOverlayList: ArrayList<DrivingRouteOverlay>,
        private val success: (String) -> Unit
    ) : RouteSearch.OnRouteSearchListener {
        override fun onDriveRouteSearched(result: DriveRouteResult?, errorCode: Int) {
            // 驾车路线查询
            if (errorCode == AMapException.CODE_AMAP_SUCCESS && result?.paths != null && result.paths.size > 0) {
                val drivePath: DrivePath = result.paths[0] ?: return

                val overlay = DrivingRouteOverlay(
                    context,
                    aMap,
                    drivePath,
                    result.startPos,
                    result.targetPos,
                    null,
                    null,
                    null
                )
                driverOverlayList.add(overlay)
                overlay.setNodeIconVisibility(false)//设置节点marker是否显示
                overlay.setIsColorfulline(true)//是否用颜色展示交通拥堵情况，默认true
                overlay.removeFromMap()
                overlay.addToMap(startAddr.address, endAddr.address)

                // 路径缩放级别，值越小，信息越详细
                overlay.zoomToSpan(context?.resources?.getDimension(R.dimen.map_zoom_edge_width)?.toInt() ?: 300)

                // 距离 米
                val dis = drivePath.distance.toInt()
                // 时间 秒
                val dur = drivePath.duration.toInt()
                val friendlyDistance = AMapUtil.getFriendlyLength(dis)
                val friendlyTime = AMapUtil.getFriendlyTime(dur)

                success(friendlyDistance)

                Log.d("FlutterAmapView", "friendlyDistance: ${friendlyDistance}, ${friendlyTime}")
            }
        }

        override fun onBusRouteSearched(p0: BusRouteResult?, p1: Int) {

        }

        override fun onRideRouteSearched(result: RideRouteResult?, errorCode: Int) {
            // 骑行路线查询
        }

        override fun onWalkRouteSearched(p0: WalkRouteResult?, p1: Int) {

        }
    }
}
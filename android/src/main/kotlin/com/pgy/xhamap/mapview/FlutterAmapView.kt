package com.pgy.xhamap.mapview

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.animation.BounceInterpolator
import android.widget.TextView
import android.widget.Toast
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapView
import com.amap.api.maps.model.*
import com.amap.api.maps.model.animation.ScaleAnimation
import com.amap.api.services.core.AMapException
import com.amap.api.services.route.*
import com.google.gson.Gson
import com.pgy.xhamap.R
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.lang.Exception

/**
 * 高德地图，每次打开页面时都会创建新的MapView，
 * 移动地图时调用getView刷新绘制，关闭页面时调用dispose方法
 */
class FlutterAmapView(
    private val context: Context?,
    private val lifecycle: Lifecycle?,
    private val param: AmapParam,
    private val binaryMessenger: BinaryMessenger?
) : PlatformView, DefaultLifecycleObserver, MethodChannel.MethodCallHandler, AMap.OnMarkerClickListener, AMap.OnCameraChangeListener {

    companion object {
        private const val TAG = "FlutterAmapView"
    }

    private var aMap: AMap? = null
    private var mapView: MapView = MapView(context)
    private var myMarker: Marker? = null

    private var actualMap: IActualMap? = null

    private val level0: Float = 13f
    private val level1: Float = 11.5f
    private val level2: Float = 9.5f
    private var annoShowType = 0
    private var lastAnnoShowType = 0
    private var needRefreshStore = false

    private var isSearchingRoute = false

    private val startAddr: AmapParam.AddressInfo = AmapParam.AddressInfo()

    private val storeMap = HashMap<Marker, AmapParam.AddressInfo>()
    private val statisticMap = HashMap<Marker, AmapParam.AddressInfo>()

    private var clickedAreaId: Int? = null
    private var selectedCityId: Int? = null
    private var clickedZoom: Float = 13f

    private var methodChannel = MethodChannel(binaryMessenger, "xh.zero/amap_view_method")

    private var lastSelectedMarker: Marker? = null

    private var filterIds: List<Int>? = null

//    private var lastRequestTime: Long = 0L
    private var lastUpdateAddrMarkers: ArrayList<AddressMarker> = ArrayList()


    init {
        lifecycle?.addObserver(this)
        methodChannel.setMethodCallHandler(this)
    }

    override fun getView(): View {
        return mapView
    }

    fun initialize() {

    }

    override fun onFlutterViewDetached() {
    }

    override fun dispose() {
        mapView.onDestroy()
    }

    override fun onCreate(owner: LifecycleOwner) {
        mapView.onCreate(null)

        aMap = mapView.map
        if (param.initialCenterPoint != null && param.initialCenterPoint.size == 2) {
            aMap?.moveCamera(
                CameraUpdateFactory.newLatLngZoom(
                    LatLng(param.initialCenterPoint[0], param.initialCenterPoint[1]), param.initialZoomLevel ?: 17f
                )
            )
        }

        // 设置点击监听器
//        aMap?.setOnMapClickListener(this)
        // 禁止旋转手势
        aMap?.uiSettings?.isRotateGesturesEnabled = false
        // 禁止倾斜手势
        aMap?.uiSettings?.isTiltGesturesEnabled = false
        // 隐藏缩放按钮
        aMap?.uiSettings?.isZoomControlsEnabled = false
        // 显示比例尺
        aMap?.uiSettings?.isScaleControlsEnabled = true
        // 显示室内地图
        aMap?.showIndoorMap(true)
        
        // 开启我当前的位置蓝点
//        if (param.enableMyLocation) {
//            val locationStyle = MyLocationStyle()
//            locationStyle.myLocationType(MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER)
////            locationStyle.strokeColor(resources.getColor(R.color.overlay_map_location))
//            locationStyle.strokeWidth(0f)
////            locationStyle.radiusFillColor(resources.getColor(R.color.overlay_map_location))
//            locationStyle.interval(5000)
//            aMap?.myLocationStyle = locationStyle
//            aMap?.isMyLocationEnabled = true
//
//            aMap?.setOnMyLocationChangeListener { location ->
//
////                myMarker?.position = LatLng(location.latitude, location.longitude)
//            }
//        }
//        Log.d("FlutterAmapView", "${Gson().toJson(param)}")
        when(param.mapType) {
            AmapParam.ROUTE_MAP ->
                actualMap = RouteMapImpl(context, aMap, param, methodChannel)
            AmapParam.ADDRESS_DESCRIPTION_MAP ->
                actualMap = AddressDescriptionMapImpl(context, aMap, param)
            else -> {}
        }
//        actualMap = RouteMapImpl(context, aMap, param, methodChannel)
        actualMap?.onCreate()
        // 开启我当前的位置Marker
        if (param.enableMyMarker) {
            // 定位蓝点
            addMyPositionMarker()
        }

        // 监听marker点击事件
        aMap?.setOnMarkerClickListener(this)

        // 监听缩放级别变化
        aMap?.setOnCameraChangeListener(this)

//        aMap?.setAMapGestureListener(object : AMapGestureListener {
//            override fun onDoubleTap(p0: Float, p1: Float) {
//
//            }
//
//            override fun onSingleTap(p0: Float, p1: Float) {
//            }
//
//            override fun onFling(p0: Float, p1: Float) {
//            }
//
//            override fun onScroll(p0: Float, p1: Float) {
//            }
//
//            override fun onLongPress(p0: Float, p1: Float) {
//            }
//
//            override fun onDown(p0: Float, p1: Float) {
//            }
//
//            override fun onUp(p0: Float, p1: Float) {
//                io.flutter.Log.d("FlutterAMapView", "onUp")
//            }
//
//            override fun onMapStable() {
//                io.flutter.Log.d("FlutterAMapView", "onMapStable")
//            }
//        })
    }

    override fun onResume(owner: LifecycleOwner) {
        mapView.onResume()
    }

    override fun onPause(owner: LifecycleOwner) {
        mapView.onPause()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method) {
            "locateMyLocation" -> {
                relocate()
                result.success(null)
            }
            "zoomIn" -> {
                aMap?.animateCamera(CameraUpdateFactory.zoomIn())
            }
            "zoomOut" -> {
                aMap?.animateCamera(CameraUpdateFactory.zoomOut())
            }
            "updateMarkers" -> {
                try {
                    val param = Gson().fromJson<MarkerParam>(call.arguments as? String, MarkerParam::class.java)
                    updateMarkers(param.markerList)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            "clickMarker" -> {
                val args = call.arguments as HashMap<String, Int>
                val id = args["id"]
                val showType = args["showType"]
                if (id != null) {
                    clickMarker(id, showType ?: 0)
                }
            }
        }
    }

    override fun onMarkerClick(marker: Marker?): Boolean {
        if (!param.markerClickable) {
            return true
        }
        if (marker?.title == "我的位置") return false

        if (annoShowType == 0) {
            val address = storeMap[marker]
            if (address != null) {
                if (isSearchingRoute) {
                    Toast.makeText(context, "正在查询路线，请勿重复点击", Toast.LENGTH_SHORT).show()
                    return true
                }
                Toast.makeText(context, "正在查询路线", Toast.LENGTH_SHORT).show()
                isSearchingRoute = true
                searchRoute(startAddr, address) { distance ->
                    isSearchingRoute = false
                    val args = HashMap<String, Any?>()
                    args["showType"] = address.showType
                    args["index"] = address.index
                    args["distance"] = distance
                    methodChannel.invokeMethod("clickMarker", args)
                }
            }
        } else {
            val addr = statisticMap[marker]
            // 记录县域id
            if (annoShowType == 1) {
                selectedCityId = addr?.id
            }
            if (addr != null) {
                val args = HashMap<String, Any?>()
                args["showType"] = addr.showType
                args["index"] = addr.id
//                args["distance"] = "distance"
                methodChannel.invokeMethod("clickMarker", args)
            }
            when (annoShowType) {
                1 -> aMap?.moveCamera(CameraUpdateFactory.zoomTo(level0 + 0.5f))
                2 -> aMap?.moveCamera(CameraUpdateFactory.zoomTo(level1 + 0.5f))
                3 -> aMap?.moveCamera(CameraUpdateFactory.zoomTo(level2 + 0.5f))
            }

        }
        changeMarkerColor(marker)
        return true
    }

    override fun onCameraChange(p0: CameraPosition?) {
        
    }

    override fun onCameraChangeFinish(cameraPos: CameraPosition?) {
        val zoomLevel: Float = cameraPos?.zoom ?: 3f
        if (zoomLevel > level0) {
            // 门店级别
            annoShowType = 0
        } else if (zoomLevel > level1 && zoomLevel <= level0) {
            // 县域级别
            annoShowType = 1
        } else if (zoomLevel > level2 && zoomLevel <= level1) {
            // 片区级别
            annoShowType = 2
        } else if (zoomLevel <= level2) {
            // 区域级别
            annoShowType = 3
        }

        if (param.fixToLevel0) {
            annoShowType = 0
        }

        if (annoShowType != lastAnnoShowType) {
            val args = HashMap<String, Any?>()
            args.put("zoomLevel", annoShowType)
            methodChannel.invokeMethod("onMapZoom", args)
            lastAnnoShowType = annoShowType
        }

        if (annoShowType == 0) {
            val region = aMap?.projection?.visibleRegion
            if (region != null) {
                val centerLat: Double = (region.farLeft.latitude + region.nearRight.latitude) / 2
                val centerLng: Double = (region.farLeft.longitude + region.nearRight.longitude) / 2
                val args = HashMap<String, Double>().apply {
                    put("lat", centerLat)
                    put("lng", centerLng)
                }
                methodChannel.invokeMethod("onMapCenterMove", args)
            }
        }
        
        io.flutter.Log.d("FlutterAmapView", "zoom: $zoomLevel")
    }
    
    private fun clickMarker(id: Int, showType: Int) {
        clickedAreaId = id
        clickedZoom = when (showType) {
            0 -> level0 + 0.5f
            1 -> level0 - 0.5f
            2 -> level1 - 0.5f
            3 -> level2 - 0.5f
            else -> 13f
        }
        aMap?.animateCamera(CameraUpdateFactory.zoomTo(clickedZoom))

        if (annoShowType == showType) {
            locateMarker()
        }
    }

    private fun filterStoreMarkers(ids: List<Int>?) {
        filterIds = ids
        aMap?.animateCamera(CameraUpdateFactory.zoomTo(level0 + 0.5f))

    }

    private fun updateMarkers(addresses: List<AmapParam.AddressInfo>?) {
        if (addresses == null || addresses.isEmpty()) return
        if (annoShowType == 0) {
            // 门店级别
            if (needRefreshStore) {
//                io.flutter.Log.d("diff_test", "重新显示门店")
                // 清除所有Marker
                needRefreshStore = false
                aMap?.clear()
                lastUpdateAddrMarkers.clear()
                storeMap.clear()
                statisticMap.clear()
                // 添加所有地址的Marker
                addresses.forEach { address ->
                    addNewMarkerForStore(address)
                }
            } else {
//                io.flutter.Log.d("diff_test", "门店移动，差异化更新门店")
                // 差异化门店Marker，需要清除统计级别marker
                statisticMap.keys.forEach { marker ->
                    marker.remove()
                }
                statisticMap.clear()

                val oldAddressList = ArrayList<AmapParam.AddressInfo>()
                val oldMarkerMap = HashMap<AmapParam.AddressInfo, Marker>()
                lastUpdateAddrMarkers.forEach { am ->
                    oldAddressList.add(am.address)
                    oldMarkerMap.put(am.address, am.marker)
                }

                val toKeep = ArrayList<AmapParam.AddressInfo>()
                toKeep.addAll(addresses)
                toKeep.retainAll(oldAddressList)
                val toRemove = ArrayList<AmapParam.AddressInfo>()
                toRemove.addAll(addresses)
                toRemove.removeAll(toKeep)
                val toAdd = ArrayList<AmapParam.AddressInfo>()
                toAdd.addAll(addresses)
                toAdd.removeAll(toKeep)

//                io.flutter.Log.d("diff_test", "保留的点：${toKeep.size}")
//                io.flutter.Log.d("diff_test", "删除的点：${toRemove.size}")
//                io.flutter.Log.d("diff_test", "新增的点：${toAdd.size}")

                // 移除Marker
                toRemove.forEach { addr ->
                    val marker = oldMarkerMap[addr]
                    // 地图移除Marker
                    marker?.remove()
                    if (marker != null) {
                        // 缓存移除Marker
                        storeMap.remove(marker)
                    }
                }

                // 添加现有的Marker和地址关系
                lastUpdateAddrMarkers.clear()
                toKeep.forEach { addr ->
                    val marker = oldMarkerMap[addr]
//                    toKeepAddrMarkers.add(Add)
                    if (marker != null) {
                        lastUpdateAddrMarkers.add(AddressMarker(addr, marker))
                    }
                }

                // 添加新的Marker
                toAdd.forEach { address ->
                    addNewMarkerForStore(address)
                }

//                io.flutter.Log.d("diff_test", "lastUpdateAddrMarkers: ${lastUpdateAddrMarkers.size}")

            }
        } else {
//            io.flutter.Log.d("diff_test", "统计级别显示")
            // 统计级别清除所有Marker
            aMap?.clear()
            lastUpdateAddrMarkers.clear()
            storeMap.clear()
            statisticMap.clear()
            needRefreshStore = true

            addresses.forEach { address ->
                if (address.geo != null && address.geo?.lat != null && address.geo?.lng != null) {
                    selectedCityId = null
                    val v = LayoutInflater.from(context).inflate(R.layout.marker_statistic_location, null)
                    v.findViewById<TextView>(R.id.tv_merchant_index).text = address.indexName
                    v.findViewById<TextView>(R.id.tv_count).text = address.index.toString()

                    val option = MarkerOptions()
                        .position(LatLng(address.geo!!.lat, address.geo!!.lng))
                        .title(address.address)
                        .icon(BitmapDescriptorFactory.fromView(v))
                    if (address.showType == 0) {
                        option.anchor(0.5f, 0f)
                    } else {
                        option.anchor(0.5f, 0.5f)

                    }
                    val marker = aMap?.addMarker(option)
                    val anim = ScaleAnimation(0f, 1f, 0f, 1f)
                    anim.setDuration(500)
                    anim.setInterpolator(BounceInterpolator())
                    marker?.setAnimation(anim)
                    marker?.startAnimation()

                    if (marker != null) {
                        statisticMap.put(marker, address)
                    }
                }
            }
        }

        // 添加我的位置
        if (myMarker != null) {
            aMap?.addMarker(myMarker?.options)
        }
        // 手动选择某个Marker点
        locateMarker()
    }
    
    private fun addNewMarkerForStore(address: AmapParam.AddressInfo) {
        if (address.geo != null && address.geo?.lat != null && address.geo?.lng != null) {
            val v = LayoutInflater.from(context).inflate(R.layout.marker_merchant_location, null)
            val tvMerchantIndex = v.findViewById<TextView>(R.id.tv_merchant_index)
            val tvTriangleView = v.findViewById<TriangleView>(R.id.triangle_view)
            tvMerchantIndex.text = address.indexName
            if (selectedCityId != null && selectedCityId != address.parentId) {
//                        io.flutter.Log.d("test_amap", "selectedCityId: $selectedCityId, parentId: ${address.parentId}")
                // 过滤某一县域下的门店
                tvMerchantIndex.background = context?.resources?.getDrawable(R.drawable.shape_title_bg_disable)
                tvTriangleView.setTriangleColor(R.color.color_999999)
            }
            val option = MarkerOptions()
                .position(LatLng(address.geo!!.lat, address.geo!!.lng))
                .title(address.address)
                .icon(BitmapDescriptorFactory.fromView(v))
            if (address.showType == 0) {
                option.anchor(0.5f, 0f)
            } else {
                option.anchor(0.5f, 0.5f)

            }
            val marker = aMap?.addMarker(option)
            val anim = ScaleAnimation(0f, 1f, 0f, 1f)
            anim.setDuration(500)
            anim.setInterpolator(BounceInterpolator())
            marker?.setAnimation(anim)
            marker?.startAnimation()
            if (marker != null) {
                storeMap.put(marker, address)
                lastUpdateAddrMarkers.add(AddressMarker(address, marker))
            }
        }
    }

    private fun locateMarker() {
        if (clickedAreaId != null) {
            // 选择某个marker点
            if (annoShowType == 0) {
                storeMap.keys.forEach { marker ->
                    val addr = storeMap[marker]
                    if (addr != null && addr.id == clickedAreaId) {
                        if (addr.geo?.lat != null && addr.geo?.lng != null) {
                            changeMarkerColor(marker)
                            aMap?.animateCamera(
                                CameraUpdateFactory.newLatLngZoom(
                                    LatLng(addr.geo?.lat!!, addr.geo?.lng!!), clickedZoom
                                )
                            )
                        }
                    }
                }
            } else {
                statisticMap.keys.forEach { marker ->
                    val addr = statisticMap[marker]
                    if (addr != null && addr.id == clickedAreaId) {
                        if (addr.geo?.lat != null && addr.geo?.lng != null) {
                            changeMarkerColor(marker)
                            aMap?.animateCamera(
                                CameraUpdateFactory.newLatLngZoom(
                                    LatLng(addr.geo?.lat!!, addr.geo?.lng!!), clickedZoom
                                )
                            )
                        }
                    }
                }
            }

//            aMap?.mapScreenMarkers?.forEach { marker ->
//                val addr = if (annoShowType == 0) storeMap[marker] else statisticMap[marker]
//                if (addr != null && addr.id == clickedAreaId) {
//                    if (addr.geo?.lat != null && addr.geo?.lng != null) {
//                        changeMarkerColor(marker)
//                        aMap?.animateCamera(
//                            CameraUpdateFactory.newLatLngZoom(
//                                LatLng(addr.geo?.lat!!, addr.geo?.lng!!), clickedZoom
//                            )
//                        )
//                    }
//                }
//            }
            clickedAreaId = null
        }
    }

    private fun changeMarkerColor(marker: Marker?) {
        if (lastSelectedMarker != null) {
            if (annoShowType == 0) {
                val address = storeMap[lastSelectedMarker!!]
                val v = LayoutInflater.from(context).inflate(R.layout.marker_merchant_location, null)
                val tvMerchantIndex = v.findViewById<TextView>(R.id.tv_merchant_index)
                tvMerchantIndex.text = address?.indexName
                tvMerchantIndex.background = context!!.resources.getDrawable(R.drawable.shape_title_bg)
                v.findViewById<TriangleView>(R.id.triangle_view).setTriangleColor(R.color.color_007AFF)
                lastSelectedMarker!!.setIcon(BitmapDescriptorFactory.fromView(v))
            } else {
                val address = statisticMap[lastSelectedMarker!!]
                val v = LayoutInflater.from(context).inflate(R.layout.marker_statistic_location, null)
                v.findViewById<TextView>(R.id.tv_merchant_index).text = address?.indexName
                v.findViewById<View>(R.id.container_statistics_marker).background = context!!.resources.getDrawable(R.drawable.shape_blue)
                v.findViewById<TextView>(R.id.tv_count).text = address?.index.toString()
                lastSelectedMarker!!.setIcon(BitmapDescriptorFactory.fromView(v))
            }
        }

        if (marker == null) return
        if (annoShowType == 0) {
            val address = storeMap[marker]
            val v = LayoutInflater.from(context).inflate(R.layout.marker_merchant_location, null)
            val tvMerchantIndex = v.findViewById<TextView>(R.id.tv_merchant_index)
            tvMerchantIndex.text = address?.indexName
            tvMerchantIndex.background = context!!.resources.getDrawable(R.drawable.shape_title_bg_selected)
            v.findViewById<TriangleView>(R.id.triangle_view).setTriangleColor(R.color.color_54A158)
            marker.setIcon(BitmapDescriptorFactory.fromView(v))
        } else {
            val address = statisticMap[marker]
            val v = LayoutInflater.from(context).inflate(R.layout.marker_statistic_location, null)
            v.findViewById<TextView>(R.id.tv_merchant_index).text = address?.indexName
            v.findViewById<View>(R.id.container_statistics_marker).background = context!!.resources.getDrawable(R.drawable.shape_blue_selected)
            v.findViewById<TextView>(R.id.tv_count).text = address?.index.toString()
            marker.setIcon(BitmapDescriptorFactory.fromView(v))
        }

        lastSelectedMarker = marker
    }

    private fun addMyPositionMarker() {
        if (context != null) {
            val prefs: SharedPreferences = context.applicationContext.getSharedPreferences(
                "pgy_native_cache", Context.MODE_PRIVATE
            )
            val lat = prefs.getFloat("my_location_lat", 0f)
            val lng = prefs.getFloat("my_location_lng", 0f)
            if (lat != 0f && lng != 0f) {
                startAddr.geo = AmapParam.GeoPoint(lat.toDouble(), lng.toDouble())
                val v = LayoutInflater.from(context).inflate(R.layout.marker_my_location, null)
                myMarker = aMap?.addMarker(MarkerOptions()
                    .position(LatLng(lat.toDouble(), lng.toDouble()))
                    .title("我的位置")
                    .infoWindowEnable(true)
                    .icon(BitmapDescriptorFactory.fromView(v)))
                actualMap?.addMerchantMarkers()

                aMap?.animateCamera(
                    CameraUpdateFactory.newLatLngZoom(LatLng(lat.toDouble(), lng.toDouble()), 17f)
                )

                callOnLocate(lat.toDouble(), lng.toDouble())
            } else {
                relocate(isInitial = true)
            }
        }
    }

    private fun relocate(isInitial: Boolean = false) {
        val option = AMapLocationClientOption()
        option.isOnceLocation = true
        val locClient = AMapLocationClient(context?.applicationContext)
        locClient.setLocationOption(option)
        locClient.setLocationListener { aMapLocation ->
            if (aMapLocation != null) {
                if (aMapLocation.errorCode == 0) {
                    /*
                    * 高德定位成功
                    * latitude=22.630025#longitude=114.068273#province=广东省
                    * #coordType=GCJ02#city=深圳市#district=龙岗区
                    * #cityCode=0755#adCode=440307#address=广东省深圳市龙岗区东坡路5号靠近中坡工业园
                    * #country=中国#road=东坡路#poiName=中坡工业园#street=东坡路
                    * #streetNum=5号#aoiName=云里智能园#poiid=#floor=
                    * #errorCode=0#errorInfo=success#locationDetail=
                    * #csid:acae7889d19d4e5fab8591af49478c61#description=在中坡工业园附近
                    * #locationType=4#conScenario=0
                    * */
                    io.flutter.Log.d(TAG, "定位成功: ${aMapLocation.address}, poiName: ${aMapLocation.poiName}, 纬度: ${aMapLocation.latitude}, 经度: ${aMapLocation.longitude}")
                    saveCurrentLocation(aMapLocation)

                    callOnLocate(aMapLocation.latitude, aMapLocation.longitude)
                    if (isInitial) {
                        // 没有本地缓存经纬度的情况
                        actualMap?.addMerchantMarkers()
                    }
                    aMap?.animateCamera(
                        CameraUpdateFactory.newLatLngZoom(LatLng(aMapLocation.latitude, aMapLocation.longitude), 17f)
                    )
                    // 保存起始地点
                    startAddr.geo = AmapParam.GeoPoint(aMapLocation.latitude, aMapLocation.longitude)
                    if (myMarker == null) {
                        val v = LayoutInflater.from(context).inflate(R.layout.marker_my_location, null)
                        myMarker = aMap?.addMarker(MarkerOptions()
                            .position(LatLng(aMapLocation.latitude, aMapLocation.longitude))
                            .title("我的位置")
                            .infoWindowEnable(true)
                            .icon(BitmapDescriptorFactory.fromView(v)))
                    } else {
                        myMarker?.position = LatLng(aMapLocation.latitude, aMapLocation.longitude)
                    }
                } else {
                    io.flutter.Log.e(TAG, "定位失败：errorCode = ${aMapLocation.errorCode}, detail: ${aMapLocation.locationDetail} ")
                }
            } else {
//                Timber.e("aMapLocation is null ")
            }
        }

        locClient.startLocation()
    }

    private fun callOnLocate(lat: Double, lng: Double) {
        val args = HashMap<String, Any?>()
        args["lat"] = lat
        args["lng"] = lng
        methodChannel.invokeMethod("onLocate", args)
    }

    private fun saveCurrentLocation(location: AMapLocation) {
        if (context != null) {
            val prefs: SharedPreferences = context.getSharedPreferences(
                "pgy_native_cache", Context.MODE_PRIVATE
            )
            prefs.edit().apply {
                putFloat("my_location_lat", location.latitude.toFloat())
                putFloat("my_location_lng", location.longitude.toFloat())
            }.apply()
        }
    }

    private fun searchRoute(startAddr: AmapParam.AddressInfo?, endAddr: AmapParam.AddressInfo?, success: (String) -> Unit = {}) {
        if (startAddr == null || endAddr == null) return
        val routeSearch = RouteSearch(context)
        routeSearch.setRouteSearchListener(MapRouteSearchListener(
//            context = context,
//            aMap = aMap,
//            startAddr = startAddr,
//            endAddr = endAddr,
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
//        private val context: Context?,
//        private val aMap: AMap?,
//        private val startAddr: AmapParam.AddressInfo,
//        private val endAddr: AmapParam.AddressInfo,
        private val success: (String) -> Unit
    ) : RouteSearch.OnRouteSearchListener {
        override fun onDriveRouteSearched(result: DriveRouteResult?, errorCode: Int) {
            // 驾车路线查询
            if (errorCode == AMapException.CODE_AMAP_SUCCESS && result?.paths != null && result.paths.size > 0) {
                val drivePath: DrivePath = result.paths[0] ?: return

//                val overlay = DrivingRouteOverlay(
//                    context,
//                    aMap,
//                    drivePath,
//                    result.startPos,
//                    result.targetPos,
//                    null,
//                    null,
//                    null
//                )
//                driverOverlayList.add(overlay)
//                overlay.setNodeIconVisibility(false)//设置节点marker是否显示
//                overlay.setIsColorfulline(true)//是否用颜色展示交通拥堵情况，默认true
//                overlay.removeFromMap()
//                overlay.addToMap(startAddr.address, endAddr.address)
//
//                // 路径缩放级别，值越小，信息越详细
//                overlay.zoomToSpan(context?.resources?.getDimension(R.dimen.map_zoom_edge_width)?.toInt() ?: 300)

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
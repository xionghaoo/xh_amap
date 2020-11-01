package com.pgy.xhamap.mapview

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.view.View
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
import com.google.gson.Gson
import com.pgy.xhamap.R
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * 高德地图，每次打开页面时都会创建新的MapView，
 * 移动地图时调用getView刷新绘制，关闭页面时调用dispose方法
 */
class FlutterAmapView(
    private val context: Context?,
    private val lifecycle: Lifecycle?,
    private val param: AmapParam,
    private val binaryMessenger: BinaryMessenger?
) : PlatformView, DefaultLifecycleObserver, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "FlutterAmapView"
    }

    private var aMap: AMap? = null
    private var mapView: MapView = MapView(context)
    private var myMarker: Marker? = null

    private var actualMap: IActualMap? = null

    private var methodChannel = MethodChannel(binaryMessenger, "xh.zero/amap_view_method")

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
        if (param.enableMyLocation) {
            val locationStyle = MyLocationStyle()
            locationStyle.myLocationType(MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER)
//            locationStyle.strokeColor(resources.getColor(R.color.overlay_map_location))
            locationStyle.strokeWidth(0f)
//            locationStyle.radiusFillColor(resources.getColor(R.color.overlay_map_location))
            locationStyle.interval(5000)
            aMap?.myLocationStyle = locationStyle
            aMap?.isMyLocationEnabled = true

            aMap?.setOnMyLocationChangeListener { location ->

//                myMarker?.position = LatLng(location.latitude, location.longitude)
            }
        }
//        Log.d("FlutterAmapView", "${Gson().toJson(param)}")
        when(param.mapType) {
            AmapParam.ROUTE_MAP ->
                actualMap = RouteMapImpl(context, aMap, param, methodChannel)
            AmapParam.ADDRESS_DESCRIPTION_MAP ->
                actualMap = AddressDescriptionMapImpl(context, aMap, param)
            else -> {}
        }
        actualMap?.onCreate()
        // 开启我当前的位置Marker
        if (param.enableMyMarker) {
            // 定位蓝点
            addMyPositionMarker()
        }


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
        }
    }

    private fun addMyPositionMarker() {
        if (context != null) {
            val prefs: SharedPreferences = context.applicationContext.getSharedPreferences(
                "pgy_native_cache", Context.MODE_PRIVATE
            )
            val lat = prefs.getFloat("my_location_lat", 0f)
            val lng = prefs.getFloat("my_location_lng", 0f)
            if (lat != 0f && lng != 0f) {
                myMarker = aMap?.addMarker(MarkerOptions()
                    .position(LatLng(lat.toDouble(), lng.toDouble()))
                    .title("MyPosition")
                    .infoWindowEnable(false)
                    .icon(BitmapDescriptorFactory.fromResource(R.mipmap.ic_car)))
                actualMap?.addMerchantMarkers()
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
                    if (isInitial) {
                        // 没有本地缓存经纬度的情况
                        actualMap?.addMerchantMarkers()
                    } else {
                        aMap?.animateCamera(CameraUpdateFactory.newLatLng(LatLng(aMapLocation.latitude, aMapLocation.longitude)))
                    }
                    if (myMarker == null) {
                        myMarker = aMap?.addMarker(MarkerOptions()
                            .position(LatLng(aMapLocation.latitude, aMapLocation.longitude))
                            .title("MyPosition")
                            .infoWindowEnable(false)
                            .icon(BitmapDescriptorFactory.fromResource(R.mipmap.ic_car)))
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
}
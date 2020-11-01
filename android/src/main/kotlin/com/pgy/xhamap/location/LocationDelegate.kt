package com.pgy.xhamap.location

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.location.LocationManager
import android.os.IBinder
import com.amap.api.location.AMapLocation
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.BinaryMessenger
import java.lang.Exception

class LocationDelegate(
    private val context: Context,
    private val messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    private lateinit var locationService: LocationService
    private var mBound: Boolean = false
    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as LocationService.LocationBinder
            locationService = binder.getService()
            locationService.setLocationListener(object : LocationService.LocationListener {
                override fun onLocated(location: AMapLocation) {
                    io.flutter.Log.d("LocationPlugin", "定位成功: ${location.address}, poiName: ${location.poiName}, 纬度: ${location.latitude}, 经度: ${location.longitude}")
                    val map = HashMap<String, Any>()
                    map.apply {
                        put("address", location.address)
                        put("lat", location.latitude)
                        put("lng", location.longitude)
                    }
                    eventSink?.success(map)
                }
            })
            mBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            mBound = false
        }
    }

    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    init {
        register(messenger)
    }

    private fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, "com.pgy/amap_location")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(messenger, "com.pgy/amap_location_stream")
        eventChannel?.setStreamHandler(this)
    }

    fun unregister() {
        LocationService.stopService(context, connection)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startLocation" -> {
//                PermissionManager.checkMulti(context,
//                    arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION,
//                        Manifest.permission.ACCESS_FINE_LOCATION,
//                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
//                        Manifest.permission.READ_EXTERNAL_STORAGE),
//                    disallow = {
//                        // 权限不允许
////                        branchActivityDelegate?.showLocationFailureCover(true, permissionForbidden = true)
//                        result.error("101", "权限不允许", null)
//                    },
//                    permissionName = "位置、存储") {
//
//                    // 检查位置服务是否开启，如果未开启，弹出提示框
////                    if (!isLocationServiceEnabled()) {
////                        LocationService.startLocationService(context)
////                        result.success(null)
////                    } else {
////                        result.error("100", "未开启定位服务", null)
////                    }
//                }

                LocationService.startService(context, connection)
                result.success(null)
            }
            "stopLocation" -> {
                LocationService.stopService(context, connection)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun isLocationServiceEnabled() : Boolean {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        var gpsEnabled = false
        var networkEnabled = false
        try {
            gpsEnabled = lm.isProviderEnabled(LocationManager.GPS_PROVIDER)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            networkEnabled = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return gpsEnabled || networkEnabled
    }

    override fun onDetachedFromActivity() {
        
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        
    }

    override fun onDetachedFromActivityForConfigChanges() {
        
    }

//    private inner class LocationRequestPermissionsListener: PluginRegistry.RequestPermissionsResultListener {
//        override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
//
//        }
//    }
}
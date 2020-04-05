package com.pgy.xhamap

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.location.Location
import android.location.LocationManager
import android.os.IBinder
import android.util.Log
import androidx.lifecycle.Lifecycle
import com.amap.api.location.AMapLocation
import com.amap.api.maps.MapsInitializer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.lang.Exception

class LocationPlugin(
    private val context: Activity
) : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    companion object {
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar, context: Activity) {
            val channel = MethodChannel(registrar.messenger(), "com.pgy/amap_location")
            channel.setMethodCallHandler(LocationPlugin(context))
        }
    }

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
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        val channelInitial = MethodChannel(binding.binaryMessenger, "com.pgy/amap_initial")
        channelInitial.setMethodCallHandler(this);
        val channel = MethodChannel(binding.binaryMessenger, "com.pgy/amap_location")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.pgy/amap_location_stream")
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        LocationService.stopService(context, connection)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initial" -> {
//                Log.d("LocationPlugin", "key: ${call.argument("apiKey") as? String}")
                MapsInitializer.setApiKey(call.argument("apiKey") as? String)
                result.success(null)
            }
            "startLocation" -> {
                PermissionManager.checkMulti(context,
                    arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION,
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
                        Manifest.permission.READ_EXTERNAL_STORAGE),
                    disallow = {
                        // 权限不允许
//                        branchActivityDelegate?.showLocationFailureCover(true, permissionForbidden = true)
                        result.error("101", "权限不允许", null)
                    },
                    permissionName = "位置、存储") {
                    LocationService.startService(context, connection)
                    result.success(null)
                    // 检查位置服务是否开启，如果未开启，弹出提示框
//                    if (!isLocationServiceEnabled()) {
//                        LocationService.startLocationService(context)
//                        result.success(null)
//                    } else {
//                        result.error("100", "未开启定位服务", null)
//                    }
                }
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
}
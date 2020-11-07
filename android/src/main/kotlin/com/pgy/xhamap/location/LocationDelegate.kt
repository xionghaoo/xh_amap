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
    eventSink: EventChannel.EventSink?
) : ActivityAware {

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

    fun startContinuousLocation(context: Context) {
        LocationService.startService(context, connection)
    }

    fun stopContinuousLocation(context: Context) {
        LocationService.stopService(context, connection)
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
package com.pgy.xhamap

import android.content.Context
import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver
import com.amap.api.maps.MapsInitializer
import com.pgy.xhamap.location.LocationDelegate
import com.pgy.xhamap.location.LocationService
import com.pgy.xhamap.mapview.AmapViewDelegate
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** XhamapPlugin */
public class XhamapPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware, DefaultLifecycleObserver {

  private var locationDelegate: LocationDelegate? = null
  private var amapViewDelegate: AmapViewDelegate? = null

  private var locationEventChannel: EventChannel? = null
  private var locationEventSink: EventChannel.EventSink? = null
  private var locationMethod: MethodChannel? = null
  
  private var context: Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    val channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.pgy/amap_initial")
    locationMethod = MethodChannel(flutterPluginBinding.binaryMessenger, "com.pgy/amap_location")
    locationMethod?.setMethodCallHandler(this)
    locationEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.pgy/amap_location_stream")
    locationEventChannel?.setStreamHandler(this)
    locationDelegate = LocationDelegate(flutterPluginBinding.applicationContext, locationEventSink)
    amapViewDelegate = AmapViewDelegate(flutterPluginBinding)
    channel.setMethodCallHandler(this)
  }

  companion object {
//    @JvmStatic
//    fun registerWith(registrar: Registrar) {
//      val channel = MethodChannel(registrar.messenger(), "com.pgy/amap_initial")
//      channel.setMethodCallHandler(XhamapPlugin(LocationDelegate(registrar.context(), registrar.messenger())))
//
//    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when(call.method) {
      "initial" -> {
        MapsInitializer.setApiKey(call.argument("apiKey") as? String)
        result.success(null)
      }
      "startLocation" -> {
        locationDelegate?.startContinuousLocation(context!!)
        result.success(null)
      }
      "stopLocation" -> {
        locationDelegate?.stopContinuousLocation(context!!)
      }
      "locateOnce" -> {
        LocationService.locateOnce(context!!, 
            failure = {
              result.error("-1", "定位失败", null)    
            }
        ) { location -> 
            val args = HashMap<String, Any?>()
            args["lat"] = location.latitude
            args["lng"] = location.longitude
            args["province"] = location.province
            args["district"] = location.district
            args["city"] = location.city
            args["address"] = location.address
            result.success(null)
            locationMethod?.invokeMethod("onOnceLocation", args)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    locationEventSink = events
  }

  override fun onCancel(arguments: Any?) {
    locationEventSink = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    amapViewDelegate?.onDetachedFromEngine()
    locationDelegate?.stopContinuousLocation(context!!)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    amapViewDelegate?.onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    amapViewDelegate?.onDetachedFromActivityForConfigChanges()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    amapViewDelegate?.onReattachedToActivityForConfigChanges(binding)
  }

  override fun onDetachedFromActivity() {
    amapViewDelegate?.onDetachedFromActivity()
  }
}

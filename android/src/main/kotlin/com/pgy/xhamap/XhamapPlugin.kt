package com.pgy.xhamap

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver
import com.amap.api.maps.MapsInitializer
import com.pgy.xhamap.location.LocationDelegate
import com.pgy.xhamap.mapview.AmapViewDelegate
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** XhamapPlugin */
public class XhamapPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, DefaultLifecycleObserver {

  private var locationDelegate: LocationDelegate? = null
  private var amapViewDelegate: AmapViewDelegate? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.pgy/amap_initial")
    locationDelegate = LocationDelegate(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
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
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    amapViewDelegate?.onDetachedFromEngine()
    locationDelegate?.unregister()
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

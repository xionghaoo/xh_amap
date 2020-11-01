package com.pgy.xhamap.mapview

import android.util.Log
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import com.pgy.xhamap.FlutterLifecycleAdapter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class AmapViewDelegate(
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding?
) {

    private var lifecycle: Lifecycle? = null

    companion object {

        // v1版本插件的注册方式
//        fun registerWith(registrar: PluginRegistry.Registrar) {
//            if (registrar.activity() == null) return
//            val plugin = AmapViewPlugin()
//            registrar.platformViewRegistry()
//                    .registerViewFactory(VIEW_TYPE_ID, AmapViewFactory(null))
//
//        }
    }

    // FlutterPlugin

    fun onDetachedFromEngine() {
        pluginBinding = null
    }

    // ActivityAware
    fun onDetachedFromActivity() {
    }

    fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
    }

    fun onAttachedToActivity(binding: ActivityPluginBinding) {
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
        pluginBinding?.platformViewRegistry
                ?.registerViewFactory("xh.zero/amap_view", AmapViewFactory(lifecycle, pluginBinding?.binaryMessenger))


    }

    fun onDetachedFromActivityForConfigChanges() {

    }
}
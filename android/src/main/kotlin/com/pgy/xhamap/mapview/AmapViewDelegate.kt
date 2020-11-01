package com.pgy.xhamap.mapview

import android.util.Log
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import com.pgy.xhamap.FlutterLifecycleAdapter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class AmapViewDelegate : ActivityAware, DefaultLifecycleObserver {

    private var lifecycle: Lifecycle? = null
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    companion object {
        const val VIEW_TYPE_ID = "xh.zero/amap_view"

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
    fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = binding
    }

    fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = null
    }

    // ActivityAware
    override fun onDetachedFromActivity() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
        pluginBinding?.platformViewRegistry
                ?.registerViewFactory(VIEW_TYPE_ID, AmapViewFactory(lifecycle, pluginBinding?.binaryMessenger))


    }

    override fun onDetachedFromActivityForConfigChanges() {

    }
}
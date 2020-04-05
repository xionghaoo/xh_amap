package com.pgy.xhamap

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class UploadLocationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        context.sendBroadcast(Intent(LocationService.ACTION_LOCATION_SERVICE_RECEIVER))
    }
}

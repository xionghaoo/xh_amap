package com.pgy.xhamap.location

import android.app.*
import android.content.*
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.pgy.xhamap.R
import java.util.*

class LocationService : Service() {

    companion object {
        const val TAG = "LocationService"
        const val EXTRA_STOP = "extra_stop"
        const val CHANNEL_ID = "location_channel"

        const val ACTION_LOCATION_SERVICE_RECEIVER = "com.pgy.xhamap.location.LocationService.ACTION_LOCATION_SERVICE_RECEIVER"

//        fun startLocationService(context: Context, bundle: Bundle? = null) {
//            val intent = Intent(context, LocationService::class.java)
//            bundle?.also { intent.putExtras(it) }
//            context.startService(intent)
//        }
//
//        fun stopLocationService(context: Context) {
//            val bundle = Bundle()
//            bundle.putBoolean(EXTRA_STOP, true)
//            startLocationService(context, bundle)
//        }

        fun startService(context: Context, connection: ServiceConnection) {
            Intent(context, LocationService::class.java).also { intent ->
//                intent.putExtra(EXTRA_UPDATE_URL, url)
//                intent.putExtra(EXTRA_IS_FORCE, isForce)
                context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            }
        }

        fun stopService(context: Context, connection: ServiceConnection) {
            context.unbindService(connection)
        }
    }

    private val binder: LocationBinder = LocationBinder()
    private var listener: LocationListener? = null

    private var locClient: AMapLocationClient? = null
//    private val locations = ArrayList<LocationRequest>()

    private var alarmMgr: AlarmManager? = null
    private var alarmIntent: PendingIntent?=  null

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
//            Timber.d("LocationService BroadcastReceiver, 上传位置信息")
//            uploadLocationInfo()
        }
    }

    override fun onCreate() {
        super.onCreate()


    }

//    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
//        if (intent != null && intent.extras != null) {
//            if (intent.getBooleanExtra(EXTRA_STOP, false)) {
//                stopForeground(true)
//                stopSelf()
//            }
//        } else {
//            showNotification()
//        }
//
//        return Service.START_STICKY
//    }


    override fun onBind(intent: Intent): IBinder? {
        // 高德定位配置项
        val option = AMapLocationClientOption()
        option.interval = 30_000L

        locClient = AMapLocationClient(applicationContext)
        locClient?.setLocationOption(option)
        locClient?.setLocationListener { aMapLocation ->
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
//                    Log.d("LocationPlugin", "定位成功: ${aMapLocation.address}, poiName: ${aMapLocation.poiName}, 纬度: ${aMapLocation.latitude}, 经度: ${aMapLocation.longitude}")
                    listener?.onLocated(aMapLocation)
//                    repo.prefs.setLocation(LatLonPoint(aMapLocation.latitude, aMapLocation.longitude))
//                    repo.prefs.setUserAddress(UserAddress(
//                        province = aMapLocation.province,
//                        city = aMapLocation.city,
//                        area = aMapLocation.district,
//                        address = aMapLocation.address,
//                        geo = Location(aMapLocation.longitude, aMapLocation.latitude)
//                    ))
//                    saveLocations(aMapLocation)
//                    sendBroadcast(Intent(MainActivity.ACTION_LOCATE_SUCCESS))
                } else {
//                    sendBroadcast(Intent(MainActivity.ACTION_LOCATE_FAILURE))
                    Log.e(TAG, "定位失败：errorCode = ${aMapLocation.errorCode}, detail: ${aMapLocation.locationDetail} ")
                }
            } else {
                Log.e(TAG, "aMapLocation is null ")
            }
        }

        locClient?.startLocation()

        // 开启系统时钟，比较省电
//        startAlarmClockTask()
        val filter = IntentFilter(ACTION_LOCATION_SERVICE_RECEIVER)
        registerReceiver(receiver, filter)

//        if (intent != null && intent.extras != null) {
//            if (intent.getBooleanExtra(EXTRA_STOP, false)) {
//                stopForeground(true)
//                stopSelf()
//            }
//        } else {
//            showNotification()
//        }
        showNotification()
        return binder
    }

    override fun onUnbind(intent: Intent?): Boolean {
        stopForeground(true)

        locClient?.stopLocation()
        // 停止系统时钟，比较省电
//        stopAlarmClockTask()
        unregisterReceiver(receiver)
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    /**
     * 位置上传时使用
     */
    private fun startAlarmClockTask() {
        // 用AlarmManager，节省电量
        alarmMgr = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmIntent = Intent(this, UploadLocationReceiver::class.java).let { intent ->
            PendingIntent.getBroadcast(this, 0, intent, 0)
        }
        val time = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
        }
        // 精确时间，黑屏时也执行
        alarmMgr?.setRepeating(AlarmManager.RTC_WAKEUP, time.timeInMillis, 60_000L, alarmIntent)
        // 不精确时间
//        alarmMgr?.setInexactRepeating(AlarmManager.RTC_WAKEUP, time.timeInMillis, 1000 * 60, alarmIntent)
    }

    private fun stopAlarmClockTask() {
        alarmMgr?.cancel(alarmIntent)
    }

    private fun showNotification() {
        val mNotifyManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create the NotificationChannel, but only on API 26+ because
            // the NotificationChannel class is new and not in the support library
            val name = "amap_loc"
            val description = "none"
            val channel = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT)
            channel.description = description
            // Register the channel with the system
            mNotifyManager.createNotificationChannel(channel)
        }

        //Ticker是状态栏显示的提示
        builder.setTicker("蒲公英")
        //第一行内容  通常作为通知栏标题
        builder.setContentTitle("蒲公英")
        //第二行内容 通常是通知正文
        builder.setContentText("蒲公英正在运行...")
        //可以点击通知栏的删除按钮删除
        builder.setAutoCancel(false)
        //系统状态栏显示的小图标
        builder.setSmallIcon(R.drawable.dir_start)
//        val intent = Intent(this, MainActivity::class.java)
//        val pIntent = PendingIntent.getActivity(this, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT)
//        builder.setContentIntent(pIntent)
        //通知默认的声音 震动 呼吸灯
//        builder.setDefaults(NotificationCompat.DEFAULT_ALL);
        val notification = builder.build()
        startForeground(1000, notification)

    }

    fun setLocationListener(_listener: LocationListener) {
        listener = _listener
    }

    inner class LocationBinder : Binder() {
        fun getService() : LocationService = this@LocationService
    }

    interface LocationListener {
        fun onLocated(location: AMapLocation)
    }
}

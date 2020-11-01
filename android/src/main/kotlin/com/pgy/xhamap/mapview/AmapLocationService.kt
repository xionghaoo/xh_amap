package com.pgy.xhamap.mapview

import android.app.*
import android.content.*
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.annotation.Keep
import androidx.core.app.NotificationCompat
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.google.gson.Gson
import com.pgy.xhamap.R
import okhttp3.*
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList

/**
 * 高德定位服务
 */
@Keep
class AmapLocationService : Service() {

//    @Inject lateinit var repo: Repository

    companion object {

        const val TAG = "LocationService"
        const val EXTRA_STOP = "extra_stop"
        const val CHANNEL_ID = "location_channel"

        private const val EXTRA_UPLOAD_URL = "EXTRA_UPLOAD_URL"
        private const val EXTRA_TOKEN_KEY = "EXTRA_LOCATION_INTERVAL"
        private const val EXTRA_TOKEN_VALUE = "EXTRA_UPLOAD_INTERVAL"

        fun startLocationService(context: Context, uploadUrl: String?, tokenKey: String?, tokenValue: String?) {
            val intent = Intent(context, AmapLocationService::class.java).also { intent ->
                intent.putExtra(EXTRA_UPLOAD_URL, uploadUrl)
                intent.putExtra(EXTRA_TOKEN_KEY, tokenKey)
                intent.putExtra(EXTRA_TOKEN_VALUE, tokenValue)
            }
            context.startService(intent)
        }

        fun stopLocationService(context: Context) {
            val intent = Intent(context, AmapLocationService::class.java).also { intent ->
                intent.putExtra(EXTRA_STOP, true)
            }
            context.startService(intent)
        }
    }

    private var locClient: AMapLocationClient? = null
    private val locations = ArrayList<LocationRequest>()

    private var uploadUrl: String? = null
    private var tokenKey: String? = null
    private var tokenValue: String? = null

    private var lastUploadTime: Long = 0L

    override fun onCreate() {
        super.onCreate()
        io.flutter.Log.d(TAG, "onCreate")

        // 高德定位配置项
        val option = AMapLocationClientOption()
        option.interval = 20_000L

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
                    Log.d(TAG,"定位成功: ${aMapLocation.address}, poiName: ${aMapLocation.poiName}, 纬度: ${aMapLocation.latitude}, 经度: ${aMapLocation.longitude}")
//                    repo.prefs.setLocation(LatLonPoint(aMapLocation.latitude, aMapLocation.longitude))
//                    repo.prefs.setUserAddress(UserAddress(
//                        province = aMapLocation.province,
//                        city = aMapLocation.city,
//                        area = aMapLocation.district,
//                        address = aMapLocation.address,
//                        geo = Location(aMapLocation.longitude, aMapLocation.latitude)
//                    ))
                    saveLocations(aMapLocation)
                    if (System.currentTimeMillis() - lastUploadTime > 60 * 1000) {
//                        Log.d(TAG, "上传位置")
                        lastUploadTime = System.currentTimeMillis()
                        uploadLocationInfo()
                    }
                    saveCurrentLocation(aMapLocation)
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
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        io.flutter.Log.d(TAG, "onStartCommand")

        uploadUrl = intent.getStringExtra(EXTRA_UPLOAD_URL)
        tokenKey = intent.getStringExtra(EXTRA_TOKEN_KEY)
        tokenValue = intent.getStringExtra(EXTRA_TOKEN_VALUE)

        if (intent.getBooleanExtra(EXTRA_STOP, false)) {
            stopForeground(true)
            stopSelf()
        } else {
            showNotification()
        }

        return Service.START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onDestroy() {
        io.flutter.Log.d(TAG, "stop service")
        locClient?.stopLocation()
        super.onDestroy()
    }

    private fun saveCurrentLocation(location: AMapLocation) {
        val prefs: SharedPreferences = applicationContext.getSharedPreferences(
            "pgy_native_cache", Context.MODE_PRIVATE
        )
        prefs.edit().apply {
            putFloat("my_location_lat", location.latitude.toFloat())
            putFloat("my_location_lng", location.longitude.toFloat())
        }.apply()
    }

    private fun uploadLocationInfo() {
        if (locations.size == 0 || tokenKey == null || tokenValue == null) return

        val data = Gson().toJson(locations)
        val client = OkHttpClient()
        val body = RequestBody.create(MediaType.get("application/json; charset=utf-8"), data)
        val request = Request.Builder()
            .url(uploadUrl!!)
            .addHeader(tokenKey!!, tokenValue!!)
            .post(body)
            .build()
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.d(TAG, "上传失败: ${e.localizedMessage}")
            }

            override fun onResponse(call: Call, response: Response) {
                val responseStr = response.body()?.string()
                val result = Gson().fromJson(responseStr, LocationResult::class.java)
//                Log.d(TAG, "上传结果: ${responseStr}")
                if (result.code == 0) {
                    Log.d(TAG, "上传成功: ${data}")
                    locations.clear()
                } else {
                    Log.d(TAG, "上传失败: ${result.message}")
                }
            }
        })
        
//        repo.uploadLocationInfo(locations, repo.prefs.accessToken).enqueue(object : Callback<CommonResult> {
//            override fun onResponse(call: Call<CommonResult>, response: Response<CommonResult>) {
//                if (response.isSuccessful) {
//                    Timber.d("上传位置信息成功")
//                    locations.clear()
//                }
//            }
//
//            override fun onFailure(call: Call<CommonResult>, t: Throwable) {
//                Timber.d("上传位置信息失败：${t.localizedMessage}")
//            }
//        })
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
        builder.setSmallIcon(R.mipmap.ic_launcher)
//        val intent = Intent(this, MainActivity::class.java)
//        val pIntent = PendingIntent.getActivity(this, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT)
//        builder.setContentIntent(pIntent)
        //通知默认的声音 震动 呼吸灯
//        builder.setDefaults(NotificationCompat.DEFAULT_ALL);
        val notification = builder.build()
        startForeground(1000, notification)
    }

    private fun saveLocations(loc: AMapLocation) {

        val info = LocationRequest()
        val geo = GeoRequest()
        geo.setLat(loc.getLatitude())
        geo.setLng(loc.getLongitude())
        info.c_time = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.CHINA).format(Date())
        info.geo = geo
        info.speed = Math.round(loc.speed * 100f) / 100f
        info.direction = loc.bearing.toString()
        info.model = Build.MODEL
        info.release = Build.VERSION.RELEASE
        info.brand = Build.BRAND
        info.province = loc.province
        info.city = loc.city
        info.area = loc.district
        info.address = loc.address
//        Log.d(TAG, "add info : ${Gson().toJson(info)}, address: ${info.address}")
        locations.add(info)
    }

}

package com.pgy.xhamap.mapview

import androidx.annotation.Keep
import java.io.Serializable

/**
 * Created by 杀死凯 on 2016/9/6.
 * 记录本地位置
 */
@Keep
class LocationRequest {

    //经纬度
    var geo: GeoRequest? = null
    //定位时间
    var c_time: String? = null
    //速度，仅gps定位结果时有速度信息，单位公里/小时，默认值0.0f
    var speed: Float? = null
    //gps定位结果时，行进的方向，单位度
    var direction: String? = null

    var member_id: Int = 0
    private val driver_id: Int = 0

    //手机型号
    var model: String? = null
    //系统版本
    var release: String? = null
    //品牌
    var brand: String? = null

    var province: String? = null
    var city: String? = null
    var area: String? = null
    var address: String? = null
}

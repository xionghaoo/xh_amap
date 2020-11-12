package com.pgy.xhamap.mapview

import com.amap.api.maps.model.Marker

data class AddressMarker(
    var address: AmapParam.AddressInfo,
    var marker: Marker
)
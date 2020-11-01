package com.pgy.xhamap.mapview;

import androidx.annotation.Keep;

import java.io.Serializable;

/**
 * Created by 杀死凯 on 2016/9/8.
 */
@Keep
public class GeoRequest implements Serializable {
    private double lat;
    private double lng;

    public double getLat() {
        return lat;
    }

    public void setLat(double lat) {
        this.lat = lat;
    }

    public double getLng() {
        return lng;
    }

    public void setLng(double lng) {
        this.lng = lng;
    }
}
//
//  PointAnnotation.swift
//  xhamap
//
//  Created by xionghao on 2020/11/7.
//

class PointAnnotation: NSObject, MAAnnotation {
    var coordinate: CLLocationCoordinate2D

    var count: Int = 0
    var title: String?
    var subtitle: String?
    
    func hash() -> Int {
        let toHash = String(format: "%.5F%.5F%ld", coordinate.latitude, coordinate.longitude, Int(count))
        return toHash.hash
    }

    func isEqual(_ object: NSObject) -> Bool {
        return hash() == object.hash
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

//
//  PointAnnotation.swift
//  xhamap
//
//  Created by xionghao on 2020/11/7.
//

class PointAnnotation: NSObject, MAAnnotation {
    var coordinate: CLLocationCoordinate2D

    var color: UIColor = UIColor(red: 86 / 255.0, green: 131 / 255.0, blue: 239 / 255.0, alpha: 1.0)
    var title: String?
    var subtitle: String?
    
    func hash() -> Int {
        let toHash = String(format: "%.5F%.5F%ld", coordinate.latitude, coordinate.longitude)
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

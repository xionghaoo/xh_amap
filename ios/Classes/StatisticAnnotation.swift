//
//  StatisticAnnotation.swift
//  xhamap
//
//  Created by xionghao on 2020/11/6.
//

class StatisticAnnotation: NSObject {
    var coordinate: CLLocationCoordinate2D?
    var count = 0
    var title: String?
    var subtitle: String?
    
    func hash() -> Int {
        let toHash = String(format: "%.5F%.5F%ld", coordinate?.latitude as! CVarArg, coordinate?.longitude as! CVarArg, Int(count))
        return toHash.hash
    }

    func isEqual(_ object: NSObject) -> Bool {
        return hash() == NSObject.hash()
    }
    
//    init(coordinate: CLLocationCoordinate2D, count: Int) {
//        super.init()
//        self.coordinate = coordinate
//        self.count = count
//    }
}

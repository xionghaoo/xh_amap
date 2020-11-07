//
//  PointAnnotationView.swift
//  xhamap
//
//  Created by xionghao on 2020/11/7.
//

class PointAnnotationView: MAAnnotationView {
    
    var titleLabel: UILabel!
    
    override init!(annotation: MAAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // 返回rect的中心.
    func RectCenter(_ rect: CGRect) -> CGPoint {
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    // 返回中心为center，尺寸为rect.size的rect.
    func CenterRect(_ rect: CGRect, _ center: CGPoint) -> CGRect {
        let r = CGRect(
            x: center.x - rect.size.width / 2.0,
            y: center.y - rect.size.height / 2.0,
            width: rect.size.width,
            height: rect.size.height)
        return r
    }
    
    private func setupLabel() {
        titleLabel = UILabel()
        titleLabel.backgroundColor = UIColor.blue
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.shadowColor = UIColor(white: 0.0, alpha: 0.75)
        titleLabel.shadowOffset = CGSize(width: 0, height: -1)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        titleLabel.baselineAdjustment = .alignCenters
        titleLabel.layer.cornerRadius = 8.0
        titleLabel.clipsToBounds = true
        addSubview(titleLabel)
    }
    
    func setLabel(title: String) {
        titleLabel.text = title
        setNeedsDisplay()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let subViews = subviews
        if subViews.count > 1 {
            for aSubView in subViews {
                guard let aSubView = aSubView as? UIView else {
                    continue
                }
                if aSubView.point(inside: convert(point, to: aSubView), with: event) {
                    return true
                }
            }
        }
        if point.x > 0 && point.x < frame.size.width && point.y > 0 && point.y < frame.size.height {
            return true
        }
        return false
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        addBounceAnnimation()
    }
    
    func addBounceAnnimation() {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")

        bounceAnimation.values = [NSNumber(value: 0.05), NSNumber(value: 1.1), NSNumber(value: 0.9), NSNumber(value: 1)]
        bounceAnimation.duration = 0.6

        var timingFunctions = [AnyHashable](repeating: 0, count: bounceAnimation.values?.count ?? 0)
        for i in 0..<(bounceAnimation.values?.count ?? 0) {
            timingFunctions.append(CAMediaTimingFunction(name: .easeInEaseOut))
        }
        bounceAnimation.timingFunctions = timingFunctions as? [CAMediaTimingFunction]

        bounceAnimation.isRemovedOnCompletion = false

        layer.add(bounceAnimation, forKey: "bounce")
    }
    
//    override func draw(_ rect: CGRect) {
//        let context = UIGraphicsGetCurrentContext()
//
//        context?.setAllowsAntialiasing(true)
//
//        let outerCircleStrokeColor = UIColor(white: 0, alpha: 0.25)
//        let innerCircleStrokeColor = UIColor.white
//        let innerCircleFillColor = UIColor(red: 86 / 255.0, green: 131 / 255.0, blue: 239 / 255.0, alpha: 1.0)
//
//        let circleFrame = rect.insetBy(dx: 4, dy: 4)
//
//        outerCircleStrokeColor.setStroke()
//        context?.setLineWidth(5.0)
//        context?.strokeEllipse(in: circleFrame)
//
//        innerCircleStrokeColor.setStroke()
//        context?.setLineWidth(4)
//        context?.strokeEllipse(in: circleFrame)
//
//        innerCircleFillColor.setFill()
//        context?.fillEllipse(in: circleFrame)
//    }
}

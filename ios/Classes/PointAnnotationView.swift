//
//  PointAnnotationView.swift
//  xhamap
//
//  Created by xionghao on 2020/11/7.
//

//@available(iOS 9.0, *)
@available(iOS 9.0, *)
class PointAnnotationView: MAAnnotationView {
    
    var titleLabel: UILabel!
    var triangleView: TriangleView?
    var stackView: UIStackView!
//    var triangleView: TriangleView!
    let triangleSize: CGFloat = 10
    let txtHeight: CGFloat = 22
    var color: UIColor = UIColor(red: 86 / 255.0, green: 131 / 255.0, blue: 239 / 255.0, alpha: 1.0)
    
    override init!(annotation: MAAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        setupLabel()
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
        titleLabel.backgroundColor = color
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.shadowColor = UIColor(white: 0.0, alpha: 0.75)
        titleLabel.shadowOffset = CGSize(width: 0, height: -1)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        titleLabel.baselineAdjustment = .alignCenters
        titleLabel.layer.cornerRadius = 10.0
        titleLabel.clipsToBounds = true
        
//        triangleView = TriangleView.init(frame: CGRect(x: 0, y: 0, width: triangleSize, height: triangleSize / 2))
        addSubview(titleLabel)
//        if #available(iOS 9.0, *) {
//            stackView = UIStackView.init(arrangedSubviews: [titleLabel])
////            let textRect = CGRect(x: 0, y: 0, width: 70, height: 30)
////            let annoRect = CGRect(x: 0, y: 0, width: 80, height: 80)
////            frame = CenterRect(annoRect, center)
////            stackView.frame = CenterRect(textRect, RectCenter(annoRect))
//            stackView.axis = .vertical
//            stackView.alignment = .center
//            stackView.distribution = .equalCentering
//            stackView.backgroundColor = .brown
//            addSubview(stackView)
//        } else {
//            // Fallback on earlier versions
//        }
    }
    
    func setLabel(title: String, labelColor: UIColor? = nil) {
        titleLabel.text = title
        let txtWidth = title.width(withConstrainedHeight: 120, font: titleLabel.font) + 20
        triangleView = TriangleView.init(frame: CGRect(x: txtWidth / 2 - triangleSize / 2, y: txtHeight, width: triangleSize, height: triangleSize / 2))
        let labelRect = CGRect(x: 0, y: 0, width: txtWidth, height: txtHeight)
        titleLabel.frame = labelRect
        addSubview(triangleView!)
        let annoHeight: CGFloat = txtHeight + triangleSize / 2
        let annoRect = CGRect(x: 0 - txtWidth / 2, y: 0 - annoHeight, width: txtWidth, height: annoHeight)
        frame = annoRect
        
        if let labelColor = labelColor {
            titleLabel.backgroundColor = labelColor
            triangleView?.setColor(color: labelColor)
        }
        
        setNeedsDisplay()
    }
    
    func setLabelColor(_ labelColor: UIColor?) {
        if let labelColor = labelColor {
            titleLabel.backgroundColor = labelColor
            triangleView?.setColor(color: labelColor)
        }
        setNeedsDisplay()
    }
    
    func resetColor() {
        titleLabel.backgroundColor = color
        triangleView?.resetColor()
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
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        context?.setAllowsAntialiasing(true)

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
    }
}

//
//  StatisticAnnotationView.swift
//  xhamap
//
//  Created by xionghao on 2020/11/6.
//

@available(iOS 9.0, *)
class StatisticAnnotationView : MAAnnotationView {
    var countLabel: UILabel!
    var titleLabel: UILabel!
    var stackView: UIStackView!
    var count: Int = 0
    var bgColor: UIColor!
    
    private let ScaleFactorAlpha: Float = 0.3
    private let ScaleFactorBeta: Float = 0.4
    
    override init!(annotation: MAAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        bgColor = UIColor(red: 86 / 255.0, green: 131 / 255.0, blue: 239 / 255.0, alpha: 1.0)
        initalView()
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

    // 根据count计算annotation的scale.
    func ScaledValueForValue(_ value: Int) -> Float {
        return 1.0 / (1.0 + expf(-1 * ScaleFactorAlpha * powf(Float(value), ScaleFactorBeta)))
    }
    
//    private func setupLabel() {
//        countLabel = UILabel(frame: frame)
//        countLabel.backgroundColor = UIColor.clear
//        countLabel.textColor = UIColor.white
//        countLabel.textAlignment = .center
//        countLabel.shadowColor = UIColor(white: 0.0, alpha: 0.75)
//        countLabel.shadowOffset = CGSize(width: 0, height: -1)
//        countLabel.adjustsFontSizeToFitWidth = true
//        countLabel.numberOfLines = 2
//        countLabel.font = UIFont.boldSystemFont(ofSize: 12)
//        countLabel.baselineAdjustment = .alignCenters
//        addSubview(countLabel)
//    }
    
    private func initalView() {
        countLabel = UILabel()
        countLabel.backgroundColor = UIColor.clear
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.shadowColor = UIColor(white: 0.0, alpha: 0.75)
        countLabel.shadowOffset = CGSize(width: 0, height: -1)
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.numberOfLines = 1
        countLabel.font = UIFont.boldSystemFont(ofSize: 12)
        countLabel.baselineAdjustment = .alignCenters
        
        titleLabel = UILabel()
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.shadowColor = UIColor(white: 0.0, alpha: 0.75)
        titleLabel.shadowOffset = CGSize(width: 0, height: -1)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        titleLabel.baselineAdjustment = .alignCenters
        
        let annoRect = CGRect(x: 0, y: 0, width: 80, height: 80)
        frame = CenterRect(annoRect, center)
        let txt_x: CGFloat = (80 - 70) / 2
        let txt_top: CGFloat = (80 - 30) / 2 + 5
        
        titleLabel.frame = CGRect(x: txt_x, y: txt_top, width: 70, height: 15)
        countLabel.frame = CGRect(x: txt_x, y: txt_top + 15, width: 70, height: 15)
        
        addSubview(countLabel)
        addSubview(titleLabel)
        
//        if #available(iOS 9.0, *) {
//            stackView = UIStackView.init(arrangedSubviews: [titleLabel, countLabel])
//            let textRect = CGRect(x: 0, y: 0, width: 70, height: 30)
//            let annoRect = CGRect(x: 0, y: 0, width: 80, height: 80)
////            let newCenter: CGPoint = CGPoint(x: center.x, y: center.y + frame.height / 2)
//            frame = CenterRect(annoRect, center)
//            stackView.frame = CenterRect(textRect, RectCenter(annoRect))
//            stackView.axis = .vertical
//            stackView.alignment = .center
//            stackView.distribution = .equalCentering
//            stackView.backgroundColor = .clear
//            addSubview(stackView)
//        } else {
//            // Fallback on earlier versions
//        }
    }
    
    func setLabel(title: String, count: Int) {
        countLabel.text = "\(count)"
        titleLabel.text = title
        
        setNeedsDisplay()
    }
    
    func setColor(color: UIColor) {
        bgColor = color
        setNeedsDisplay()
    }
    
    func resetColor() {
        bgColor = UIColor(red: 86 / 255.0, green: 131 / 255.0, blue: 239 / 255.0, alpha: 1.0)
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

        let outerCircleStrokeColor = UIColor(white: 0, alpha: 0.25)
        let innerCircleStrokeColor = UIColor.white
        let innerCircleFillColor = bgColor

        let circleFrame = rect.insetBy(dx: 4, dy: 4)

        outerCircleStrokeColor.setStroke()
        context?.setLineWidth(5.0)
        context?.strokeEllipse(in: circleFrame)

        innerCircleStrokeColor.setStroke()
        context?.setLineWidth(4)
        context?.strokeEllipse(in: circleFrame)

        innerCircleFillColor?.setFill()
        context?.fillEllipse(in: circleFrame)
    }
    
}

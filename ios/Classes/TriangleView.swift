//
//  TriangleView.swift
//  xhamap
//
//  Created by xionghao on 2020/11/7.
//

class TriangleView : UIView {
    
    private var pointOne: CGPoint!
    private var pointTwo: CGPoint!
    private var pointThr: CGPoint!
    private var fillColor: UIColor!
    
    override init(frame: CGRect) {
        pointOne = CGPoint(x: 0, y: 0)
        pointTwo = CGPoint(x: frame.width / 2, y: frame.height)
        pointThr = CGPoint(x: frame.width, y: 0)
        fillColor = UIColor(red: 86 / 255.0, green: 131 / 255.0, blue: 239 / 255.0, alpha: 1.0)
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
//        // 设置背景色
//        UIColor.white.set()

        //拿到当前视图准备好的画板
        let context = UIGraphicsGetCurrentContext()

        //利用path进行绘制三角形
        context?.beginPath() //标记

        context?.move(to: CGPoint(x: pointOne.x, y: pointOne.y)) //设置起点

        context?.addLine(to: CGPoint(x: pointTwo.x, y: pointTwo.y))

        context?.addLine(to: CGPoint(x: pointThr.x, y: pointThr.y))

        context?.closePath() //路径结束标志，不写默认封闭

        fillColor.setFill() //设置填充色

        fillColor.setStroke() //设置边框颜色

        context?.drawPath(
            using: .fillStroke) //绘制路径path
    }
}

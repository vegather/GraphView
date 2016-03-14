//
//  MOONGraphView.swift
//  iOS Example
//
//  Created by Vegard Solheim Theriault on 28/02/16.
//  Copyright © 2016 MOON Wearables. All rights reserved.
//
//     .___  ___.   ______     ______   .__   __.
//     |   \/   |  /  __  \   /  __  \  |  \ |  |
//     |  \  /  | |  |  |  | |  |  |  | |   \|  |
//     |  |\/|  | |  |  |  | |  |  |  | |  . `  |
//     |  |  |  | |  `--'  | |  `--'  | |  |\   |
//     |__|  |__|  \______/   \______/  |__| \__|
//      ___  _____   _____ _    ___  ___ ___ ___
//     |   \| __\ \ / / __| |  / _ \| _ \ __| _ \
//     | |) | _| \ V /| _|| |_| (_) |  _/ _||   /
//     |___/|___| \_/ |___|____\___/|_| |___|_|_\
//


import UIKit

enum GraphColor {
    case Gray
    case Orange
    case Green
    case Blue
    case Turquoise
    case Yellow
    case Purple
    
    private func colors() -> [CGColorRef] {
        switch self {
        case Gray:
            return [UIColor(red: 210.0/255.0, green: 209.0/255.0, blue: 215.0/255.0, alpha: 1.0).CGColor,
                    UIColor(red: 141.0/255.0, green: 140.0/255.0, blue: 146.0/255.0, alpha: 1.0).CGColor]
        case .Orange:
            return [UIColor(red: 255.0/255.0, green: 148.0/255.0, blue:  86.0/255.0, alpha: 1.0).CGColor,
                    UIColor(red: 253.0/255.0, green:  58.0/255.0, blue:  52.0/255.0, alpha: 1.0).CGColor]
        case .Green:
            return [UIColor(red:  78.0/255.0, green: 238.0/255.0, blue:  92.0/255.0, alpha: 1.0).CGColor,
                    UIColor(red:  28.0/255.0, green: 180.0/255.0, blue:  28.0/255.0, alpha: 1.0).CGColor]
        case .Blue:
            return [UIColor(red:  90.0/255.0, green: 202.0/255.0, blue: 251.0/255.0, alpha: 1.0).CGColor,
                    UIColor(red:   0.0/255.0, green: 108.0/255.0, blue: 250.0/255.0, alpha: 1.0).CGColor]
        case .Turquoise:
            return [UIColor(red:  82.0/255.0, green: 234.0/255.0, blue: 208.0/255.0, alpha: 1.0).CGColor,
                    UIColor(red:  54.0/255.0, green: 174.0/255.0, blue: 220.0/255.0, alpha: 1.0).CGColor]
        case .Yellow:
            return [UIColor(red: 254.0/255.0, green: 209.0/255.0, blue:  48.0/255.0, alpha: 1.0).CGColor,
                    UIColor(red: 255.0/255.0, green: 160.0/255.0, blue:  33.0/255.0, alpha: 1.0).CGColor]
        case .Purple:
            return [UIColor(red: 217.0/255.0, green: 168.0/255.0, blue: 252.0/255.0, alpha: 1.0).CGColor,
                    UIColor(red: 140.0/255.0, green:  70.0/255.0, blue: 250.0/255.0, alpha: 1.0).CGColor]
        }
    }
}

enum GraphDirection {
    case LeftToRight
    case RightToLeft
}

private struct Constants {
    static let FontName = "HelveticaNeue"
    static let ValueLabelWidth: CGFloat = 70.0
    static let TickMargin     : CGFloat = 15.0
    static let TickWidth      : CGFloat = 10.0
    static let Alpha          : CGFloat = 0.6
    static let CornerRadius   : CGFloat = 10.0
    static let GraphWidth     : CGFloat = 2.0
}

class MOONGraphView: UIView {

    private let gradientBackground = CAGradientLayer()
    private var lineView: LineView!
    private var accessoryView: AccessoryView!
    
    
    // -------------------------------
    // MARK: Initialization
    // -------------------------------
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        gradientBackground.frame = layer.bounds
        gradientBackground.colors = themeColor.colors()
        gradientBackground.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        layer.addSublayer(gradientBackground)
        
        accessoryView = AccessoryView(frame: bounds)
        accessoryView.layer.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        accessoryView.title = title
        accessoryView.subTitle = subTitle
        accessoryView.maxValue = maxValue
        accessoryView.minValue = minValue
        accessoryView.graphDirection = graphDirection
        addSubview(accessoryView)
        
        lineView = LineView(frame: bounds)
        lineView.layer.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        lineView.maxSamples = maxSamples
        lineView.maxValue = maxValue
        lineView.minValue = minValue
        lineView.graphDirection = graphDirection
        lineView.numberOfGraphs = numberOfGraphs
        addSubview(lineView)
    }
    
    
    
    
    // -------------------------------
    // MARK: Public API
    // -------------------------------
    
    /// Used to set the title of the graph in one of the upper corners. The default value for this is `""`, meaning that it will not be displayed.
    var title: String = "" {
        didSet {
            accessoryView.title = title
        }
    }
    
    /// Used to set a subtitle that will go right underneath the title. The default value for this is `""`, and will thus not be displayed.
    var subTitle: String = "" {
        didSet {
            accessoryView.subTitle = subTitle
        }
    }
    
    /// Specifies which way the graph will go. This is an enum with two possible options: `.LeftToRight`, and `.RightToLeft`. Setting this will also change which corner the title and subtitle will get drawn in (upper left corner for `.RightToLeft`, and vice versa). It also changes which side the values for the y-axis gets drawn (right side for `.RightToLeft`, and vice versa). The default is `.RightToLeft`.
    var graphDirection = GraphDirection.RightToLeft {
        didSet {
            accessoryView.graphDirection = graphDirection
            lineView.graphDirection = graphDirection
        }
    }
    
    /// This will set the background gradient of the graph. It's an enum with seven colors to pick from: `.Gray`, `.Orange`, `.Green`, `.Blue`, `.Turquoise`, `.Yellow`, and `.Purple`. The default is `.Orange`.
    var themeColor = GraphColor.Orange {
        didSet {
            gradientBackground.colors = themeColor.colors()
        }
    }
    
    /// This sets how many samples will fit within the view. E.g., if you set this to 200, what you will see in the view is the last 200 samples. You can't set it to any lower than 2 (for obvious reasons). The default value of this is 150.
    var maxSamples = 150  {
        didSet {
            lineView.maxSamples = max(2, maxSamples)
        }
    }
    
    /// Determines what the maximum expected value is. It is used as an upper limit for the view. The default is 1.0.
    var maxValue: CGFloat = 1.0 {
        didSet {
            accessoryView.maxValue = maxValue
            lineView.maxValue = maxValue
        }
    }
    
    /// Determines what the minimum expected value is. It is used as an lower limit for the view. The default is -1.0.
    var minValue: CGFloat = -1.0 {
        didSet {
            accessoryView.minValue = minValue
            lineView.minValue = minValue
        }
    }
    
    /// If you want your view to draw more than one graph at the same time (say x, y, z values of an accelerometer), you can specify that using this property. Notice that the `addSamples` method takes an argument of type `Double...` (called a variadic parameter). Whatever value you set for the `numberOfGraphs` property, you need to pass in the same number of arguments to this method, otherwise it will do nothing. If you change this property, all the samples you've added so far will be removed. The default is 1, meaning the `addSamples` method takes 1 argument.
    var numberOfGraphs = 1 {
        didSet {
            lineView.numberOfGraphs = max(1, numberOfGraphs)
        }
    }
    
    /// Use this to make the corners rounded or square. The default is true, meaning rounded corners.
    var roundedCorners = true {
        didSet {
            gradientBackground.cornerRadius  = roundedCorners ? Constants.CornerRadius : 0.0
            lineView.layer.cornerRadius      = roundedCorners ? Constants.CornerRadius : 0.0
            accessoryView.layer.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        }
    }
    
    /// This method is where you add your data to the graph. The value of the samples you add should be within the range `[minValue, maxValue]`, otherwise the graph will draw outside the view. Notice that this takes `Double...` as an argument (called a variadic parameter), which means that you can pass it one or more `Double` values as arguments. This is so that you can draw multiple graphs in the same view at the same time (say x, y, z data from an accelerometer). The number of arguments you pass needs to correspond to the `numberOfGraphs` property, otherwise this method will do nothing.
    func addSamples(newSamples: Double...) {
        lineView.addSamples(newSamples)
    }
    
    /// Removes all the samples you've added to the graph. All the other properties like `roundedCorners` and `maxSamples` etc are kept the same. Useful if you want to reuse the same graph view.
    func reset() {
        lineView.reset()
    }
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        gradientBackground.frame = self.layer.bounds
        accessoryView.frame = self.layer.bounds
        lineView.frame = self.layer.bounds
        
        gradientBackground.setNeedsDisplay()
        accessoryView.setNeedsDisplay()
        lineView.setNeedsDisplay()
        
        gradientBackground.removeAllAnimations()
    }

}




private class LineView: UIView {
    private var sampleArrays = [[Double]]()
    
    var maxSamples = 0                              { didSet { setNeedsDisplay() } }
    var maxValue: CGFloat = 0.0                     { didSet { setNeedsDisplay() } }
    var minValue: CGFloat = 0.0                     { didSet { setNeedsDisplay() } }
    var graphDirection = GraphDirection.LeftToRight { didSet { setNeedsDisplay() } }
    var numberOfGraphs = 1 {
        didSet {
            sampleArrays = [[Double]](count: numberOfGraphs, repeatedValue: [Double]())
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        opaque = false
        backgroundColor = UIColor.clearColor()
        layer.drawsAsynchronously = true
    }
    
    func addSamples(newSamples: [Double]) {
        guard newSamples.count == sampleArrays.count else { return }
        
        for (index, samples) in sampleArrays.enumerate() {
            if samples.count == maxSamples {
                sampleArrays[index].removeFirst()
            }
            
            sampleArrays[index].append(newSamples[index])
        }
        
        setNeedsDisplay()
    }
    
    func reset() {
        sampleArrays = [[Double]()]
        setNeedsDisplay()
    }
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    private override func drawRect(rect: CGRect) {
        UIColor(white: 1.0, alpha: Constants.Alpha).setStroke()
        drawGraph()
    }
    
    private func drawGraph() {
        let widthPerSample = (bounds.width - Constants.ValueLabelWidth) / CGFloat(maxSamples - 1)
        let pointsToSampleValueRatio = (bounds.height - Constants.TickMargin * 2) / (maxValue - minValue)
        
        let progress = CGFloat(sampleArrays[0].count) / CGFloat(maxSamples)
        let window = bounds.width - Constants.ValueLabelWidth
        
        for samples in sampleArrays {
            var currentXValue: CGFloat
            switch graphDirection {
                case .RightToLeft: currentXValue = (progress - 1.0) * -1.0 * window
                case .LeftToRight: currentXValue = progress * window + Constants.ValueLabelWidth
            }
            
            let path = UIBezierPath()
            
            for (index, sample) in samples.enumerate() {
                let y: CGFloat = (maxValue - CGFloat(sample)) * pointsToSampleValueRatio + Constants.TickMargin
                
                let point = CGPoint(x: currentXValue, y: y)
                
                if index == 0 { path.moveToPoint(point) }
                else { path.addLineToPoint(point) }
                
                switch graphDirection {
                    case .RightToLeft: currentXValue += widthPerSample
                    case .LeftToRight: currentXValue -= widthPerSample
                }
            }
            
            path.lineWidth = Constants.GraphWidth
            path.stroke()
        }
    }
}

private class AccessoryView: UIView {
    
    var title = ""                                  { didSet { setNeedsDisplay() } }
    var subTitle = ""                               { didSet { setNeedsDisplay() } }
    var maxValue: CGFloat = 0.0                     { didSet { setNeedsDisplay() } }
    var minValue: CGFloat = 0.0                     { didSet { setNeedsDisplay() } }
    var graphDirection = GraphDirection.LeftToRight { didSet { setNeedsDisplay() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        opaque = false
        backgroundColor = UIColor.clearColor()
    }
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    private override func drawRect(rect: CGRect) {
        UIColor(white: 1.0, alpha: Constants.Alpha).setStroke()
        
//        drawValueLabelsFill()
        drawSeparatorLine()
        drawTicks()
        drawValueLabels()
        drawInformationLabels()
    }
    
    /// Draws a lighter background for the label values.
    private func drawValueLabelsFill() {
        let fill = UIBezierPath()
        
        switch graphDirection {
        case .RightToLeft:
            fill.moveToPoint(CGPoint(x: bounds.width - Constants.ValueLabelWidth, y: 0.0))
            fill.addLineToPoint(CGPoint(x: bounds.width, y: 0.0))
            fill.addLineToPoint(CGPoint(x: bounds.width, y: bounds.height))
            fill.addLineToPoint(CGPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height))
        case .LeftToRight:
            fill.moveToPoint(CGPoint(x: 0.0, y: 0.0))
            fill.addLineToPoint(CGPoint(x: Constants.ValueLabelWidth, y: 0.0))
            fill.addLineToPoint(CGPoint(x: Constants.ValueLabelWidth, y: bounds.height))
            fill.addLineToPoint(CGPoint(x: 0.0, y: bounds.height))
        }
        
        UIColor(white: 1.0, alpha: 0.2).setFill()
        fill.fill()
    }
    
    /// Draws the vertical line between the graph and the value labels.
    private func drawSeparatorLine() {
        let separatorLine = UIBezierPath()
        
        switch graphDirection {
        case .RightToLeft:
            separatorLine.moveToPoint(CGPoint(x: bounds.width - Constants.ValueLabelWidth, y: 0.0))
            separatorLine.addLineToPoint(CGPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height))
        case .LeftToRight:
            separatorLine.moveToPoint(CGPoint(x: Constants.ValueLabelWidth, y: 0.0))
            separatorLine.addLineToPoint(CGPoint(x: Constants.ValueLabelWidth, y: bounds.height))
        }
        
        UIColor(white: 1.0, alpha: Constants.Alpha).setStroke()
        separatorLine.lineWidth = 1.0
        separatorLine.stroke()
    }
    
    /// Draws the three tiny tick marks for the value labels
    private func drawTicks() {
        let tick1 = UIBezierPath()
        let tick2 = UIBezierPath()
        let tick3 = UIBezierPath()
        
        switch graphDirection {
        case .RightToLeft:
            tick1.moveToPoint(   CGPoint(x: bounds.width - Constants.ValueLabelWidth, y: Constants.TickMargin))
            tick1.addLineToPoint(CGPoint(x: bounds.width - Constants.ValueLabelWidth + Constants.TickWidth, y: Constants.TickMargin))
            
            tick2.moveToPoint(   CGPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height / 2.0))
            tick2.addLineToPoint(CGPoint(x: bounds.width - Constants.ValueLabelWidth + Constants.TickWidth / 2.0, y: bounds.height / 2.0))
            
            tick3.moveToPoint(   CGPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height - Constants.TickMargin))
            tick3.addLineToPoint(CGPoint(x: bounds.width - Constants.ValueLabelWidth + Constants.TickWidth, y: bounds.height - Constants.TickMargin))
        case .LeftToRight:
            tick1.moveToPoint(   CGPoint(x: Constants.ValueLabelWidth,                       y: Constants.TickMargin))
            tick1.addLineToPoint(CGPoint(x: Constants.ValueLabelWidth - Constants.TickWidth, y: Constants.TickMargin))
            
            tick2.moveToPoint(   CGPoint(x: Constants.ValueLabelWidth,                             y: bounds.height / 2.0))
            tick2.addLineToPoint(CGPoint(x: Constants.ValueLabelWidth - Constants.TickWidth / 2.0, y: bounds.height / 2.0))
            
            tick3.moveToPoint(   CGPoint(x: Constants.ValueLabelWidth,                       y: bounds.height - Constants.TickMargin))
            tick3.addLineToPoint(CGPoint(x: Constants.ValueLabelWidth - Constants.TickWidth, y: bounds.height - Constants.TickMargin))
        }
        
        UIColor(white: 1.0, alpha: Constants.Alpha).setStroke()
        tick1.lineWidth = 1.0
        tick2.lineWidth = 1.0
        tick3.lineWidth = 1.0
        tick1.stroke()
        tick2.stroke()
        tick3.stroke()
    }
    
    /// Draws the value labels
    private func drawValueLabels() {
        let attributes = [
            NSFontAttributeName           : UIFont(name: Constants.FontName, size: 15)!,
            NSForegroundColorAttributeName: UIColor(white: 1.0, alpha: 0.8)
            ] as Dictionary<String, AnyObject>
        
        let label1 = NSAttributedString(string: String(format: "%.2f", arguments: [maxValue]), attributes: attributes)
        let label2 = NSAttributedString(string: String(format: "%.2f", arguments: [(maxValue-minValue)/2.0 + minValue]), attributes: attributes)
        let label3 = NSAttributedString(string: String(format: "%.2f", arguments: [minValue]), attributes: attributes)
        
        let alignmentCoefficient: CGFloat = -1.0
        
        switch graphDirection {
        case .RightToLeft:
            let x = bounds.width - Constants.ValueLabelWidth + Constants.TickWidth + 5.0
            label1.drawInRect(CGRect(
                x       : x,
                y       : Constants.TickMargin - (label1.size().height / 2.0) + alignmentCoefficient,
                width   : label1.size().width,
                height  : label1.size().height)
            )
            label2.drawInRect(CGRect(
                x       : x,
                y:      bounds.height / 2.0 - (label2.size().height / 2.0) + alignmentCoefficient,
                width   : label2.size().width,
                height  : label2.size().height)
            )
            label3.drawInRect(CGRect(
                x       : x,
                y       : bounds.height - Constants.TickMargin - (label3.size().height / 2.0) + alignmentCoefficient,
                width   : label3.size().width,
                height  : label3.size().height)
            )
        case .LeftToRight:
            let x = Constants.ValueLabelWidth - Constants.TickWidth - 5.0
            label1.drawInRect(CGRect(
                x       : x - label1.size().width,
                y       : Constants.TickMargin - (label1.size().height / 2.0) + alignmentCoefficient,
                width   : label1.size().width,
                height  : label1.size().height)
            )
            label2.drawInRect(CGRect(
                x       : x - label2.size().width,
                y       : bounds.height / 2.0 - (label2.size().height / 2.0) + alignmentCoefficient,
                width   : label2.size().width,
                height  : label2.size().height)
            )
            label3.drawInRect(CGRect(
                x       : x - label3.size().width,
                y       : bounds.height - Constants.TickMargin - (label3.size().height / 2.0) + alignmentCoefficient,
                width   : label3.size().width,
                height  : label3.size().height)
            )
        }
    }
    
    /// Draws the title label and the subtitle label
    private func drawInformationLabels() {
        let titleAttributes    = [
            NSFontAttributeName           : UIFont(name: Constants.FontName, size: 30)!,
            NSForegroundColorAttributeName: UIColor.whiteColor()
            ] as Dictionary<String, AnyObject>
        
        let subTitleAttributes = [
            NSFontAttributeName           : UIFont(name: Constants.FontName, size: 20)!,
            NSForegroundColorAttributeName: UIColor(white: 1.0, alpha: Constants.Alpha)
            ] as Dictionary<String, AnyObject>
        
        let titleLabel    = NSAttributedString(string: title, attributes: titleAttributes)
        let subTitleLabel = NSAttributedString(string: subTitle, attributes: subTitleAttributes)
        
        let horizontalMargin   : CGFloat = 20.0
        let verticalMargin     : CGFloat = 30.0
        
        let titleY = horizontalMargin
        let subTitleY = horizontalMargin + titleLabel.size().height
        
        switch graphDirection {
        case .RightToLeft:
            titleLabel   .drawInRect(CGRect(
                x       : verticalMargin,
                y       : titleY,
                width   : titleLabel.size().width,
                height  : titleLabel.size().height)
            )
            subTitleLabel.drawInRect(CGRect(
                x       : verticalMargin,
                y       : subTitleY,
                width   : subTitleLabel.size().width,
                height  : subTitleLabel.size().height))
        case .LeftToRight:
            let x = bounds.width - verticalMargin - max(titleLabel.size().width, subTitleLabel.size().width)
            titleLabel   .drawInRect(CGRect(
                x       : x,
                y       : titleY,
                width   : titleLabel.size().width,
                height  : titleLabel.size().height)
            )
            subTitleLabel.drawInRect(CGRect(
                x       : x,
                y       : subTitleY,
                width   : subTitleLabel.size().width,
                height  : subTitleLabel.size().height)
            )
        }
    }

}

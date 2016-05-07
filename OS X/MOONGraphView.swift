//
//  GraphView.swift
//  OS X Example
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


import Cocoa

private struct Constants {
    static let FontName = "HelveticaNeue"
    static let ValueLabelWidth    : CGFloat = 70.0
    static let TickMargin         : CGFloat = 15.0
    static let TickWidth          : CGFloat = 10.0
    static let Alpha              : CGFloat = 0.6
    static let CornerRadius       : CGFloat = 10.0
    static let GraphWidth         : CGFloat = 2.0
    static let ScatterPointRadius : CGFloat = 4.0
}


@IBDesignable
public class MOONGraphView: NSView {
    
    public enum GraphColor {
        case Gray
        case Red
        case Green
        case Blue
        case Turquoise
        case Yellow
        case Purple
        
        private func colors() -> [CGColorRef] {
            switch self {
            case Gray:
                return [NSColor(red: 141.0/255.0, green: 140.0/255.0, blue: 146.0/255.0, alpha: 1.0).CGColor,
                        NSColor(red: 210.0/255.0, green: 209.0/255.0, blue: 215.0/255.0, alpha: 1.0).CGColor]
            case .Red:
                return [NSColor(red: 253.0/255.0, green:  58.0/255.0, blue: 52.0/255.0,  alpha: 1.0).CGColor,
                        NSColor(red: 255.0/255.0, green: 148.0/255.0, blue: 86.0/255.0,  alpha: 1.0).CGColor]
            case .Green:
                return [NSColor(red: 28.0/255.0,  green: 180.0/255.0, blue: 28.0/255.0,  alpha: 1.0).CGColor,
                        NSColor(red: 78.0/255.0,  green: 238.0/255.0, blue: 92.0/255.0,  alpha: 1.0).CGColor]
            case .Blue:
                return [NSColor(red:  0.0/255.0,  green: 108.0/255.0, blue: 250.0/255.0, alpha: 1.0).CGColor,
                        NSColor(red: 90.0/255.0,  green: 202.0/255.0, blue: 251.0/255.0, alpha: 1.0).CGColor]
            case .Turquoise:
                return [NSColor(red: 54.0/255.0,  green: 174.0/255.0, blue: 220.0/255.0, alpha: 1.0).CGColor,
                        NSColor(red: 82.0/255.0,  green: 234.0/255.0, blue: 208.0/255.0, alpha: 1.0).CGColor]
            case .Yellow:
                return [NSColor(red: 255.0/255.0, green: 160.0/255.0, blue: 33.0/255.0,  alpha: 1.0).CGColor,
                        NSColor(red: 254.0/255.0, green: 209.0/255.0, blue: 48.0/255.0,  alpha: 1.0).CGColor]
            case .Purple:
                return [NSColor(red: 140.0/255.0, green:  70.0/255.0, blue: 250.0/255.0, alpha: 1.0).CGColor,
                        NSColor(red: 217.0/255.0, green: 168.0/255.0, blue: 252.0/255.0, alpha: 1.0).CGColor]
            }
        }
    }
    
    public enum GraphDirection {
        case LeftToRight
        case RightToLeft
    }
    
    public enum GraphType {
        case Line
        case Scatter
    }
    
    
    
    private let gradientBackground = CAGradientLayer()
    private var lineView: LineView?
    private var accessoryView: AccessoryView?
    
    
    
    
    // -------------------------------
    // MARK: Initialization
    // -------------------------------
    
    override public func awakeFromNib() {
        super.awakeFromNib()

        addSubviews()
    }
    
    private func addSubviews() {
        wantsLayer = true
        guard let layer = layer else { return }
        
        NSBezierPath.setDefaultLineWidth(Constants.GraphWidth)
        
        gradientBackground.frame = layer.bounds
        gradientBackground.colors = themeColor.colors()
        gradientBackground.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        gradientBackground.removeAllAnimations()
        layer.addSublayer(gradientBackground)
        
        lineView = LineView(frame: bounds)
        lineView!.maxSamples = maxSamples
        lineView!.maxValue = maxValue
        lineView!.minValue = minValue
        lineView!.graphDirection = graphDirection
        lineView!.numberOfGraphs = numberOfGraphs
        lineView!.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        lineView!.graphType = graphType
        addSubview(lineView!)
        
        accessoryView = AccessoryView(frame: bounds)
        accessoryView!.title = title
        accessoryView!.subtitle = subtitle
        accessoryView!.maxValue = maxValue
        accessoryView!.minValue = minValue
        accessoryView!.graphDirection = graphDirection
        addSubview(accessoryView!)
    }
    
    
    
    
    // -------------------------------
    // MARK: Public API
    // -------------------------------
    
    /// Used to set the title of the graph in one of the upper corners. The default value for this is `""`, meaning that it will not be displayed.
    @IBInspectable public var title: String = "" {
        didSet {
            accessoryView?.title = title
        }
    }
    
    /// Used to set a subtitle that will go right underneath the title. The default value for this is `""`, and will thus not be displayed.
    @IBInspectable public var subtitle: String = "" {
        didSet {
            accessoryView?.subtitle = subtitle
        }
    }
    
    /// Specifies which way the graph will go. This is an enum with two possible options: `.LeftToRight`, and `.RightToLeft`. Setting this will also change which corner the title and subtitle will get drawn in (upper left corner for `.RightToLeft`, and vice versa). It also changes which side the values for the y-axis gets drawn (right side for `.RightToLeft`, and vice versa). The default is `.RightToLeft`.
    public var graphDirection = GraphDirection.RightToLeft {
        didSet {
            accessoryView?.graphDirection = graphDirection
            lineView?.graphDirection = graphDirection
        }
    }
    
    /// This will set the background gradient of the graph. It's an enum with seven colors to pick from: `.Gray`, `.Red`, `.Green`, `.Blue`, `.Turquoise`, `.Yellow`, and `.Purple`. The default is `.Red`.
    public var themeColor = GraphColor.Red {
        didSet {
            gradientBackground.colors = themeColor.colors()
        }
    }
    
    /// This sets how many samples will fit within the view. E.g., if you set this to 200, what you will see in the view is the last 200 samples. You can't set it to any lower than 2 (for obvious reasons). The default value of this is 150.
    public var maxSamples = 150  {
        didSet {
            lineView?.maxSamples = max(2, maxSamples)
        }
    }
    
    /// Determines what the maximum expected value is. It is used as an upper limit for the view. The default is 1.0.
    @IBInspectable public var maxValue: CGFloat = 1.0 {
        didSet {
            accessoryView?.maxValue = maxValue
            lineView?.maxValue = maxValue
        }
    }
    
    /// Determines what the minimum expected value is. It is used as an lower limit for the view. The default is -1.0.
    @IBInspectable public var minValue: CGFloat = -1.0 {
        didSet {
            accessoryView?.minValue = minValue
            lineView?.minValue = minValue
        }
    }
    
    /// If you want your view to draw more than one graph at the same time (say x, y, z values of an accelerometer), you can specify that using this property. Notice that the `addSamples` method takes an argument of type `Double...` (called a variadic parameter). Whatever value you set for the `numberOfGraphs` property, you need to pass in the same number of arguments to this method, otherwise it will do nothing. If you change this property, all the samples you've added so far will be removed. The default is 1, meaning the `addSamples` method takes 1 argument.
    public var numberOfGraphs = 1 {
        didSet {
            lineView?.numberOfGraphs = max(1, numberOfGraphs)
        }
    }
    
    /// Use this to make the corners rounded or square. The default is true, meaning rounded corners.
    @IBInspectable public var roundedCorners = true {
        didSet {
            gradientBackground.cornerRadius    = roundedCorners ? Constants.CornerRadius : 0.0
            lineView?.cornerRadius             = roundedCorners ? Constants.CornerRadius : 0.0
        }
    }
    
    /// Changes how the samples are drawn. The current options are .Line and .Scatter. The default is .Line
    public var graphType = GraphType.Line {
        didSet {
            lineView?.graphType = graphType
        }
    }
    
    /// This method is where you add your data to the graph. The value of the samples you add should be within the range `[minValue, maxValue]`, otherwise the graph will draw outside the view. Notice that this takes `Double...` as an argument (called a variadic parameter), which means that you can pass it one or more `Double` values as arguments. This is so that you can draw multiple graphs in the same view at the same time (say x, y, z data from an accelerometer). The number of arguments you pass needs to correspond to the `numberOfGraphs` property, otherwise this method will do nothing.
    public func addSamples(newSamples: Double...) {
        lineView?.addSamples(newSamples)
    }
    
    /// Removes all the samples you've added to the graph. All the other properties like `roundedCorners` and `maxSamples` etc are kept the same. Useful if you want to reuse the same graph view.
    public func reset() {
        lineView?.reset()
    }
    
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    override public func layoutSublayersOfLayer(layer: CALayer) {
        if let selfLayer = self.layer {
            gradientBackground.frame = selfLayer.bounds
            accessoryView?.frame = selfLayer.bounds
            lineView?.frame = selfLayer.bounds
        }
        
        gradientBackground.removeAllAnimations()
    }
    
    override public func prepareForInterfaceBuilder() {
        addSubviews()
        
        if title == "" { title = "Heading" }
        if subtitle == "" { subtitle = "Subtitle" }
        
        for i in 0..<maxSamples {
            addSamples(sin(Double(i) * 0.1))
        }
    }
    
}






private class LineView: NSView {
    
    private var sampleArrays = [[Double]]()
    
    
    // -------------------------------
    // MARK: Properties
    // -------------------------------
    
    var maxSamples = 0 {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var maxValue: CGFloat = 0.0 {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var minValue: CGFloat = 0.0 {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var cornerRadius = Constants.CornerRadius {
        didSet { layer?.cornerRadius = cornerRadius }
    }
    
    var graphType = MOONGraphView.GraphType.Line {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var graphDirection = MOONGraphView.GraphDirection.LeftToRight {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var numberOfGraphs = 1 {
        didSet {
            sampleArrays = [[Double]](count: numberOfGraphs, repeatedValue: [Double]())
            setNeedsDisplayInRect(bounds)
        }
    }
    
    
    
    // -------------------------------
    // MARK: Initialization
    // -------------------------------
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
    }
    
    
    
    // -------------------------------
    // MARK: Methods
    // -------------------------------
    
    func addSamples(newSamples: [Double]) {
        guard newSamples.count == sampleArrays.count else { return }
        
        for (index, samples) in sampleArrays.enumerate() {
            if samples.count == maxSamples {
                sampleArrays[index].removeFirst()
            }
            
            sampleArrays[index].append(newSamples[index])
        }
        
        setNeedsDisplayInRect(bounds)
    }
    
    func reset() {
        sampleArrays = [[Double]()]
        setNeedsDisplayInRect(bounds)
    }
    
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor(white: 1.0, alpha: Constants.Alpha).set() // Sets both stroke and fill
        drawGraph()
    }
    
    private func drawGraph() {
        let widthPerSample = (bounds.width - Constants.ValueLabelWidth) / CGFloat(maxSamples - 1)
        let pointsToSampleValueRatio = (bounds.height - Constants.TickMargin * 2) / (maxValue - minValue)
        
        let progress = CGFloat(sampleArrays[0].count - 1) / CGFloat(maxSamples)
        let window = bounds.width - Constants.ValueLabelWidth
        
        for samples in sampleArrays {
            var currentXValue: CGFloat
            switch graphDirection {
                case .RightToLeft: currentXValue = (progress - 1.0) * -1.0 * window
                case .LeftToRight: currentXValue = progress * window + Constants.ValueLabelWidth
            }
            
            for (index, sample) in samples.enumerate() {
                guard index > 0 else { continue } // Skip the first one
                
                let x1: CGFloat = currentXValue
                let y1: CGFloat = (CGFloat(sample) - minValue) * pointsToSampleValueRatio + Constants.TickMargin
                let point1 = NSPoint(x: x1, y: y1)
                
                switch graphType {
                    case .Line:
                        var x2 = currentXValue
                        switch graphDirection {
                            case .RightToLeft: x2 -= widthPerSample
                            case .LeftToRight: x2 += widthPerSample
                        }
                        
                        let y2: CGFloat = (CGFloat(samples[index - 1]) - minValue) * pointsToSampleValueRatio + Constants.TickMargin
                        let point2 = NSPoint(x: x2, y: y2)
                        
                        NSBezierPath.strokeLineFromPoint(point1, toPoint: point2)
                    
                    case .Scatter:
                        NSBezierPath(ovalInRect: NSRect(
                            x: x1 - Constants.ScatterPointRadius / 2.0,
                            y: y1 - Constants.ScatterPointRadius / 2.0,
                            width:  Constants.ScatterPointRadius,
                            height: Constants.ScatterPointRadius
                            )
                        ).fill()
                }
                
                switch graphDirection {
                    case .RightToLeft: currentXValue += widthPerSample
                    case .LeftToRight: currentXValue -= widthPerSample
                }
            }
        }
    }
        
        
}







private class AccessoryView: NSView {
    
    
    // -------------------------------
    // MARK: Properties
    // -------------------------------
    
    var title = "" {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var subtitle = "" {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var maxValue: CGFloat = 0.0 {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var minValue: CGFloat = 0.0 {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    var graphDirection = MOONGraphView.GraphDirection.LeftToRight {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    override func drawRect(dirtyRect: NSRect) {
//        drawValueLabelsFill() // Not yet sure if I prefer this on or off
        drawSeparatorLine()
        drawTicks()
        drawValueLabels()
        drawInformationLabels()
    }
    
    private func drawValueLabelsFill() {
        let fill = NSBezierPath()
        
        switch graphDirection {
        case .RightToLeft:
            fill.moveToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth, y: 0.0))
            fill.lineToPoint(NSPoint(x: bounds.width, y: 0.0))
            fill.lineToPoint(NSPoint(x: bounds.width, y: bounds.height))
            fill.lineToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height))
        case .LeftToRight:
            fill.moveToPoint(NSPoint(x: 0.0, y: 0.0))
            fill.lineToPoint(NSPoint(x: Constants.ValueLabelWidth, y: 0.0))
            fill.lineToPoint(NSPoint(x: Constants.ValueLabelWidth, y: bounds.height))
            fill.lineToPoint(NSPoint(x: 0.0, y: bounds.height))
        }
        
        NSColor(white: 1.0, alpha: 0.2).setFill()
        fill.fill()
    }
    
    private func drawSeparatorLine() {
        let separatorLine = NSBezierPath()
        
        switch graphDirection {
        case .RightToLeft:
            separatorLine.moveToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth, y: 0.0))
            separatorLine.lineToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height))
        case .LeftToRight:
            separatorLine.moveToPoint(NSPoint(x: Constants.ValueLabelWidth, y: 0.0))
            separatorLine.lineToPoint(NSPoint(x: Constants.ValueLabelWidth, y: bounds.height))
        }
        
        NSColor(white: 1.0, alpha: Constants.Alpha).setStroke()
        separatorLine.lineWidth = 1.0
        separatorLine.stroke()
    }
    
    private func drawTicks() {
        let tick1 = NSBezierPath()
        let tick2 = NSBezierPath()
        let tick3 = NSBezierPath()
        
        switch graphDirection {
        case .RightToLeft:
            tick1.moveToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth, y: Constants.TickMargin))
            tick1.lineToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth + Constants.TickWidth, y: Constants.TickMargin))
            
            tick2.moveToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height / 2.0))
            tick2.lineToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth + Constants.TickWidth / 2.0, y: bounds.height / 2.0))
            
            tick3.moveToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth, y: bounds.height - Constants.TickMargin))
            tick3.lineToPoint(NSPoint(x: bounds.width - Constants.ValueLabelWidth + Constants.TickWidth, y: bounds.height - Constants.TickMargin))
        case .LeftToRight:
            tick1.moveToPoint(NSPoint(x: Constants.ValueLabelWidth, y: Constants.TickMargin))
            tick1.lineToPoint(NSPoint(x: Constants.ValueLabelWidth - Constants.TickWidth, y: Constants.TickMargin))
            
            tick2.moveToPoint(NSPoint(x: Constants.ValueLabelWidth, y: bounds.height / 2.0))
            tick2.lineToPoint(NSPoint(x: Constants.ValueLabelWidth - Constants.TickWidth / 2.0, y: bounds.height / 2.0))
            
            tick3.moveToPoint(NSPoint(x: Constants.ValueLabelWidth, y: bounds.height - Constants.TickMargin))
            tick3.lineToPoint(NSPoint(x: Constants.ValueLabelWidth - Constants.TickWidth, y: bounds.height - Constants.TickMargin))
        }
        
        NSColor(white: 1.0, alpha: Constants.Alpha).setStroke()
        tick1.lineWidth = 1.0
        tick2.lineWidth = 1.0
        tick3.lineWidth = 1.0
        tick1.stroke()
        tick2.stroke()
        tick3.stroke()
    }
    
    private func drawValueLabels() {
        let attributes = [
            NSFontAttributeName           : NSFont(name: Constants.FontName, size: 15)!,
            NSForegroundColorAttributeName: NSColor(white: 1.0, alpha: 0.8)
        ] as Dictionary<String, AnyObject>
        
        let label1 = NSAttributedString(string: String(format: "%.2f", arguments: [minValue]), attributes: attributes)
        let label2 = NSAttributedString(string: String(format: "%.2f", arguments: [(maxValue-minValue)/2.0 + minValue]), attributes: attributes)
        let label3 = NSAttributedString(string: String(format: "%.2f", arguments: [maxValue]), attributes: attributes)
        
        let alignmentCoefficient: CGFloat = 2.0
        
        switch graphDirection {
        case .RightToLeft:
            let x = bounds.width - Constants.ValueLabelWidth + Constants.TickWidth + 5.0
            label1.drawInRect(NSRect(
                x       : x,
                y       : Constants.TickMargin - (label1.size().height / 2.0) + alignmentCoefficient,
                width   : label1.size().width,
                height  : label1.size().height)
            )
            label2.drawInRect(NSRect(
                x       : x,
                y:      bounds.height / 2.0 - (label2.size().height / 2.0) + alignmentCoefficient,
                width   : label2.size().width,
                height  : label2.size().height)
            )
            label3.drawInRect(NSRect(
                x       : x,
                y       : bounds.height - Constants.TickMargin - (label3.size().height / 2.0) + alignmentCoefficient,
                width   : label3.size().width,
                height  : label3.size().height)
            )
        case .LeftToRight:
            let x = Constants.ValueLabelWidth - Constants.TickWidth - 5.0
            label1.drawInRect(NSRect(
                x       : x - label1.size().width,
                y       : Constants.TickMargin - (label1.size().height / 2.0) + alignmentCoefficient,
                width   : label1.size().width,
                height  : label1.size().height)
            )
            label2.drawInRect(NSRect(
                x       : x - label2.size().width,
                y       : bounds.height / 2.0 - (label2.size().height / 2.0) + alignmentCoefficient,
                width   : label2.size().width,
                height  : label2.size().height)
            )
            label3.drawInRect(NSRect(
                x       : x - label3.size().width,
                y       : bounds.height - Constants.TickMargin - (label3.size().height / 2.0) + alignmentCoefficient,
                width   : label3.size().width,
                height  : label3.size().height)
            )
        }
    }
    
    private func drawInformationLabels() {
        let titleAttributes    = [
            NSFontAttributeName           : NSFont(name: Constants.FontName, size: 30)!,
            NSForegroundColorAttributeName: NSColor.whiteColor()
        ] as Dictionary<String, AnyObject>
        
        let subTitleAttributes = [
            NSFontAttributeName           : NSFont(name: Constants.FontName, size: 20)!,
            NSForegroundColorAttributeName: NSColor(white: 1.0, alpha: Constants.Alpha)
        ] as Dictionary<String, AnyObject>
        
        let titleLabel    = NSAttributedString(string: title, attributes: titleAttributes)
        let subTitleLabel = NSAttributedString(string: subtitle, attributes: subTitleAttributes)
        
        let horizontalMargin   : CGFloat = 20.0
        let verticalMargin     : CGFloat = 30.0
        
        let titleY = bounds.height - titleLabel.size().height - horizontalMargin
        let subTitleY = titleY - subTitleLabel.size().height
        
        switch graphDirection {
        case .RightToLeft:
            titleLabel   .drawInRect(NSRect(
                x       : verticalMargin,
                y       : titleY,
                width   : titleLabel.size().width,
                height  : titleLabel.size().height)
            )
            subTitleLabel.drawInRect(NSRect(
                x       : verticalMargin,
                y       : subTitleY,
                width   : subTitleLabel.size().width,
                height  : subTitleLabel.size().height))
        case .LeftToRight:
            let x = bounds.width - verticalMargin - max(titleLabel.size().width, subTitleLabel.size().width)
            titleLabel   .drawInRect(NSRect(
                x       : x,
                y       : titleY,
                width   : titleLabel.size().width,
                height  : titleLabel.size().height)
            )
            subTitleLabel.drawInRect(NSRect(
                x       : x,
                y       : subTitleY,
                width   : subTitleLabel.size().width,
                height  : subTitleLabel.size().height)
            )
        }
    }
    
}


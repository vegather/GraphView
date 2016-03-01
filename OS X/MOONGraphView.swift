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
            return [NSColor(red: 141.0/255.0, green: 140.0/255.0, blue: 146.0/255.0, alpha: 1.0).CGColor,
                    NSColor(red: 210.0/255.0, green: 209.0/255.0, blue: 215.0/255.0, alpha: 1.0).CGColor]
        case .Orange:
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

enum GraphDirection {
    case LeftToRight
    case RightToLeft
}

private struct Constants {
    static let FontName = "HelveticaNeue"
    static let GraphSeparatorLineMargin: CGFloat = 70.0
    static let TickMargin: CGFloat = 15.0
    static let TickWidth: CGFloat = 10.0
    static let Alpha: CGFloat = 0.6
    static let CornerRadius: CGFloat = 10.0
    static let GraphWidth: CGFloat = 2.0
}




class GraphView: NSView {
    
    private let gradientBackground = CAGradientLayer()
    private var lineView: LineView!
    private var accessoryView: AccessoryView!
    
    
    // -------------------------------
    // MARK: Initialization
    // -------------------------------
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        wantsLayer = true
        
        guard let layer = layer else { return }
        
        NSBezierPath.setDefaultLineWidth(Constants.GraphWidth)
        
        gradientBackground.frame = layer.bounds
        gradientBackground.colors = themeColor.colors()
        gradientBackground.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        gradientBackground.removeAllAnimations()
        layer.addSublayer(gradientBackground)
        
        accessoryView = AccessoryView(frame: bounds)
        accessoryView.title = title
        accessoryView.subTitle = subTitle
        accessoryView.maxValue = maxValue
        accessoryView.minValue = minValue
        accessoryView.graphDirection = graphDirection
        accessoryView.layer?.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        addSubview(accessoryView)
        
        lineView = LineView(frame: bounds)
        lineView.maxSamples = maxSamples
        lineView.maxValue = maxValue
        lineView.minValue = minValue
        lineView.graphDirection = graphDirection
        lineView.numberOfGraphs = numberOfGraphs
        lineView.layer?.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        addSubview(lineView)
    }
    
    
    
    
    // -------------------------------
    // MARK: Public API
    // -------------------------------
    
    var title: String = "" {
        didSet {
            accessoryView?.title = title
        }
    }
    var subTitle: String = "" {
        didSet {
            accessoryView?.subTitle = subTitle
        }
    }
    var graphDirection = GraphDirection.LeftToRight {
        didSet {
            accessoryView?.graphDirection = graphDirection
            lineView?.graphDirection = graphDirection
        }
    }
    var themeColor = GraphColor.Yellow {
        didSet {
            gradientBackground.colors = themeColor.colors()
        }
    }
    /// Can't be lower than 2.
    var maxSamples = 150  {
        didSet {
            lineView?.maxSamples = max(2, maxSamples)
        }
    }
    var maxValue: CGFloat = 1.0 {
        didSet {
            accessoryView?.maxValue = maxValue
            lineView?.maxValue = maxValue
        }
    }
    var minValue: CGFloat = -1.0 {
        didSet {
            accessoryView?.minValue = minValue
            lineView?.minValue = minValue
        }
    }
    /// Changing this will reset the graph(s). Can't be lower than 1
    var numberOfGraphs = 1 {
        didSet {
            lineView?.numberOfGraphs = max(1, numberOfGraphs)
        }
    }
    
    var roundedCorners = false {
        didSet {
            gradientBackground.cornerRadius    = roundedCorners ? Constants.CornerRadius : 0.0
            lineView.layer?.cornerRadius       = roundedCorners ? Constants.CornerRadius : 0.0
            accessoryView.layer?.cornerRadius  = roundedCorners ? Constants.CornerRadius : 0.0
        }
    }
    
    
    
    
    
    /// If the number of arguments is different from `numberOfGraphs`, this does nothing.
    func addSamples(newSamples: Double...) {
        lineView?.addSamples(newSamples)
    }
    
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        if let selfLayer = self.layer {
            gradientBackground.frame = selfLayer.bounds
            accessoryView?.frame = selfLayer.bounds
            lineView?.frame = selfLayer.bounds
        }
        
        gradientBackground.removeAllAnimations()
    }
    
}






private class LineView: NSView {
    
    private var sampleArrays = [[Double]]()
    
    var maxSamples = 0                              { didSet { setNeedsDisplayInRect(bounds) } }
    var maxValue: CGFloat = 0.0                     { didSet { setNeedsDisplayInRect(bounds) } }
    var minValue: CGFloat = 0.0                     { didSet { setNeedsDisplayInRect(bounds) } }
    var graphDirection = GraphDirection.LeftToRight { didSet { setNeedsDisplayInRect(bounds) } }
    var numberOfGraphs = 1 {
        didSet {
            sampleArrays = [[Double]](count: numberOfGraphs, repeatedValue: [Double]())
            setNeedsDisplayInRect(bounds)
        }
    }
    
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
    
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor(white: 1.0, alpha: Constants.Alpha).setStroke()
        drawGraph()
    }
    
    private func drawGraph() {
        let widthPerSample = (bounds.width - Constants.GraphSeparatorLineMargin) / CGFloat(maxSamples - 1)
        let pointsToSampleValueRatio = (bounds.height - Constants.TickMargin * 2) / (maxValue - minValue)
        
        let progress = CGFloat(sampleArrays[0].count - 1) / CGFloat(maxSamples)
        let window = bounds.width - Constants.GraphSeparatorLineMargin
        
        for samples in sampleArrays {
            var currentXValue: CGFloat
            switch graphDirection {
                case .RightToLeft: currentXValue = (progress - 1.0) * -1.0 * window
                case .LeftToRight: currentXValue = progress * window + Constants.GraphSeparatorLineMargin
            }
            
            for (index, sample) in samples.enumerate() {
                guard index > 0 else { continue } // Skip the first one
                
                let x1: CGFloat
                switch graphDirection {
                    case .RightToLeft: x1 = currentXValue - widthPerSample
                    case .LeftToRight: x1 = currentXValue + widthPerSample
                }
                let x2: CGFloat = currentXValue
                
                let y1: CGFloat = (CGFloat(samples[index - 1]) - minValue) * pointsToSampleValueRatio + Constants.TickMargin
                let y2: CGFloat = (CGFloat(sample) - minValue) * pointsToSampleValueRatio + Constants.TickMargin
                
                let point1 = NSPoint(x: x1, y: y1)
                let point2 = NSPoint(x: x2, y: y2)
                
                NSBezierPath.strokeLineFromPoint(point1, toPoint: point2)
                
                switch graphDirection {
                    case .RightToLeft: currentXValue += widthPerSample
                    case .LeftToRight: currentXValue -= widthPerSample
                }
            }
        }
    }
    
}


private class AccessoryView: NSView {
    
    var title = ""                                  { didSet { setNeedsDisplayInRect(bounds) } }
    var subTitle = ""                               { didSet { setNeedsDisplayInRect(bounds) } }
    var maxValue: CGFloat = 0.0                     { didSet { setNeedsDisplayInRect(bounds) } }
    var minValue: CGFloat = 0.0                     { didSet { setNeedsDisplayInRect(bounds) } }
    var graphDirection = GraphDirection.LeftToRight { didSet { setNeedsDisplayInRect(bounds) } }
    
    
    
    
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
            fill.moveToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin, y: 0.0))
            fill.lineToPoint(NSPoint(x: bounds.width, y: 0.0))
            fill.lineToPoint(NSPoint(x: bounds.width, y: bounds.height))
            fill.lineToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin, y: bounds.height))
        case .LeftToRight:
            fill.moveToPoint(NSPoint(x: 0.0, y: 0.0))
            fill.lineToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin, y: 0.0))
            fill.lineToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin, y: bounds.height))
            fill.lineToPoint(NSPoint(x: 0.0, y: bounds.height))
        }
        
        NSColor(white: 1.0, alpha: 0.2).setFill()
        fill.fill()
    }
    
    private func drawSeparatorLine() {
        let separatorLine = NSBezierPath()
        
        switch graphDirection {
        case .RightToLeft:
            separatorLine.moveToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin, y: 0.0))
            separatorLine.lineToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin, y: bounds.height))
        case .LeftToRight:
            separatorLine.moveToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin, y: 0.0))
            separatorLine.lineToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin, y: bounds.height))
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
            tick1.moveToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin, y: Constants.TickMargin))
            tick1.lineToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin + Constants.TickWidth, y: Constants.TickMargin))
            
            tick2.moveToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin, y: bounds.height / 2.0))
            tick2.lineToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin + Constants.TickWidth / 2.0, y: bounds.height / 2.0))
            
            tick3.moveToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin, y: bounds.height - Constants.TickMargin))
            tick3.lineToPoint(NSPoint(x: bounds.width - Constants.GraphSeparatorLineMargin + Constants.TickWidth, y: bounds.height - Constants.TickMargin))
        case .LeftToRight:
            tick1.moveToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin, y: Constants.TickMargin))
            tick1.lineToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin - Constants.TickWidth, y: Constants.TickMargin))
            
            tick2.moveToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin, y: bounds.height / 2.0))
            tick2.lineToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin - Constants.TickWidth / 2.0, y: bounds.height / 2.0))
            
            tick3.moveToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin, y: bounds.height - Constants.TickMargin))
            tick3.lineToPoint(NSPoint(x: Constants.GraphSeparatorLineMargin - Constants.TickWidth, y: bounds.height - Constants.TickMargin))
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
            let x = bounds.width - Constants.GraphSeparatorLineMargin + Constants.TickWidth + 5.0
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
            let x = Constants.GraphSeparatorLineMargin - Constants.TickWidth - 5.0
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
        let subTitleLabel = NSAttributedString(string: subTitle, attributes: subTitleAttributes)
        
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


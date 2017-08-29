//
//  GraphView.swift
//  Graph View
//
//  Created by Vegard Solheim Theriault on 13/01/2017.
//  Copyright © 2017 Vegard Solheim Theriault. All rights reserved.
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

import MetalKit
import Accelerate
import simd


// -------------------------------
// MARK: Platform Specific Types
// -------------------------------

#if os(iOS)
    import UIKit
    public      typealias View       = UIView
    public      typealias Color      = UIColor
    fileprivate typealias Label      = UILabel
    fileprivate typealias Font       = UIFont
    fileprivate typealias BezierPath = UIBezierPath
    fileprivate typealias Point      = CGPoint
    fileprivate typealias Rect       = CGRect


    extension Label {
        convenience init(labelWithString string: String) {
            self.init()
            text = string

        }
    }
#elseif os(OSX)
    import Cocoa
    public      typealias View       = NSView
    public      typealias Color      = NSColor
    fileprivate typealias Label      = NSTextField
    fileprivate typealias Font       = NSFont
    fileprivate typealias BezierPath = NSBezierPath
    fileprivate typealias Point      = NSPoint
    fileprivate typealias Rect       = NSRect

    extension NSView {
        func setNeedsDisplay() {
            setNeedsDisplay(bounds)
        }
    }

    extension NSTextField {
        var text : String {
            get {
                return stringValue
            }
            set {
                stringValue = newValue
            }
        }
    }

    extension CVDisplayLink {
        func invalidate() {
            CVDisplayLinkStop(self)
        }
    }
#endif

#if swift(>=4.0)

#else
    extension MTLRenderCommandEncoder {
        func setVertexBuffer(buffer: MTLBuffer, offset: Int, index: Int) {
            setVertexBuffer(buffer, offset: offset, at: index)
        }

        func setVertexBufferOffset(_ offset: Int, index: Int) {
            setVertexBufferOffset(offset, at: index)
        }
    }

#endif


// -------------------------------
// MARK: Constants
// -------------------------------

fileprivate struct Constants {
    static let ValueLabelWidth  : CGFloat = 60
    static let TopBottomPadding : CGFloat = 16
    static let CornerRadius     : CGFloat = 10
}




// -------------------------------
// MARK: Data Structures
// -------------------------------

public extension GraphView {
    public enum GraphType {
        case scatter

        /// Line currently only works when using the replace(with: ...)
        /// function to set the data.
        case line
    }

    public enum SampleSize {
        case small
        case large
        case custom(size: UInt8)

        fileprivate func size() -> UInt8 {
            switch self {
            case .small: return 2
            case .large: return 6
            case .custom(let size): return size
            }
        }
    }
}



// -------------------------------
// MARK: Graph View
// -------------------------------

public class GraphView: View {

    /// The background color of the graph view. This will be a gradient color,
    /// unless `.clear` is selected.
    public var backgroundTint = BackgroundTintColor.blue {
        didSet {
            #if os(iOS)
                gradientBackground.gradient.colors = backgroundTint.colors().reversed()
            #elseif os(OSX)
                gradientBackground.gradient.colors = backgroundTint.colors()
            #endif
        }
    }

    /// The color of the samples plotted in the graph. This can either be
    /// a `.plain` color, or a `.gradient` one.
    public var sampleColor = SampleColor.color(plain: .white) {
        didSet {
            switch sampleColor {
            case .color(color):
                metalGraph.uniforms.topColor    = color.vector()
                metalGraph.uniforms.bottomColor = color.vector()
            case let .gradient(top, bottom):
                metalGraph.uniforms.topColor    = top.vector()
                metalGraph.uniforms.bottomColor = bottom.vector()
            }


            metalGraph.setNeedsDisplay()
        }
    }

    /// Whether or not the graph should have rounded corners.
    public var roundedCorners = true {
        didSet { gradientBackground.gradient.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0 }
    }

    /// The title string that appears in the top left of the view
    public var title = "" {
        didSet {
            titleLabel.text = title
        }
    }

    /// The subtitle string that appears right under the title
    public var subtitle = "" {
        didSet {
            subtitleLabel.text = subtitle
        }
    }

    /// The unit of the samples added to the graph. This appears as a suffix
    /// for the value labels on the right hand side.
    public var valueUnit = "" {
        didSet {
            updateMinMaxLabels()
        }
    }

    /// The number of desired decimals displayed for the values. The default is 0.
    public var valueUnitDecimals = 0 {
        didSet {
            updateMinMaxLabels()
        }
    }

    /// The number of samples that fit in the graph view. When more samples than this are
    /// added, the oldest samples will slide off the left edge. The default value is 1000.
    public var capacity: Int {
        get { return Int(_capacity) }
        set { _capacity = Float(newValue) }
    }

    /// How the graph should be plotted. The `.line` option currently does not work propertly
    public var graphType = GraphType.scatter {
        didSet {
            metalGraph.graphType = graphType

            metalGraph.setNeedsDisplay()
        }
    }

    /// This is only applicable when `graphType` is set to `.scatter`.
    public var sampleSize = SampleSize.small {
        didSet {
            metalGraph.uniforms.pointSize = sampleSize.size()

            metalGraph.setNeedsDisplay()
        }
    }

    /// This property is only available on iOS. It specifies if the user should
    /// be able to change the capacity (by pinching horizontally), the minimum
    /// and maximum value (by pinching vertically), and moving up and down the
    /// y-axis (by swiping). When the user has started interacting, an "Auto-Scale"
    /// button will appear. This button is removed again when the user taps it.
    #if os(iOS)
    public var gesturesEnabled = true {
        didSet {
            if gesturesEnabled {
                addGestureRecognizers()
            } else {
                removeGestureRecognizers()
            }
        }
    }
    #endif

    /// Gets or sets the range of values that can be visible within the graph view.
    /// If `isAutoscaling` is set to true, this will change by itself. If you want
    /// to set this variable yourself, you should probably set `isAutoscaling` to false.
    public var visibleRange: ClosedRange<Float> {
        get {
            return ClosedRange<Float>(uncheckedBounds: (metalGraph.uniforms.minValue, metalGraph.uniforms.maxValue))
        }
        set {
            guard newValue.upperBound > newValue.lowerBound else { return }

            metalGraph.uniforms.maxValue = newValue.upperBound
            metalGraph.uniforms.minValue = newValue.lowerBound

            metalGraph.setNeedsDisplay()
            updateMinMaxLabels()
        }
    }

    /// Whether or not the graph should be autoscaling. This will be false if the
    /// user is currently using gestures
    public var isAutoscaling = true {
        didSet {
            metalGraph.isAutoscaling = isAutoscaling

            #if os(iOS)
                if isAutoscaling {
                    removeAutoScaleButton()
                } else {
                    addAutoScaleButton()
                }
            #endif
        }
    }

    /// Horizontal lines will be drawn with the y-axis values corresponding
    /// to the values in this array.
    public var horizontalLines: [Float] = [] {
        didSet { drawHorizontalLines() }
    }





    // -------------------------------
    // MARK: Public Methods
    // -------------------------------

    /// Adds a new sample to the graph. If the number of samples added is the
    /// same as the value of `capacity`, the oldest value will be pushed out to
    /// the left side of the graph view.
    public func add(sample: Float) {
        metalGraph.add(sample: sample)
    }

    /// Replaces all the current samples in the graph. This will also modify
    /// `capacity` to the numper of samples in this call. Calling this function
    /// is much faster than manually calling `add(...)` for each individual sample.
    public func replace(with samples: [Float]) {
        guard samples.count > 0 else { return }

        _capacity = Float(samples.count)
        metalGraph.set(samples: samples)
    }

    /// Removes every sample from the graph.
    public func clear() {
        metalGraph.clear()
    }



    // -------------------------------
    // MARK: Private Properties
    // -------------------------------

    #if os(iOS)
    private var pinchRecognizer     : UIPinchGestureRecognizer?
    private var panRecognizer       : UIPanGestureRecognizer?
    private var doubleTapRecognizer : UITapGestureRecognizer?
    private var previousPinchPosY   : CGFloat?
    #endif

    // This is here so it can be set independently of the user facing capacity
    // It's also a Float so that scaling will work properly
    private var _capacity: Float = 1000 {
        didSet {
            // Clamping value to [2, Int32.max]
            if _capacity < 2 { _capacity = 2 }
            else if _capacity > Float(Int32.max) { _capacity = Float(Int32.max) }

            metalGraph.changeCapacity(to: UInt32(_capacity))
        }
    }

    private var updateMinMaxLabelsTimer: Timer!

    // Subviews
    private     var gradientBackground : _GradientView!
    private     var accessoriesView    : _AccessoriesView!
    fileprivate var metalGraph         : _MetalGraphView!
    fileprivate var horizontalLineView : _HorizontalLinesView!
    fileprivate var maximumValueLabel  : Label!
    fileprivate var midValueLabel      : Label!
    fileprivate var minimumValueLabel  : Label!
    fileprivate var titleLabel         : Label!
    fileprivate var subtitleLabel      : Label!

    #if os(iOS)
    fileprivate var autoScaleButton    : GraphButton?
    #endif




    // -------------------------------
    // MARK: Initialization
    // -------------------------------

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {

        #if os(iOS)
            isOpaque = false
            backgroundColor = .clear
        #elseif os(OSX)
            wantsLayer = true
            layer?.isOpaque = false
            layer?.backgroundColor = Color.clear.cgColor
        #endif

        addBackgroundView()
        addHorizontalLineView()
        addMetalGraphView()
        addAccessoriesView()
        addValueLabels()
        addTitleAndSubtitleLabels()

        #if os(iOS)
            if gesturesEnabled { addGestureRecognizers() }
        #endif

        updateMinMaxLabelsTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            self.updateMinMaxLabels()
        }
    }

    private func addBackgroundView() {
        gradientBackground = _GradientView(frame: bounds)
        #if os(iOS)
            gradientBackground.gradient.colors = backgroundTint.colors().reversed()
        #elseif os(OSX)
            gradientBackground.gradient.colors = backgroundTint.colors()
        #endif
        gradientBackground.gradient.cornerRadius = roundedCorners ? Constants.CornerRadius : 0.0
        addSubview(gradientBackground)
        gradientBackground.translatesAutoresizingMaskIntoConstraints = false
        gradientBackground.topAnchor     .constraint(equalTo: topAnchor)   .isActive = true
        gradientBackground.bottomAnchor  .constraint(equalTo: bottomAnchor).isActive = true
        gradientBackground.trailingAnchor.constraint(equalTo: trailingAnchor) .isActive = true
        gradientBackground.leadingAnchor .constraint(equalTo: leadingAnchor)  .isActive = true
    }

    private func addHorizontalLineView() {
        horizontalLineView = _HorizontalLinesView(frame: bounds)
        addSubview(horizontalLineView)
        horizontalLineView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLineView.topAnchor     .constraint(equalTo: topAnchor,      constant:  Constants.TopBottomPadding).isActive = true
        horizontalLineView.bottomAnchor  .constraint(equalTo: bottomAnchor,   constant: -Constants.TopBottomPadding).isActive = true
        horizontalLineView.leadingAnchor .constraint(equalTo: leadingAnchor,  constant:  0)                         .isActive = true
        horizontalLineView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.ValueLabelWidth) .isActive = true
    }

    private func addMetalGraphView() {
        let uniforms = _MetalGraphView.Uniforms(
            offset      : 0,
            capacity    : UInt32(capacity),
            minValue    : 0,
            maxValue    : 1,
            pointSize   : sampleSize.size(),
            topColor    : vector_float4(1, 1, 1, 1),
            bottomColor : vector_float4(1, 1, 1, 1)
        )
        metalGraph = _MetalGraphView(frame: bounds, uniforms: uniforms)
        switch sampleColor {
        case .color(let color):
            metalGraph.uniforms.topColor    = color.vector()
            metalGraph.uniforms.bottomColor = color.vector()
        case .gradient(let top, let bottom):
            metalGraph.uniforms.topColor    = top   .vector()
            metalGraph.uniforms.bottomColor = bottom.vector()
        }

        addSubview(metalGraph)
        metalGraph.translatesAutoresizingMaskIntoConstraints = false
        metalGraph.topAnchor     .constraint(equalTo: topAnchor,      constant:  Constants.TopBottomPadding).isActive = true
        metalGraph.bottomAnchor  .constraint(equalTo: bottomAnchor,   constant: -Constants.TopBottomPadding).isActive = true
        metalGraph.leadingAnchor .constraint(equalTo: leadingAnchor,  constant:  0)                         .isActive = true
        metalGraph.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.ValueLabelWidth) .isActive = true
    }

    private func addAccessoriesView() {
        accessoriesView = _AccessoriesView(frame: bounds)
        addSubview(accessoriesView)
        accessoriesView.translatesAutoresizingMaskIntoConstraints = false
        accessoriesView.topAnchor     .constraint(equalTo: topAnchor)     .isActive = true
        accessoriesView.bottomAnchor  .constraint(equalTo: bottomAnchor)  .isActive = true
        accessoriesView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        accessoriesView.widthAnchor   .constraint(equalToConstant: Constants.ValueLabelWidth).isActive = true
    }

    private func addValueLabels() {
        let maxValue = metalGraph.uniforms.maxValue
        let minValue = metalGraph.uniforms.minValue
        let midValue = Int32((Double(maxValue - minValue)/2 + Double(minValue)).rounded())

        maximumValueLabel = Label(labelWithString: "\(maxValue)")
        midValueLabel     = Label(labelWithString: "\(midValue)")
        minimumValueLabel = Label(labelWithString: "\(minValue)")

        addSubview(maximumValueLabel)
        addSubview(midValueLabel)
        addSubview(minimumValueLabel)

        maximumValueLabel.translatesAutoresizingMaskIntoConstraints = false
        midValueLabel    .translatesAutoresizingMaskIntoConstraints = false
        minimumValueLabel.translatesAutoresizingMaskIntoConstraints = false

        maximumValueLabel.font = Font.systemFont(ofSize: 15)
        midValueLabel    .font = Font.systemFont(ofSize: 15)
        minimumValueLabel.font = Font.systemFont(ofSize: 15)

        maximumValueLabel.textColor = Color(white: 1, alpha: 0.7)
        midValueLabel    .textColor = Color(white: 1, alpha: 0.7)
        minimumValueLabel.textColor = Color(white: 1, alpha: 0.7)

        maximumValueLabel.leadingAnchor.constraint(equalTo: accessoriesView.leadingAnchor, constant: 20).isActive = true
        midValueLabel    .leadingAnchor.constraint(equalTo: accessoriesView.leadingAnchor, constant: 20).isActive = true
        minimumValueLabel.leadingAnchor.constraint(equalTo: accessoriesView.leadingAnchor, constant: 20).isActive = true

        maximumValueLabel.widthAnchor.constraint(equalToConstant: Constants.ValueLabelWidth).isActive = true
        midValueLabel    .widthAnchor.constraint(equalToConstant: Constants.ValueLabelWidth).isActive = true
        minimumValueLabel.widthAnchor.constraint(equalToConstant: Constants.ValueLabelWidth).isActive = true

        maximumValueLabel.topAnchor    .constraint(equalTo: topAnchor,    constant: Constants.TopBottomPadding - 10).isActive = true
        minimumValueLabel.bottomAnchor .constraint(equalTo: bottomAnchor, constant: -7).isActive = true
        midValueLabel    .centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    private func addTitleAndSubtitleLabels() {
        #if os(iOS)
            titleLabel    = Label()
            subtitleLabel = Label()

            titleLabel   .text = title
            subtitleLabel.text = subtitle

            titleLabel   .minimumScaleFactor = 0.1
            subtitleLabel.minimumScaleFactor = 0.1

            titleLabel   .adjustsFontSizeToFitWidth = true
            subtitleLabel.adjustsFontSizeToFitWidth = true

        #elseif os(OSX)
            titleLabel    = Label(labelWithString: title)
            subtitleLabel = Label(labelWithString: subtitle)

            titleLabel   .preferredMaxLayoutWidth = 1
            subtitleLabel.preferredMaxLayoutWidth = 1
        #endif

        titleLabel   .translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel   .font = Font.systemFont(ofSize: 30)
        subtitleLabel.font = Font.systemFont(ofSize: 20)

        titleLabel   .textColor = Color(white: 1, alpha: 1)
        subtitleLabel.textColor = Color(white: 1, alpha: 0.6)

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel   .leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true

        titleLabel   .topAnchor.constraint(equalTo: topAnchor,               constant: 20).isActive = true
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5) .isActive = true

        titleLabel   .trailingAnchor.constraint(equalTo: metalGraph.trailingAnchor, constant: -20).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: metalGraph.trailingAnchor, constant: -20).isActive = true
    }

    #if os(iOS)
    private func addAutoScaleButton() {
        guard autoScaleButton == nil else { return }

        autoScaleButton = GraphButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        autoScaleButton?.text = "Auto Scale"
        autoScaleButton?.addTarget(self, action: #selector(autoScaleButtonTapped), for: .touchUpInside)
        autoScaleButton?.translatesAutoresizingMaskIntoConstraints = false
        autoScaleButton?.alpha = 0
        addSubview(autoScaleButton!)

        autoScaleButton?.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(Constants.ValueLabelWidth + 16)).isActive = true
        autoScaleButton?.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        autoScaleButton?.widthAnchor.constraint(equalToConstant: 110).isActive = true
        autoScaleButton?.heightAnchor.constraint(equalToConstant: 30).isActive = true

        UIView.animate(withDuration: 0.5) {
            self.autoScaleButton?.alpha = 1
        }
    }
    #endif

    #if os(iOS)
    private func removeAutoScaleButton() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0.1,
            options: [],
            animations: {
                self.autoScaleButton?.alpha = 0
        }, completion: { _ in
            self.autoScaleButton?.removeFromSuperview()
            self.autoScaleButton = nil
        }
        )
    }
    #endif

    /// Calling this will draw a constant horizontal line across the entire graph
    /// for each of the specified values. It will also override any previous
    /// horizontal lines.
    fileprivate func drawHorizontalLines() {
        horizontalLineView.lines = horizontalLines.map {
            ($0 - visibleRange.lowerBound) / (visibleRange.upperBound - visibleRange.lowerBound)
        }
    }



    // -------------------------------
    // MARK: Gesture Recognizers
    // -------------------------------

    #if os(iOS)
    private func addGestureRecognizers() {
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchRecognizerDidPinch))
        pinchRecognizer?.delegate = self
        addGestureRecognizer(pinchRecognizer!)

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panRecognizerDidPan))
        panRecognizer?.delegate = self
        panRecognizer?.minimumNumberOfTouches = 1
        panRecognizer?.maximumNumberOfTouches = 1
        addGestureRecognizer(panRecognizer!)

        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapRecognizerDidRecognize))
        doubleTapRecognizer?.numberOfTapsRequired = 2
        doubleTapRecognizer?.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapRecognizer!)
    }
    #endif

    #if os(iOS)
    private func removeGestureRecognizers() {
        if let pinch = pinchRecognizer {
            removeGestureRecognizer(pinch)
        }
        if let pan = panRecognizer {
            removeGestureRecognizer(pan)
        }
        if let doubleTap = doubleTapRecognizer {
            removeGestureRecognizer(doubleTap)
        }
    }
    #endif

    #if os(iOS)
    @objc private func pinchRecognizerDidPinch() {
        guard let pinch = pinchRecognizer else { return }

        switch pinch.state {
        case .began:
            isAutoscaling = false
            fallthrough
        case .changed:
            guard pinch.numberOfTouches >= 2 else { return }

            let a = pinch.location(ofTouch: 0, in: self)
            let b = pinch.location(ofTouch: 1, in: self)
            let dx = abs(a.x - b.x)
            let dy = abs(a.y - b.y)
            let midpointY = abs(a.y - b.y) / 2 + min(a.y, b.y)

            // Calculate new capacity
            let dxScale = (dx / (dx+dy)) * (1-pinch.scale) + 1
            let dyScale = (dy / (dx+dy)) * (1-pinch.scale) + 1
            let newCapacity = Float(CGFloat(_capacity) * dxScale)

            if newCapacity >= 2 {
                _capacity = newCapacity
            }

            // Calculate new visible range, based on pinch location
            let oldMin = metalGraph.uniforms.minValue
            let oldMax = metalGraph.uniforms.maxValue
            let oldRange = visibleRange

            let oldYSpread = oldRange.upperBound - oldRange.lowerBound
            let newYSpread = oldYSpread * Float(dyScale)
            let spreadChange = oldYSpread - newYSpread

            let pinchLocationRatio = midpointY / bounds.height

            let newMax = oldMax - Float(pinchLocationRatio) * spreadChange
            let newMin = oldMin + Float(1-pinchLocationRatio) * spreadChange

            visibleRange = newMin...newMax

            // Do panning, works even when one finger is lifted
            if let prevPos = previousPinchPosY {
                translate(with: Float(midpointY - prevPos))
            }

            previousPinchPosY = midpointY
            pinchRecognizer?.scale = 1.0
        default:
            // When released, cancelled, failed etc
            previousPinchPosY = nil
        }
    }
    #endif

    #if os(iOS)
    @objc private func doubleTapRecognizerDidRecognize() {
        switch sampleSize {
        case .custom: sampleSize = .small
        case .large : sampleSize = .small
        case .small : sampleSize = .large
        }
    }
    #endif

    #if os(iOS)
    @objc private func panRecognizerDidPan() {
        guard let pan = panRecognizer else { return }

        switch pan.state {
        case .began:
            isAutoscaling = false
            fallthrough
        case .changed:
            guard pan.numberOfTouches == 1 else { return }

            translate(with: Float(pan.translation(in: self).y))
            panRecognizer?.setTranslation(.zero, in: self)
        default: break
        }
    }
    #endif

    private func translate(with translation: Float) {
        let oldRange = visibleRange
        let visibleHeight = bounds.height - Constants.TopBottomPadding * 2
        let valuesPerPoint = abs(oldRange.upperBound - oldRange.lowerBound) / Float(visibleHeight)
        let valuesToMove = translation * valuesPerPoint

        let newMin = oldRange.lowerBound + valuesToMove
        let newMax = oldRange.upperBound + valuesToMove
        visibleRange = newMin...newMax
    }

    @objc private func autoScaleButtonTapped() {
        isAutoscaling = true
    }



}

#if os(iOS)

    extension GraphView: UIGestureRecognizerDelegate {
        public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // True unless we find a finger on the auto-scale button

            if let autoScaleButton = autoScaleButton {
                for i in 0..<gestureRecognizer.numberOfTouches {
                    let point = gestureRecognizer.location(ofTouch: i, in: self)
                    if autoScaleButton.frame.contains(point) {
                        return false
                    }
                }
            }

            return true
        }
    }

#endif

extension GraphView {
    @objc fileprivate func updateMinMaxLabels() {
        drawHorizontalLines()

        let minValue = metalGraph.uniforms.minValue
        let maxValue = metalGraph.uniforms.maxValue
        let midValue = (maxValue - minValue)/2 + minValue

        let minValueText = String(format: "%.\(valueUnitDecimals)f", minValue) + " " + self.valueUnit
        let midValueText = String(format: "%.\(valueUnitDecimals)f", midValue) + " " + self.valueUnit
        let maxValueText = String(format: "%.\(valueUnitDecimals)f", maxValue) + " " + self.valueUnit

        self.minimumValueLabel.text        = minValueText
        self.midValueLabel    .text        = midValueText
        self.maximumValueLabel.text        = maxValueText
    }
}




// -------------------------------
// MARK: Colors
// -------------------------------

public extension GraphView {
    public enum BackgroundTintColor: Int {
        case gray = 0
        case red
        case green
        case blue
        case turquoise
        case yellow
        case purple
        case clear

        fileprivate func colors() -> [CGColor] {
            switch self {
            case .gray:
                return [Color(red: 141.0/255.0, green: 140.0/255.0, blue: 146.0/255.0, alpha: 1.0).cgColor,
                        Color(red: 210.0/255.0, green: 209.0/255.0, blue: 215.0/255.0, alpha: 1.0).cgColor]
            case .red:
                return [Color(red: 253.0/255.0, green:  58.0/255.0, blue:  52.0/255.0, alpha: 1.0).cgColor,
                        Color(red: 255.0/255.0, green: 148.0/255.0, blue:  86.0/255.0, alpha: 1.0).cgColor]
            case .green:
                return [Color(red: 28.0/255.0,  green: 180.0/255.0, blue:  28.0/255.0, alpha: 1.0).cgColor,
                        Color(red: 78.0/255.0,  green: 238.0/255.0, blue:  92.0/255.0, alpha: 1.0).cgColor]
            case .blue:
                return [Color(red:  0.0/255.0,  green: 108.0/255.0, blue: 250.0/255.0, alpha: 1.0).cgColor,
                        Color(red: 90.0/255.0,  green: 202.0/255.0, blue: 251.0/255.0, alpha: 1.0).cgColor]
            case .turquoise:
                return [Color(red: 54.0/255.0,  green: 174.0/255.0, blue: 220.0/255.0, alpha: 1.0).cgColor,
                        Color(red: 82.0/255.0,  green: 234.0/255.0, blue: 208.0/255.0, alpha: 1.0).cgColor]
            case .yellow:
                return [Color(red: 255.0/255.0, green: 160.0/255.0, blue:  33.0/255.0, alpha: 1.0).cgColor,
                        Color(red: 254.0/255.0, green: 209.0/255.0, blue:  48.0/255.0, alpha: 1.0).cgColor]
            case .purple:
                return [Color(red: 140.0/255.0, green:  70.0/255.0, blue: 250.0/255.0, alpha: 1.0).cgColor,
                        Color(red: 217.0/255.0, green: 168.0/255.0, blue: 252.0/255.0, alpha: 1.0).cgColor]
            case .clear:
                return [Color.clear.cgColor]
            }
        }

        public static var count: Int { return BackgroundTintColor.clear.rawValue + 1 }
    }

    public enum SampleColor {
        case color(plain: Color)
        case gradient(top: Color, bottom: Color)
    }
}




// -------------------------------
// MARK: Gradient View
// -------------------------------

// This has to be a separate class to work properly with rotation animation
fileprivate class _GradientView: View {
    var gradient: CAGradientLayer {
        get { return layer as! CAGradientLayer }
    }

    #if os(iOS)
    override class var layerClass: AnyClass {
        get { return CAGradientLayer.self }
    }
    #elseif os(OSX)
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
    layerContentsRedrawPolicy = .onSetNeedsDisplay
    }
    fileprivate override func makeBackingLayer() -> CALayer {
    return CAGradientLayer()
    }
    #endif
}




// -------------------------------
// MARK: RenderCycle
// -------------------------------

fileprivate protocol RenderCycleObserver: class {
    func renderCycle()
}

class RenderCycle {
    private struct WeakRenderCycleObserver {
        weak var value : RenderCycleObserver?
        init (value: RenderCycleObserver) {
            self.value = value
        }
    }

    static let shared = RenderCycle()

    private var observers = [WeakRenderCycleObserver]()
    private var mutex = pthread_mutex_t()

    #if os(iOS)
    private var displayLink: CADisplayLink?
    #elseif os(OSX)
    private var displayLink: CVDisplayLink?
    #endif

    private init() {
        pthread_mutex_init(&mutex, nil)
    }

    private func initializeDisplayLink() {
        #if os(iOS)
            displayLink = CADisplayLink(target: self, selector: #selector(renderCycle))
            if #available(iOS 10, *) {
                displayLink?.preferredFramesPerSecond = 30
            } else {
                displayLink?.frameInterval = 2
            }
            displayLink?.add(to: .main, forMode: .commonModes)
        #elseif os(OSX)
            var dl: CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&dl)
            guard let displayLink = dl else { return }
            self.displayLink = displayLink

            CVDisplayLinkSetOutputCallback(displayLink, { _, _, _, _, _, context in
                if let context = context {
                    let me = Unmanaged<RenderCycle>.fromOpaque(context).takeUnretainedValue()
                    me.renderCycle()
                }
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())

            CVDisplayLinkStart(displayLink)
        #endif
    }

    private func destroyDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func renderCycle() {

        DispatchQueue.main.async {
            pthread_mutex_lock(&self.mutex)
            self.observers.forEach { $0.value?.renderCycle() }
            pthread_mutex_unlock(&self.mutex)
        }
    }

    fileprivate func add(cycleObserver: RenderCycleObserver) {
        pthread_mutex_lock(&mutex)
        observers.append(WeakRenderCycleObserver(value: cycleObserver))

        if observers.count == 1 {
            // Just added the first observer
            initializeDisplayLink()
        }
        pthread_mutex_unlock(&mutex)
    }

    fileprivate func remove(cycleObserver: RenderCycleObserver) {
        pthread_mutex_lock(&mutex)
        if let idx = observers.index(where: { $0.value === cycleObserver }) {
            observers.remove(at: idx)
        }

        if observers.count == 0 {
            // Just removed the last observer
            destroyDisplayLink()
        }
        pthread_mutex_unlock(&mutex)
    }
}




// -------------------------------
// MARK: Metal Graph
// -------------------------------

fileprivate class _MetalGraphView: View, RenderCycleObserver {

    struct Uniforms {
        var offset     : UInt32
        var capacity   : UInt32
        var minValue   : Float
        var maxValue   : Float
        var pointSize  : UInt8
        var topColor   : vector_float4
        var bottomColor: vector_float4

        // On macOS, the uniforms must be 256 byte aligned
        #if os(OSX)
        let pad0 = matrix_double4x4()
        let pad1 = matrix_double2x3()
        #endif
    }

    // User Data
    fileprivate var vertices: [Float]!
    private var verticesSemaphore: DispatchSemaphore!
    private var samplesAdded = 0
    private var needsRedraw = true
    private var needsRedrawMutex = pthread_mutex_t()
    var uniforms: Uniforms!
    var graphType = GraphView.GraphType.scatter

    var isAutoscaling = true {
        didSet {
            if isAutoscaling {
                guard case .success = verticesSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
                    Swift.print("❌ Semaphore wait timed out \(self)")
                    return
                }
                refreshMin()
                refreshMax()
                verticesSemaphore.signal()

                setNeedsDisplay()
            }
        }
    }

    // Metal State
    private var commandQueue: MTLCommandQueue!
    private var pipeline: MTLRenderPipelineState!
    private let multisamplingEnabled = true // Currently not in use

    // Buffers
    private var vertexBuffer: MTLBuffer!
    private var uniformBuffers: [MTLBuffer]!
    private let bufferOptions: MTLResourceOptions = [.cpuCacheModeWriteCombined, .storageModeShared]

    // Inflight Buffers
    private let numberOfInflightBuffers = 3
    private var inflightBufferSemaphore = DispatchSemaphore(value: 3) // Used for triple buffering
    private var inflightBufferIndex = 0

    private var device: MTLDevice!
    private var metalLayer: CAMetalLayer { return layer as! CAMetalLayer }



    // -------------------------------
    // MARK: Setup
    // -------------------------------

    required init(coder: NSCoder) {
        // _MetalGraphView will only be initialized by GraphView
        fatalError("❌ init(coder:) has not been implemented")
    }

    init(frame frameRect: CGRect, uniforms: Uniforms) {
        super.init(frame: frameRect)
        self.uniforms = uniforms
        setup()
    }


    private func setup() {
        #if os(iOS)
            layer.isOpaque = false
        #elseif os(OSX)
            wantsLayer = true
            layer?.isOpaque = false
        #endif

        pthread_mutex_init(&needsRedrawMutex, nil)

        // Setup user data
        vertices = [Float](repeating: 0, count: Int(uniforms.capacity))

        // Setup metal state
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            fatalError("❌ GraphView has to run on a device with Metal support")
        }

        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true

        commandQueue = device?.makeCommandQueue()
        setupBuffers()
        setupPipeline()

        // Setup semaphores
        verticesSemaphore       = DispatchSemaphore(value: 1)
        inflightBufferSemaphore = DispatchSemaphore(value: numberOfInflightBuffers)

        RenderCycle.shared.add(cycleObserver: self)
    }

    deinit {
        RenderCycle.shared.remove(cycleObserver: self)
    }

    #if os(iOS)

    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        let screen = window?.screen ?? UIScreen.main
        setNewScale(screen.scale)

        setNeedsDisplay()
    }

    #elseif os(OSX)

    override fileprivate func makeBackingLayer() -> CALayer {
    return CAMetalLayer()
    }

    fileprivate override func layout() {
    super.layout()
    setNewScale(window?.backingScaleFactor ?? 1)
    }

    fileprivate override func viewDidMoveToWindow() {
    setNewScale(window?.backingScaleFactor ?? 1)
    }

    #endif

    private func setNewScale(_ scale: CGFloat) {
        metalLayer.contentsScale = scale

        var drawableSize = bounds.size
        drawableSize.width  = round(scale * drawableSize.width)
        drawableSize.height = round(scale * drawableSize.height)

        metalLayer.drawableSize = drawableSize

        setNeedsDisplay()
    }

    #if os(iOS)
    fileprivate override func setNeedsDisplay() {
        pthread_mutex_lock(&needsRedrawMutex)
        needsRedraw = true
        pthread_mutex_unlock(&needsRedrawMutex)

        super.setNeedsDisplay()
    }
    #elseif os(OSX)
    fileprivate override func setNeedsDisplay(_ invalidRect: NSRect) {
    pthread_mutex_lock(&needsRedrawMutex)
    needsRedraw = true
    pthread_mutex_unlock(&needsRedrawMutex)

    super.setNeedsDisplay(invalidRect)
    }
    #endif




    // -------------------------------
    // MARK: 🤘 Setup
    // -------------------------------

    private func setupPipeline() {
        #if swift(>=4.0)
            guard let library = device!.makeDefaultLibrary() else {
            Swift.print("❌ There doesn't appear to be a .metal file in your project")
            return
            }
        #else
            guard let library = device!.newDefaultLibrary() else {
                Swift.print("❌ There doesn't appear to be a .metal file in your project")
                return
            }
        #endif
        guard let vertexFunction   = library.makeFunction(name: "vertexShader")   else {
            Swift.print("❌ Make sure that the .metal file in your project contains a function called \"vertexShader\"")
            return
        }
        guard let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            Swift.print("❌ Make sure that the .metal file in your project contains a function called \"fragmentShader\"")
            return
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction

        do {
            pipeline = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error as NSError {
            Swift.print("❌ Failed to create a render pipeline state with error: \(error)")
        }
    }

    private func setupBuffers() {
        // Vertices
        let vertexByteCount = MemoryLayout<Float>.size * Int(uniforms.capacity)
        vertexBuffer = device!.makeBuffer(length: vertexByteCount, options : bufferOptions)
        vertexBuffer.label = "Vertex Buffer"

        // Uniforms
        uniformBuffers = (0..<numberOfInflightBuffers).map {
            let byteCount = MemoryLayout<Uniforms>.size

            #if swift(>=4.0)
                guard let buffer = device!.makeBuffer(length: byteCount, options: bufferOptions) else {
                fatalError("❌ Failed to create buffer of size \(byteCount)")
                }
            #else
                let buffer = device!.makeBuffer(length: byteCount, options: bufferOptions)
            #endif

            buffer.label = "Uniforms Buffer \($0)"
            return buffer
        }
    }




    // -------------------------------
    // MARK: Fileprivate Methods
    // -------------------------------

    // Adds a new sample to the vertices array, and checks to see if the
    // sample added is a new min or max sample, or if the oldest sample
    // was the current min or max. In either case, a new min or max is
    // selected, respectively.
    func add(sample: Float) {
        // Grab the vertices array lock
        guard case .success = verticesSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
            Swift.print("❌ Semaphore wait timed out \(self))")
            return
        }

        // Used to check if we need to scan for a new min or max
        let sampleToRemove = vertices[Int(uniforms.offset)]

        // Write the new sample to the vertices array
        vertices[Int(uniforms.offset)] = sample
        uniforms.offset = (uniforms.offset + 1) % UInt32(vertices.count)

        if samplesAdded == 0 && isAutoscaling {
            // This was the first sample
            uniforms.minValue = sample - 1
            uniforms.maxValue = sample + 1
        } else if samplesAdded == 2 {
            refreshMin()
            refreshMax()
        } else {
            // This was not the first sample

            if isAutoscaling {

                if sample < uniforms.minValue {
                    // The sample added is a new min
                    uniforms.minValue = sample
                } else if sample > uniforms.maxValue {
                    // The sample added is a new max
                    uniforms.maxValue = sample
                }

                // Checking if sampleToRemove is equal to the current min or max.
                // Not the best of practises, but hopefully the epsilon large enough to avoid
                // inaccuracies, and small enough to not conflict with any actual values.
                let epsilon: Float = 0.00001
                if abs(sampleToRemove - uniforms.minValue) < epsilon {
                    // The sample that was removed was the previous min value.
                    // Rescanning for a new min value
                    refreshMin()
                }
                if abs(sampleToRemove - uniforms.maxValue) < epsilon {
                    // The sample that was removed was the previous max value.
                    // Rescanning for a new max value
                    refreshMax()
                }
            }
        }

        // Updating this after the sample has been added as a vertex to avoid race conditions.
        // If the draw occurs between when the vertex is added, and samplesAdded is updated,
        // this sample won't get drawn until the next screen update. This is only an issue in
        // the beginning when uniforms.capacity > samplesAdded.
        samplesAdded = min(samplesAdded + 1, Int(uniforms.capacity))

        // Release the vertices array lock
        verticesSemaphore.signal()

        setNeedsDisplay()
    }

    /// Replaces the entire vertices array with new data.
    /// uniforms.capacity and the vertex buffer is resized accordingly.
    func set(samples: [Float]) {
        guard case .success = verticesSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
            Swift.print("❌ Semaphore wait timed out \(self))")
            return
        }
        for _ in 0..<3 {
            guard case .success = inflightBufferSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
                Swift.print("❌ Semaphore wait timed out \(self))")
                return
            }
        }

        samplesAdded = samples.count
        uniforms.offset = 0
        uniforms.capacity = UInt32(samples.count)
        vertices = samples

        let vertexByteCount = MemoryLayout<Float>.size * Int(uniforms.capacity)
        if vertexBuffer.length != vertexByteCount {
            vertexBuffer = device!.makeBuffer(length: vertexByteCount, options : bufferOptions)
            vertexBuffer.label = "Vertex Buffer"
        }

        if isAutoscaling {
            refreshMin()
            refreshMax()
        }

        for _ in 0..<3 { inflightBufferSemaphore.signal() }
        verticesSemaphore.signal()

        setNeedsDisplay()
    }

    // Changes the size of the vertices array, and the vertex buffers.
    // It stops all drawing, and waits until the buffers are available
    // before resizing.
    func changeCapacity(to newCapacity: UInt32) {

        // Make sure we have a new capacity
        guard newCapacity != uniforms.capacity else { return }

        guard case .success = verticesSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
            Swift.print("❌ Semaphore wait timed out \(self))")
            return
        }

        // We will re-alloc the metal buffers, so stop all drawing.
        for _ in 0..<3 {
            guard case .success = inflightBufferSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
                Swift.print("❌ Semaphore wait timed out \(self))")
                return
            }
        }

        // First resize the vertices array
        if newCapacity > uniforms.capacity {
            // Increase the buffer size
            let count = Int(newCapacity - uniforms.capacity)

            if samplesAdded < Int(uniforms.capacity) {
                // All the elements in the vertices array are not yet populated
                vertices.append(contentsOf: [Float](repeating: 0, count: count))
            } else {
                // All the elements in the vertices array are populated
                let suffix = vertices.suffix(from: Int(uniforms.offset))
                let prefix = vertices.prefix(upTo: Int(uniforms.offset))
                vertices = suffix + prefix + [Float](repeating: 0, count: count)

                uniforms.offset = UInt32(samplesAdded - 1)
            }
        } else {
            // Remove samples

            let count = Int(uniforms.capacity - newCapacity)
            let rightStartIndex = Int(uniforms.offset) // This is the oldest sample in the verticesArray
            // The elements we're removing could be spread over both
            // the right side, and the left side of the vertices array,
            // so it gets sort of tricky.

            // Remove the portion on the right-hand side
            let rightEndIndex = min(rightStartIndex + count - 1, vertices.count - 1)
            vertices.removeSubrange(rightStartIndex...rightEndIndex)

            // Check if we need to remove from the left-hand side as well
            if rightStartIndex + count > Int(uniforms.capacity) {
                let leftCount = rightStartIndex + count - Int(uniforms.capacity)
                vertices.removeFirst(leftCount)
            }

            // If we've removed everything on the right-hand side, then
            // the write index should be set to zero.
            if rightStartIndex + count >= Int(uniforms.capacity) {
                uniforms.offset = 0
            }
        }

        // New that the vertices array has been resized, re-alloc the vertex buffers
        let newBufferSize = MemoryLayout<Float>.size * Int(newCapacity)
        vertexBuffer = device!.makeBuffer(length: newBufferSize, options : bufferOptions)
        vertexBuffer.label = "Vertex Buffer"

        uniforms.capacity = newCapacity
        samplesAdded = min(samplesAdded, Int(uniforms.capacity))

        refreshMin()
        refreshMax()

        // All the buffers have been re-alloced, and are ready for drawing
        for _ in 0..<3 { inflightBufferSemaphore.signal() }

        verticesSemaphore.signal()

        setNeedsDisplay()
    }

    func clear() {
        guard case .success = verticesSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
            Swift.print("❌ Semaphore wait timed out \(self))")
            return
        }
        vertices = [Float](repeating: 0, count: Int(uniforms.capacity))
        uniforms.offset = 0
        samplesAdded = 0
        verticesSemaphore.signal()

        uniforms.minValue = 0
        uniforms.maxValue = 1

        setNeedsDisplay()
    }

    // -------------------------------
    // MARK: Drawing
    // -------------------------------

    private func updateUniforms() {
        memcpy(
            uniformBuffers[inflightBufferIndex].contents(),
            &uniforms,
            MemoryLayout<Uniforms>.size
        )
    }

    private func updateVertexBuffer() {
        guard case .success = verticesSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
            Swift.print("❌ Semaphore wait timed out \(self))")
            return
        }
        _ = vertices.withUnsafeBytes {
            memcpy(
                self.vertexBuffer.contents(),
                $0.baseAddress,
                MemoryLayout<Float>.size * vertices.count
            )
        }
        verticesSemaphore.signal()
    }

    func renderCycle() {
        guard (bounds.size.width > 0 && bounds.size.height > 0 && bounds.size.width <= 16384) &&
            samplesAdded > 0 &&
            uniformBuffers != nil &&
            window != nil
            else { return }

        pthread_mutex_lock(&needsRedrawMutex)
        let shouldDraw = needsRedraw
        needsRedraw = false
        pthread_mutex_unlock(&needsRedrawMutex)

        if shouldDraw {
            autoreleasepool { self.render() }
        }
    }

    private func render() {
        guard case .success = inflightBufferSemaphore.wait(timeout: .now() + .milliseconds(100)) else {
            Swift.print("❌ Semaphore wait timed out \(self))")
            return
        }

        updateUniforms()
        updateVertexBuffer()

        #if swift(>=4.0)
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            Swift.print("❌ Failed to create command buffer")
            return
            }
        #else
            let commandBuffer = commandQueue.makeCommandBuffer()
        #endif
        commandBuffer.label = "Graph Command Buffer"

        guard let drawable = metalLayer.nextDrawable() else {
            Swift.print("❌ No drawable")
            inflightBufferSemaphore.signal()
            return
        }

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        #if swift(>=4.0)
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
            Swift.print("❌ Failed to create render command encoder with pass descriptor \(passDescriptor)")
            return
            }
        #else
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        #endif
        encoder.label = "Graph Encoder"
        encoder.setRenderPipelineState(pipeline)

        encoder.setVertexBuffer(vertexBuffer,  offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffers[inflightBufferIndex], offset: 0, index: 1)

        switch graphType {
        case .scatter:
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: samplesAdded)
        case .line:
            // - Draw in two parts based on the verticesWriteIndex to avoid the line from start to finish.
            // - Probably use setVertexOffset or something.
            // - Take a look at offset byte alignment in the documentation for setVertexBufferOffset.
            // - The problem with this approach is that the vid in the vertex shader gets reset for every
            //   drawPrimitives call. The result is that two lines are being drawn on top of each other.
            // - Perhaps the solution is to change the uniforms buffer, or even to have a separate
            //   uniforms buffer that is used when drawing as a line.

            encoder.setVertexBufferOffset(MemoryLayout<Float>.size * Int(uniforms.offset), index: 0)

            encoder.drawPrimitives(
                type        : .lineStrip,
                vertexStart : 0,
                vertexCount : samplesAdded - Int(uniforms.offset)
            )

            encoder.setVertexBufferOffset(0, index: 0)

            encoder.drawPrimitives(
                type        : .lineStrip,
                vertexStart : 0,
                vertexCount : Int(uniforms.offset) + 1
            )
        }

        encoder.endEncoding()

        commandBuffer.addCompletedHandler { _ in
            self.inflightBufferSemaphore.signal()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()

        inflightBufferIndex = (inflightBufferIndex + 1) % numberOfInflightBuffers
    }

    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------

    private func refreshMin() {
        guard samplesAdded > 0 && isAutoscaling else { return }

        var minimum : Float = .greatestFiniteMagnitude

        if samplesAdded == 1 {
            minimum = vertices[0] - 1
        } else {
            vDSP_minv(vertices, vDSP_Stride(1), &minimum, vDSP_Length(samplesAdded))
        }

        uniforms.minValue = minimum
    }

    private func refreshMax() {
        guard samplesAdded > 0 && isAutoscaling else { return }

        var maximum = -Float.greatestFiniteMagnitude

        if samplesAdded == 1 {
            maximum = vertices[0] + 1
        } else {
            vDSP_maxv(vertices, vDSP_Stride(1), &maximum, vDSP_Length(samplesAdded))
        }

        uniforms.maxValue = maximum
    }
}





// -------------------------------
// MARK: Accessories View
// -------------------------------

fileprivate class _AccessoriesView: View {

    // -------------------------------
    // MARK: Setup
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
        #if os(iOS)
            backgroundColor = .clear
            isOpaque = false
            contentMode = .redraw
        #elseif os(OSX)
            wantsLayer = true
            layer?.backgroundColor = .clear
        #endif
    }


    // -------------------------------
    // MARK: Draw
    // -------------------------------

    fileprivate override func draw(_ rect: CGRect) {
        // Constants for the accessories view
        let lineWidth: CGFloat = 2
        let tickLength: CGFloat = 10

        // Set up the path
        let path = BezierPath()
        path.lineWidth = lineWidth
        Color(white: 1, alpha: 0.3).setStroke()


        #if os(iOS)
            // Vertical Line
            path.move(   to: Point(x: 0, y: 0))
            path.addLine(to: Point(x: 0, y: bounds.size.height))

            // Top
            path.move(   to: Point(x: lineWidth/2, y: Constants.TopBottomPadding))
            path.addLine(to: Point(x: lineWidth/2 + tickLength, y: Constants.TopBottomPadding))

            // Middle
            path.move(   to: Point(x: lineWidth/2, y: bounds.size.height / 2))
            path.addLine(to: Point(x: lineWidth/2 + tickLength, y: bounds.size.height / 2))

            // Bottom
            path.move(   to: Point(x: lineWidth/2, y: bounds.size.height - Constants.TopBottomPadding))
            path.addLine(to: Point(x: lineWidth/2 + tickLength, y: bounds.size.height - Constants.TopBottomPadding))

        #elseif os(OSX)
            // Vertical Line
            path.move(to: Point(x: 0, y: 0))
            path.line(to: Point(x: 0, y: bounds.size.height))

            // Top
            path.move(to: Point(x: lineWidth/2, y: bounds.size.height - Constants.TopBottomPadding))
            path.line(to: Point(x: lineWidth/2 + tickLength, y: bounds.size.height - Constants.TopBottomPadding))

            // Middle
            path.move(to: Point(x: lineWidth/2, y: bounds.size.height / 2))
            path.line(to: Point(x: lineWidth/2 + tickLength, y: bounds.size.height / 2))

            // Bottom
            path.move(to: Point(x: lineWidth/2, y: Constants.TopBottomPadding))
            path.line(to: Point(x: lineWidth/2 + tickLength, y: Constants.TopBottomPadding))
        #endif


        // Stroke the path
        path.stroke()
    }
}



// -------------------------------
// MARK: Horizontal Lines
// -------------------------------

fileprivate class _HorizontalLinesView: View {

    /// Should be values between 0 (bottom) and 1 (top)
    var lines = [Float]() {
        didSet { setNeedsDisplay(bounds) }
    }

    override init(frame frameRect: Rect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        #if os(iOS)
            backgroundColor = .clear
            isOpaque = false
            contentMode = .redraw
        #elseif os(OSX)
            wantsLayer = true
            layer?.backgroundColor = .clear
        #endif
    }

    override func draw(_ dirtyRect: Rect) {
        super.draw(dirtyRect)

        for line in lines {
            #if os(OSX)
                let y = CGFloat(line) * bounds.height
            #elseif os(iOS)
                let y = CGFloat(1-line) * bounds.height
            #endif

            let path = BezierPath()
            path.move(to: Point(x: 0, y: y))
            #if os(OSX)
                path.line(to: Point(x: bounds.width, y: y))
            #elseif os(iOS)
                path.addLine(to: Point(x: bounds.width, y: y))
            #endif

            Color(white: 1, alpha: 0.7).setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }
}




// -------------------------------
// MARK: Graph Button
// -------------------------------

#if os(iOS)

    @IBDesignable
    class GraphButton: UIButton {

        @IBInspectable
        var text: String = ""

        @IBInspectable
        var fontSize: CGFloat = 17

        override var isHighlighted: Bool {
            didSet { setNeedsDisplay() }
        }

        // Overrides the case when a touch is near the bottom or top of the screen, and
        // iOS waits to check if the user want to open Control Center or Notification Center.
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            if bounds.contains(point) {
                isHighlighted = true
                return true
            } else {
                return false
            }
        }

        override func draw(_ rect: CGRect) {
            // Set fill color
            Color(white: 1, alpha: isHighlighted ? 0.3 : 0.5).setFill()

            // Draw the background
            BezierPath(roundedRect: bounds, cornerRadius: 5).fill()

            // Get the context
            if let context = UIGraphicsGetCurrentContext() {

                // Prepare text attributes
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center

                let attributes: [NSAttributedStringKey: Any] = [
                    .font           : UIFont.systemFont(ofSize: fontSize, weight: .medium),
                    .paragraphStyle : paragraphStyle
                ]
                let textSize = (text as NSString).size(withAttributes: attributes)

                // Finding the rect to draw in, so the text is centered
                var drawingRect = bounds
                drawingRect.origin.y = bounds.height/2 - textSize.height/2
                drawingRect.size.height = textSize.height

                // Draw text
                context.saveGState()
                context.setBlendMode(.destinationOut)
                (text as NSString).draw(in: drawingRect, withAttributes: attributes)
                context.restoreGState()

            }
        }
    }

#endif


// -------------------------------
// MARK: Helpful Extensions
// -------------------------------

fileprivate extension Color {
    func vector() -> vector_float4 {
        #if os(iOS)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            getRed(&r, green: &g, blue: &b, alpha: &a)
            return [Float(r), Float(g), Float(b), Float(a)]
        #elseif os(OSX)
            let color = usingColorSpace(.deviceRGB)!
            return [
                Float(color.redComponent),
                Float(color.greenComponent),
                Float(color.blueComponent),
                Float(color.alphaComponent)
            ]
        #endif
    }
}


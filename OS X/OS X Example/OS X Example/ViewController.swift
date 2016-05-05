//
//  ViewController.swift
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

class ViewController: NSViewController {
    
    @IBOutlet weak var graph1: MOONGraphView!
    @IBOutlet weak var graph2: MOONGraphView!
    @IBOutlet weak var graph3: MOONGraphView!
    @IBOutlet weak var graph4: MOONGraphView!
    @IBOutlet weak var graph5: MOONGraphView!
    @IBOutlet weak var graph6: MOONGraphView!
    @IBOutlet weak var graph7: MOONGraphView!
    
    var displayLink: CVDisplayLink?
    var i = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        graph1.themeColor = .Gray
        graph1.title = "Dates"
        graph1.subtitle = "λ = 690nm"
        graph1.maxSamples = 50
        
        graph2.themeColor = .Red
        graph2.title = "Orange"
        graph2.subtitle = "λ = 590nm"
        graph2.graphDirection = .LeftToRight
        graph2.maxSamples = 500
        graph2.maxValue   = 8.0
        graph2.minValue   = -8.0
        
        graph3.themeColor = .Green
        graph3.title = "Kiwi"
        graph3.subtitle = "λ = 530nm"
        graph3.graphDirection = .LeftToRight
        graph3.maxSamples = 400
        graph3.maxValue   = 2.0
        graph3.minValue   = -2.0
        
        graph4.themeColor = .Yellow
        graph4.title = "Lemon"
        graph4.subtitle = "λ = 575nm"
        graph4.roundedCorners = false
        graph4.maxSamples = 400
        graph4.maxValue   = 2.0
        graph4.numberOfGraphs = 3
        
        graph5.themeColor = .Purple
        graph5.graphType = .Scatter
        graph5.title = "Aubergine"
        graph5.subtitle = "λ = 430nm"
        graph5.roundedCorners = false
        graph5.maxSamples = 200
        graph5.numberOfGraphs = 3
        
        graph6.themeColor = .Blue
        graph6.title = "Blueberry"
        graph6.subtitle = "λ = 460nm"
        graph6.maxSamples = 1000
        graph6.maxValue   = 5.0
        graph6.minValue   = -1.1
        
        graph7.themeColor = .Turquoise
        graph7.title = "Blue Grapes"
        graph7.subtitle = "λ = 480nm"
        graph7.maxSamples = 400
        graph7.maxValue = 6.0
        graph7.minValue = -6.0
        
        
        func displayLinkOutputCallback(
              displayLink       : CVDisplayLink,
            _ inNow             : UnsafePointer<CVTimeStamp>,
            _ inOutputTime      : UnsafePointer<CVTimeStamp>,
            _ flagsIn           : CVOptionFlags,
            _ flagsOut          : UnsafeMutablePointer<CVOptionFlags>,
            _ displayLinkContext: UnsafeMutablePointer<Void>) -> CVReturn
        {
            unsafeBitCast(displayLinkContext, ViewController.self).update()
            return kCVReturnSuccess
        }
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink, displayLinkOutputCallback, UnsafeMutablePointer<Void>(unsafeAddressOf(self)))
            CVDisplayLinkStart(displayLink)
        }
    }
    
    func squareForI(input: Double) -> Double {
        return (1...20).filter({$0 % 2 != 0}).reduce(0.0, combine: {$0 + sin(input * Double($1))})
    }
    
    func triangleForI(input: Double) -> Double {
        return (1...20).reduce(0.0, combine: {$0 + sin(input * Double($1))})
    }
    
    
    func update() {
        dispatch_async(dispatch_get_main_queue()) {
            let value = sin(self.i)
            
            self.graph1.addSamples(value)
            self.graph2.addSamples(self.triangleForI(self.i))
            self.graph3.addSamples(value + sin(self.i * 5) / 3.0)
            self.graph6.addSamples(value)
            self.graph7.addSamples(self.squareForI(self.i))
            self.graph4.addSamples(sin(self.i * 19) / 2.0 + sin(self.i * 21) / 2.0, cos(self.i), cos(self.i + M_PI))
            self.graph5.addSamples(value, sin(self.i + 2 * M_PI / 3), sin(self.i + 4 * M_PI / 3))
            
            self.i += 0.1
        }
    }
    
}

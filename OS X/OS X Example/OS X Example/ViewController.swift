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
    
    @IBOutlet weak var graph1: GraphView!
    @IBOutlet weak var graph2: GraphView!
    @IBOutlet weak var graph3: GraphView!
    @IBOutlet weak var graph4: GraphView!
    @IBOutlet weak var graph5: GraphView!
    @IBOutlet weak var graph6: GraphView!
    @IBOutlet weak var graph7: GraphView!
    
    var displayLink: CVDisplayLink?
    var i = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        graph1.themeColor = .Gray
        graph1.maxSamples = 50
        graph1.graphDirection = .RightToLeft
        graph1.title = "Dates"
        graph1.subTitle = "λ = 690nm"
        
        graph2.themeColor = .Orange
        graph2.maxSamples = 500
        graph2.maxValue   = 8.0
        graph2.minValue   = -8.0
        graph2.title = "Orange"
        graph2.subTitle = "λ = 590nm"
        graph2.graphDirection = .RightToLeft
        
        graph3.themeColor = .Green
        graph3.maxSamples = 200
        graph3.maxValue   = 2.0
        graph3.minValue   = -2.0
        graph3.graphDirection = .RightToLeft
        graph3.title = "Kiwi"
        graph3.subTitle = "λ = 530nm"
        
        graph4.themeColor = .Blue
        graph4.maxValue   = 5.0
        graph4.minValue   = -1.1
        graph4.maxSamples = 1000
        graph4.title = "Blueberry"
        graph4.subTitle = "λ = 460nm"
        graph4.graphDirection = .RightToLeft
        
        graph5.themeColor = .Turquoise
        graph5.maxSamples = 400
        graph5.maxValue = 6.0
        graph5.minValue = -6.0
        graph5.graphDirection = .RightToLeft
        graph5.title = "Blue Grapes"
        graph5.subTitle = "λ = 480nm"
        
        graph6.themeColor = .Yellow
        graph6.maxSamples = 250
        graph6.maxValue   = 2.0
        graph6.title = "Lemon"
        graph6.subTitle = "λ = 575nm"
        graph6.graphDirection = .RightToLeft
        graph6.numberOfGraphs = 3
        
        graph7.themeColor = .Purple
        graph7.graphDirection = .RightToLeft
        graph7.title = "Aubergine"
        graph7.subTitle = "λ = 430nm"
        graph7.numberOfGraphs = 3
        
        func displayLinkOutputCallback(
            displayLink: CVDisplayLink,
            _ inNow: UnsafePointer<CVTimeStamp>,
            _ inOutputTime: UnsafePointer<CVTimeStamp>,
            _ flagsIn: CVOptionFlags,
            _ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
            _ displayLinkContext: UnsafeMutablePointer<Void>) -> CVReturn
        {
            unsafeBitCast(displayLinkContext, ViewController.self).update()
            return kCVReturnSuccess
        }
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutablePointer<Void>(unsafeAddressOf(self)))
        CVDisplayLinkStart(displayLink!)
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
            self.graph4.addSamples(value)
            self.graph5.addSamples(self.squareForI(self.i))
            self.graph6.addSamples(sin(self.i * 19) / 2.0 + sin(self.i * 21) / 2.0, cos(self.i), cos(self.i + M_PI))
            self.graph7.addSamples(value, sin(self.i + 2 * M_PI / 3), sin(self.i + 4 * M_PI / 3))
            
            self.i += 0.1
        }
    }
    
}

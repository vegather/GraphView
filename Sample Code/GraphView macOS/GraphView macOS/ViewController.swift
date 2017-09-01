//
//  ViewController.swift
//  GraphView macOS
//
//  Created by Aurelius Prochazka on 8/31/17.
//  Copyright © 2017 Vegard Solheim Theriault. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var graph1: GraphView!
    @IBOutlet weak var graph2: GraphView!
    @IBOutlet weak var graph3: GraphView!
    @IBOutlet weak var graph4: GraphView!

    var displayLink: CVDisplayLink?
    var i: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        graph1.backgroundTint  = .red
        graph1.title           = "Orange"
        graph1.subtitle        = "λ = 590nm"
        graph1.capacity        = 500

        graph2.backgroundTint  = .green
        graph2.capacity        = 1200
        graph2.isAutoscaling   = false
        graph2.visibleRange    = (-18)...3
        graph2.title           = "Kiwi"
        graph2.subtitle        = "λ = 530nm"

        graph3.backgroundTint  = .blue
        graph3.capacity        = 1000
        graph3.title           = "Blueberry"
        graph3.subtitle        = "λ = 460nm"

        graph4.backgroundTint  = .yellow
        graph4.capacity        = 1400
        graph4.title           = "Lemon"
        graph4.subtitle        = "λ = 575nm"
        graph4.sampleSize      = .large

        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {
            (displayLink: CVDisplayLink,
            inNow: UnsafePointer<CVTimeStamp>,
            inOutputTime: UnsafePointer<CVTimeStamp>,
            flagsIn: CVOptionFlags,
            flagsOut: UnsafeMutablePointer<CVOptionFlags>,
            displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in

            unsafeBitCast(displayLinkContext, to: ViewController.self).update()
            return kCVReturnSuccess
        }

        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink,
                                           displayLinkOutputCallback,
                                           UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque()))
            CVDisplayLinkStart(displayLink)
        }
    }

    func square(for input: Float) -> Float {
        return stride(from: 1, to: 30, by: 2).reduce(0) { $0 + (1/$1) * sin($1 * input) }
    }

    func sawtooth(for input: Float) -> Float {
        return stride(from: 1, to: 15, by: 1).reduce(0) { $0 + (1/$1) * sin($1 * input) }
    }

    @objc func update() {

        DispatchQueue.main.async {
            let sineValue = sin(self.i)

            self.graph1.add(sample: self.sawtooth(for: self.i))
            self.graph2.add(sample: sineValue + sin(self.i * 5) / 3.0)
            self.graph3.add(sample: sineValue)
            self.graph4.add(sample: self.square(for: self.i))
        }
        i += 0.05
    }
}


//
//  ViewController.swift
//  GraphView iOS
//
//  Created by Vegard Solheim Theriault on 29/08/2017.
//  Copyright © 2017 Vegard Solheim Theriault. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var graph1: GraphView!
    @IBOutlet weak var graph2: GraphView!
    @IBOutlet weak var graph3: GraphView!
    @IBOutlet weak var graph4: GraphView!
    
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
        graph3.gesturesEnabled = false
        graph3.title           = "Blueberry"
        graph3.subtitle        = "λ = 460nm"
        
        graph4.backgroundTint  = .yellow
        graph4.capacity        = 1400
        graph4.title           = "Lemon"
        graph4.subtitle        = "λ = 575nm"
        graph4.sampleSize      = .large
        
        let updater = CADisplayLink(target: self, selector: #selector(update))
        updater.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
        updater.add(to: RunLoop.current, forMode: .UITrackingRunLoopMode) // Makes sure update is called while scrolling
    }
    
    func square(for input: Float) -> Float {
        return stride(from: 1, to: 30, by: 2).reduce(0) { $0 + (1/$1) * sin($1 * input) }
    }
    
    func sawtooth(for input: Float) -> Float {
        return stride(from: 1, to: 15, by: 1).reduce(0) { $0 + (1/$1) * sin($1 * input) }
    }
    
    @objc func update() {
        let sineValue = sin(i)
        
        graph1.add(sample: sawtooth(for: i))
        graph2.add(sample: sineValue + sin(i * 5) / 3.0)
        graph3.add(sample: sineValue)
        graph4.add(sample: square(for: i))
        
        i += 0.05
    }

}


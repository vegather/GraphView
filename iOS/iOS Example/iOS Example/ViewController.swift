//
//  ViewController.swift
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

class ViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    var graphs = [MOONGraphView]()
    var i = 0.0
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let graphHeight: CGFloat = 150.0
        var currentY: CGFloat = 20.0
        let separator: CGFloat = 8.0
        
        let graph1 = MOONGraphView(frame: CGRect(x: 0.0, y: currentY, width: scrollView.bounds.width, height: graphHeight))
        graph1.themeColor = .Gray
        graph1.maxSamples = 50
        graph1.title = "Dates"
        graph1.subTitle = "λ = 690nm"
        graph1.graphDirection = .LeftToRight
        graph1.roundedCorners = false
        graph1.graphType = .Scatter
        scrollView.addSubview(graph1)
        graphs.append(graph1)
        
        currentY += graphHeight + separator
        
        let graph2 = MOONGraphView(frame: CGRect(x: 0.0, y: currentY, width: scrollView.bounds.width, height: graphHeight))
        graph2.themeColor = .Red
        graph2.maxSamples = 330
        graph2.maxValue   = 4.0
        graph2.minValue   = -4.0
        graph2.title      = "Orange"
        graph2.subTitle   = "λ = 590nm"
        graph2.roundedCorners = false
        graph2.graphType = .Scatter
        scrollView.addSubview(graph2)
        graphs.append(graph2)
        
        currentY += graphHeight + separator
        
        let graph3 = MOONGraphView(frame: CGRect(x: 0.0, y: currentY, width: scrollView.bounds.width, height: graphHeight))
        graph3.themeColor = .Green
        graph3.maxSamples = 200
        graph3.maxValue   = 2.0
        graph3.minValue   = -2.0
        graph3.title = "Kiwi"
        graph3.subTitle = "λ = 530nm"
        graph3.roundedCorners = false
        scrollView.addSubview(graph3)
        graphs.append(graph3)
        
        currentY += graphHeight + separator
        
        let graph4 = MOONGraphView(frame: CGRect(x: 0.0, y: currentY, width: scrollView.bounds.width, height: graphHeight))
        graph4.themeColor = .Blue
        graph4.maxValue   = 5.0
        graph4.minValue   = -1.1
        graph4.maxSamples = 1000
        graph4.title = "Blueberry"
        graph4.subTitle = "λ = 460nm"
        graph4.roundedCorners = false
        scrollView.addSubview(graph4)
        graphs.append(graph4)
        
        currentY += graphHeight + separator
        
        let graph5 = MOONGraphView(frame: CGRect(x: 0.0, y: currentY, width: scrollView.bounds.width, height: graphHeight))
        graph5.themeColor = .Turquoise
        graph5.maxSamples = 280
        graph5.maxValue = 6.0
        graph5.minValue = -6.0
        graph5.title = "Blue Grapes"
        graph5.subTitle = "λ = 480nm"
        graph5.roundedCorners = false
        scrollView.addSubview(graph5)
        graphs.append(graph5)
        
        currentY += graphHeight + separator
        
        let graph6 = MOONGraphView(frame: CGRect(x: 0.0, y: currentY, width: scrollView.bounds.width, height: graphHeight))
        graph6.themeColor = .Yellow
        graph6.maxSamples = 300
        graph6.maxValue   = 2.0
        graph6.title = "Lemon"
        graph6.subTitle = "λ = 575nm"
        graph6.numberOfGraphs = 3
        graph6.roundedCorners = false
        scrollView.addSubview(graph6)
        graphs.append(graph6)
        
        currentY += graphHeight + separator
        
        let graph7 = MOONGraphView(frame: CGRect(x: 0.0, y: currentY, width: scrollView.bounds.width, height: graphHeight))
        graph7.themeColor = .Purple
        graph7.title = "Aubergine"
        graph7.subTitle = "λ = 430nm"
        graph7.numberOfGraphs = 3
        graph7.roundedCorners = false
        graph7.graphType = .Scatter
        scrollView.addSubview(graph7)
        graphs.append(graph7)
        
        scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: currentY + graphHeight)
        
        let updater = CADisplayLink(target: self, selector: #selector(update))
        updater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        updater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: UITrackingRunLoopMode) // Makes sure update is called while scrolling
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for i in 0..<graphs.count {
            graphs[i].frame = CGRect(
                x: graphs[i].frame.origin.x,
                y: graphs[i].frame.origin.y,
                width: scrollView.bounds.width,
                height: graphs[i].frame.size.height)
        }
    }
    
    func squareForI(input: Double) -> Double {
        return (1...15).filter({$0 % 2 != 0}).reduce(0.0, combine: {$0 + sin(input * Double($1))})
    }
    
    func triangleForI(input: Double) -> Double {
        return (1...15).reduce(0.0, combine: {$0 + sin(input * Double($1))})
    }
    
    func update() {
        let sineValue = sin(i)
        
        graphs[0].addSamples(sineValue)
        graphs[1].addSamples(triangleForI(i))
        graphs[2].addSamples(sineValue + sin(i * 5) / 3.0)
        graphs[3].addSamples(sineValue)
        graphs[4].addSamples(squareForI(i))
        graphs[5].addSamples(sin(i * 19) / 2.0 + sin(i * 21) / 2.0, cos(i), cos(i + M_PI))
        graphs[6].addSamples(sineValue, sin(i + 2 * M_PI / 3), sin(i + 4 * M_PI / 3))
        
        self.i += 0.1
    }
}


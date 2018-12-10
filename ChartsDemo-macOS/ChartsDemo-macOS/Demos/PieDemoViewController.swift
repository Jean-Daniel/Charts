//
//  PieDemoViewController.swift
//  ChartsDemo-OSX
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts

import Foundation
import Cocoa
import Charts

open class PieDemoViewController: NSViewController
{
    @IBOutlet var pieChartView: PieChartView!
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let ys1 = Array(1..<10).map { x in return sin(Double(x) / 2.0 / 3.141 * 1.5) * 100.0 }
        
        let yse1 = ys1.enumerated().map { (x, y) in return ChartDataEntry(value: y, label: String(x)) }
        
        let data = ChartData(label: "Hello", values: yse1)
        
        data.colors = ChartColorTemplates.vordiplom() + ChartColorTemplates.liberty()
//      pieChartView.holeColor = NSColor.windowBackgroundColor
//      pieChartView.transparentCircleColor = NSColor.windowBackgroundColor.withAlphaComponent(0.5)
      pieChartView.rotationWithTwoFingers = true
      pieChartView.usesPercentValues = true
      pieChartView.drawsHole = false
      // pieChartView.rotationEnabled = false

        let paragraphStyle: NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        let centerText: NSMutableAttributedString = NSMutableAttributedString(string: "Charts\nby Daniel Cohen Gindi")
      let fontdesc = NSFont.labelFont(ofSize: 15).fontDescriptor.withSymbolicTraits(.italic)
        centerText.setAttributes([.font: NSFont.labelFont(ofSize: 15), .foregroundColor: NSColor.labelColor, .paragraphStyle: paragraphStyle], range: NSMakeRange(0, centerText.length))
        centerText.addAttributes([.font: NSFont.labelFont(ofSize: 13), .foregroundColor: NSColor.labelColor], range: NSMakeRange(10, centerText.length - 10))
        centerText.addAttributes([.font: NSFont(descriptor: fontdesc, size: 13)!, .foregroundColor: NSColor.controlAccentColor], range: NSMakeRange(centerText.length - 19, 19))
        
        self.pieChartView.centerAttributedText = centerText
        
        self.pieChartView.data = data
        
        self.pieChartView.chartDescription.text = "Piechart Demo"
    }
    
    override open func viewWillAppear()
    {
      self.pieChartView.animate(duration: 1.0, easing: .easeOutSine)
    }
}

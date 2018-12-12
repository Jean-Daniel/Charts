//
//  PieChartViewController.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

import UIKit
import Charts

class PieChartViewController: DemoBaseViewController {

    @IBOutlet var chartView: PieChartView!
    @IBOutlet var sliderX: UISlider!
    @IBOutlet var sliderY: UISlider!
    @IBOutlet var sliderTextX: UITextField!
    @IBOutlet var sliderTextY: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Pie Chart"
        
        self.options = [.toggleValues,
                        .toggleXValues,
                        .togglePercent, 
                        .toggleHole,
                        .animate,
                        .spin,
                        .drawCenter,
                        .saveToGallery,
                        .toggleData]
        
        self.setup(pieChartView: chartView)
        
        chartView.delegate = self
        
        let l = chartView.legend
        l.horizontalAlignment = .right
        l.verticalAlignment = .top
        l.orientation = .vertical
        l.xEntrySpace = 7
        l.yEntrySpace = 0
        l.yOffset = 0
//        chartView.legend = l

        // entry label styling
        chartView.entryLabelColor = .white
        chartView.entryLabelFont = .systemFont(ofSize: 12, weight: .light)
        
        sliderX.value = 4
        sliderY.value = 100
        self.slidersValueChanged(nil)
        
        chartView.animate(duration: 1.4, easing: .easeOutBack)
    }
    
    override func updateChartData() {
        if self.shouldHideData {
            chartView.data = nil
            return
        }
        
        self.setDataCount(Int(sliderX.value), range: UInt32(sliderY.value))
    }
    
    func setDataCount(_ count: Int, range: UInt32) {
        let entries = (0..<count).map { (i) -> ChartDataEntry in
            // IMPORTANT: In a PieChart, no values (Entry) should have the same xIndex (even if from different DataSets), since no values can be drawn above each other.
            return ChartDataEntry(value: Double(arc4random_uniform(range) + range / 5), label: parties[i % parties.count])
        }
        
        let data = ChartData(label: "Election Results", values: entries)
        data.sliceSpace = 2
        
        data.colors = ChartColorTemplates.vordiplom()
            + ChartColorTemplates.joyful()
            + ChartColorTemplates.colorful()
            + ChartColorTemplates.liberty()
            + ChartColorTemplates.pastel()
            + [UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)]

        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.valueFormatter = DefaultValueFormatter(formatter: pFormatter)
        
        data.valueFont = .systemFont(ofSize: 11, weight: .light)
        data.valueColors = [.white]
        
        chartView.data = data
        chartView.highlightValue(nil)
    }
    
    override func optionTapped(_ option: Option) {
        switch option {
        case .toggleXValues:
            chartView.drawsEntryLabels.toggle()
            chartView.setNeedsDisplay()
            
        case .togglePercent:
            chartView.usesPercentValues.toggle()
            chartView.setNeedsDisplay()
            
        case .toggleHole:
            chartView.drawsHole.toggle()
            chartView.setNeedsDisplay()
            
        case .drawCenter:
            chartView.drawsCenterText.toggle()
            chartView.setNeedsDisplay()
            
        case .animate:
            chartView.animate(duration: 1.4)

        case .spin:
            chartView.spin(duration: 2,
                           fromAngle: chartView.rotationAngle,
                           toAngle: chartView.rotationAngle + 360,
                           easingOption: .easeInCubic)
            
        default:
            handleOption(option, forChartView: chartView)
        }
    }
    
    // MARK: - Actions
    @IBAction func slidersValueChanged(_ sender: Any?) {
        sliderTextX.text = "\(Int(sliderX.value))"
        sliderTextY.text = "\(Int(sliderY.value))"
        
        self.updateChartData()
    }
}

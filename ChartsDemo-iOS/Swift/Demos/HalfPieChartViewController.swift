//
//  HalfPieChartViewController.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

import UIKit
import Charts

class HalfPieChartViewController: DemoBaseViewController {

  @IBOutlet var chartView: PieChartView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    self.title = "Half Pie Chart"

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

    chartView.holeColor = .white
    chartView.transparentCircleColor = NSUIColor.white.withAlphaComponent(0.43)
    chartView.holeRadiusPercent = 58
    chartView.rotationEnabled = false
    chartView.highlightsPerTap = true

    chartView.maxAngle = 180 // Half chart
    chartView.rotationAngle = 180 // Rotate to make the half on the upper side
    chartView.centerTextOffset = CGPoint(x: 0, y: -20)

    let l = chartView.legend
    l.horizontalAlignment = .center
    l.verticalAlignment = .top
    l.orientation = .horizontal
    l.drawInside = false
    l.xEntrySpace = 7
    l.yEntrySpace = 0
    l.yOffset = 0
    //        chartView.legend = l

    // entry label styling
    chartView.entryLabelColor = .white
    chartView.entryLabelFont = UIFont(name:"HelveticaNeue-Light", size:12)!

    self.updateChartData()

    chartView.animate(duration: 1.4, easing: .easeOutBack)
  }

  override func updateChartData() {
    if self.shouldHideData {
      chartView.data = nil
      return
    }

    self.setDataCount(4, range: 100)
  }

  func setDataCount(_ count: Int, range: UInt32) {
    let entries = (0..<count).map { (i) -> ChartDataEntry in
      // IMPORTANT: In a PieChart, no values (Entry) should have the same xIndex (even if from different DataSets), since no values can be drawn above each other.
      return ChartDataEntry(value: Double(arc4random_uniform(range) + range / 5), label: parties[i % parties.count])
    }

    let data = ChartData(label: "Election Results", values: entries)
    data.sliceSpace = 3
    data.selectionShift = 5
    data.colors = ChartColorTemplates.material()

    let pFormatter = NumberFormatter()
    pFormatter.numberStyle = .percent
    pFormatter.maximumFractionDigits = 1
    pFormatter.multiplier = 1
    pFormatter.percentSymbol = " %"
    data.valueFormatter = DefaultValueFormatter(formatter: pFormatter)
    
    data.valueFont = UIFont(name: "HelveticaNeue-Light", size: 11)!
    data.valueColors = [.white]

    chartView.data = data
    chartView.highlightValue(nil)
  }

  override func optionTapped(_ option: Option) {
    switch option {
    case .toggleXValues:
      chartView.drawsEntryLabels.toggle()

    case .togglePercent:
      chartView.usesPercentValues.toggle()

    case .toggleHole:
      chartView.drawsHole.toggle()

    case .drawCenter:
      chartView.drawsCenterText.toggle()

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
}

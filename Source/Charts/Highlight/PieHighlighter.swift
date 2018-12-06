//
//  PieHighlighter.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

class PieHighlighter
{

  open weak var chart: ChartDataProvider?

  public init(chart: ChartDataProvider)
  {
    self.chart = chart
  }

  /// - Parameters:
  ///   - x:
  ///   - y:
  /// - Returns: A Highlight object corresponding to the given x- and y- touch positions in pixels.
  func getHighlight(x: CGFloat, y: CGFloat) -> Highlight?
  {
    guard let chart = self.chart as? PieChartView else { return nil }
    
    let touchDistanceToCenter = chart.distanceToCenter(x: x, y: y)
    
    // check if a slice was touched
    guard touchDistanceToCenter <= chart.radius else
    {
      // if no slice was touched, highlight nothing
      return nil
    }
    
    var angle = chart.angleForPoint(x: x ,y: y)
    
    angle /= CGFloat(chart.chartAnimator.phaseY)
    
    let index = chart.indexForAngle(angle)
    
    // check if the index could be found
    if index < 0 || index >= chart.data?.maxEntryCountSet?.entryCount ?? 0
    {
      return nil
    }
    else
    {
      return closestHighlight(index: index, x: x, y: y)
    }
    
  }
  
  private func closestHighlight(index: Int, x: CGFloat, y: CGFloat) -> Highlight?
  {
    guard
      let set = chart?.data?.dataSets[0],
      let entry = set.entryForIndex(index)
      else { return nil }
    
    return Highlight(x: Double(index), y: entry.y, xPx: x, yPx: y, dataSetIndex: 0, axis: set.axisDependency)
  }
}

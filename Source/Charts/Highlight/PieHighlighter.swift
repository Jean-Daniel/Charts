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

  public weak var chart: PieChartView?

  public init(chart: PieChartView)
  {
    self.chart = chart
  }

  /// - Parameters:
  ///   - x:
  ///   - y:
  /// - Returns: A Highlight object corresponding to the given x- and y- touch positions in pixels.
  func getHighlight(x: CGFloat, y: CGFloat) -> Highlight?
  {
    guard let chart = self.chart else { return nil }
    
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
    if index < 0 || index >= chart.data?.entryCount ?? 0
    {
      return nil
    }
    else
    {
      return Highlight(value: index)
    }
    
  }
  
}

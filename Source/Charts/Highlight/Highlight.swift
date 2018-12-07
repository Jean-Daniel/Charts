//
//  Highlight.swift
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

public struct Highlight
{
  /// the x-value of the highlighted value
  fileprivate var _x = Double.nan

  /// the y-value of the highlighted value
  fileprivate var _y = Double.nan

  /// the x-pixel of the highlight
  private var _xPx = CGFloat.nan

  /// the y-pixel of the highlight
  private var _yPx = CGFloat.nan

  /// the index of the dataset the highlighted value is in
  fileprivate var _dataSetIndex = Int(0)

  /// - Parameters:
  ///   - x: the x-value of the highlighted value
  ///   - y: the y-value of the highlighted value
  ///   - xPx: the x-pixel of the highlighted value
  ///   - yPx: the y-pixel of the highlighted value
  ///   - dataIndex: the index of the Data the highlighted value belongs to
  ///   - dataSetIndex: the index of the DataSet the highlighted value belongs to
  ///   - stackIndex: references which value of a stacked-bar entry has been selected
  ///   - axis: the axis the highlighted value belongs to
  init(
    x: Double, y: Double,
    xPx: CGFloat, yPx: CGFloat,
    dataSetIndex: Int)
  {
    _x = x
    _y = y
    _xPx = xPx
    _yPx = yPx
    _dataSetIndex = dataSetIndex
  }

  /// - Parameters:
  ///   - x: the x-value of the highlighted value
  ///   - y: the y-value of the highlighted value
  ///   - dataSetIndex: the index of the DataSet the highlighted value belongs to
  ///   - dataIndex: The data index to search in (only used in CombinedChartView currently)
  init(x: Double, y: Double, dataSetIndex: Int)
  {
    _x = x
    _y = y
    _dataSetIndex = dataSetIndex
  }

  var x: Double { return _x }
  var y: Double { return _y }
  var xPx: CGFloat { return _xPx }
  var yPx: CGFloat { return _yPx }
  var dataSetIndex: Int { return _dataSetIndex }
}

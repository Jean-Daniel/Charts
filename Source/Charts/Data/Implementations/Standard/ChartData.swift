//
//  ChartData.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

public class ChartData
{
  private var _yMax: Double = -Double.greatestFiniteMagnitude
  private var _yMin: Double = Double.greatestFiniteMagnitude
  private var _leftAxisMax: Double = -Double.greatestFiniteMagnitude
  private var _leftAxisMin: Double = Double.greatestFiniteMagnitude

  var dataSet : ChartDataSet? {
    didSet {
      notifyDataChanged()
    }
  }

  public convenience init() {
    self.init(dataSet: nil)
  }

  public init(dataSet: ChartDataSet?)
  {
    self.dataSet = dataSet

    notifyDataChanged()
  }

  /// Call this method to let the ChartData know that the underlying data has changed.
  /// Calling this performs all necessary recalculations needed when the contained data has changed.
  private func notifyDataChanged()
  {
    calcMinMax()
  }

  /// calc minimum and maximum y value over all datasets
  private func calcMinMax()
  {
    _yMax = -Double.greatestFiniteMagnitude
    _yMin = Double.greatestFiniteMagnitude

    if let dataSet = dataSet
    {
      calcMinMax(dataSet: dataSet)
    }

    _leftAxisMax = -Double.greatestFiniteMagnitude
    _leftAxisMin = Double.greatestFiniteMagnitude

    // left axis

    if let dataSet = dataSet
    {
      _leftAxisMax = dataSet.yMax
      _leftAxisMin = dataSet.yMin

      if dataSet.yMin < _leftAxisMin
      {
        _leftAxisMin = dataSet.yMin
      }

      if dataSet.yMax > _leftAxisMax
      {
        _leftAxisMax = dataSet.yMax
      }
    }
  }

  /// Adjusts the minimum and maximum values based on the given DataSet.
  private func calcMinMax(dataSet d: ChartDataSet)
  {
    if _yMax < d.yMax
    {
      _yMax = d.yMax
    }

    if _yMin > d.yMin
    {
      _yMin = d.yMin
    }

    if _leftAxisMax < d.yMax
    {
      _leftAxisMax = d.yMax
    }

    if _leftAxisMin > d.yMin
    {
      _leftAxisMin = d.yMin
    }
  }

  /// The smallest y-value the data object contains.
  public var yMin: Double
  {
    return _yMin
  }

  /// The greatest y-value the data object contains.
  public var yMax: Double
  {
    return _yMax
  }

  /// Get the Entry for a corresponding highlight object
  ///
  /// - Parameters:
  ///   - highlight:
  /// - Returns: The entry that is highlighted
  public func entryForHighlight(_ highlight: Highlight) -> ChartDataEntry?
  {
    return dataSet?.entryForIndex(highlight.value)
  }

  /// The total entry count across all DataSet objects this data object contains.
  public var entryCount: Int
  {
    return dataSet?.entryCount ?? 0
  }

  // MARK: - Accessibility

  /// When the data entry labels are generated identifiers, set this property to prepend a string before each identifier
  ///
  /// For example, if a label is "#3", settings this property to "Item" allows it to be spoken as "Item #3"
  public var accessibilityEntryLabelPrefix: String?

  /// When the data entry value requires a unit, use this property to append the string representation of the unit to the value
  ///
  /// For example, if a value is "44.1", setting this property to "m" allows it to be spoken as "44.1 m"
  public var accessibilityEntryLabelSuffix: String?

  /// If the data entry value is a count, set this to true to allow plurals and other grammatical changes
  /// **default**: false
  public var accessibilityEntryLabelSuffixIsCount: Bool = false

  // MARK: -
  // MARk: Pie Chart
  /// All DataSet objects this ChartData object holds.

  /// The total y-value sum across all DataSet objects the this object represents.
  public var yValueSum: Double
  {
    guard let dataSet = dataSet else { return 0.0 }

    var yValueSum: Double = 0.0

    for i in 0..<dataSet.entryCount
    {
      yValueSum += dataSet.entryForIndex(i)?.value ?? 0.0
    }

    return yValueSum
  }
}

extension ChartData : Equatable {
  public static func == (lhs: ChartData, rhs: ChartData) -> Bool {
    return lhs === rhs
  }
  
}

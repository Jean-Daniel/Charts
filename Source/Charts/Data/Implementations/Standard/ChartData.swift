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
  internal var _yMax: Double = -Double.greatestFiniteMagnitude
  internal var _yMin: Double = Double.greatestFiniteMagnitude
  internal var _leftAxisMax: Double = -Double.greatestFiniteMagnitude
  internal var _leftAxisMin: Double = Double.greatestFiniteMagnitude
  
  internal var _dataSets = [IChartDataSet]()
  
  public init(dataSets: [IChartDataSet]? = nil)
  {
    _dataSets = dataSets ?? [IChartDataSet]()
    
    self.initialize(dataSets: _dataSets)
  }
  
  public convenience init(dataSet: IChartDataSet?)
  {
    self.init(dataSets: dataSet.map { [$0] })
  }
  
  internal func initialize(dataSets: [IChartDataSet])
  {
    notifyDataChanged()
  }
  
  /// Call this method to let the ChartData know that the underlying data has changed.
  /// Calling this performs all necessary recalculations needed when the contained data has changed.
  public func notifyDataChanged()
  {
    calcMinMax()
  }
  
  public func calcMinMaxY(fromX: Double, toX: Double)
  {
    for set in _dataSets
    {
      set.calcMinMaxY(fromX: fromX, toX: toX)
    }
    
    // apply the new data
    calcMinMax()
  }
  
  /// calc minimum and maximum y value over all datasets
  public func calcMinMax()
  {
    _yMax = -Double.greatestFiniteMagnitude
    _yMin = Double.greatestFiniteMagnitude
    
    for set in _dataSets
    {
      calcMinMax(dataSet: set)
    }
    
    _leftAxisMax = -Double.greatestFiniteMagnitude
    _leftAxisMin = Double.greatestFiniteMagnitude
    
    // left axis
    
    if let firstLeft = getFirstLeft(dataSets: dataSets)
    {
      _leftAxisMax = firstLeft.yMax
      _leftAxisMin = firstLeft.yMin
      
      for dataSet in _dataSets
      {
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
  }
  
  /// Adjusts the current minimum and maximum values based on the provided Entry object.
  public func calcMinMax(entry e: ChartDataEntry)
  {
    if _yMax < e.value
    {
      _yMax = e.value
    }
    
    if _yMin > e.value
    {
      _yMin = e.value
    }

    if _leftAxisMax < e.value
    {
      _leftAxisMax = e.value
    }
    
    if _leftAxisMin > e.value
    {
      _leftAxisMin = e.value
    }
  }
  
  /// Adjusts the minimum and maximum values based on the given DataSet.
  public func calcMinMax(dataSet d: IChartDataSet)
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
  
  /// The number of LineDataSets this object contains
  public var dataSetCount: Int
  {
    return _dataSets.count
  }
  
  /// The smallest y-value the data object contains.
  public var yMin: Double
  {
    return _yMin
  }
  
  @nonobjc
  public func getYMin() -> Double
  {
    return _yMin
  }
  
  /// The greatest y-value the data object contains.
  public var yMax: Double
  {
    return _yMax
  }
  
  @nonobjc
  public func getYMax() -> Double
  {
    return _yMax
  }
  
  /// All DataSet objects this ChartData object holds.
  public var dataSets: [IChartDataSet]
    {
    get
    {
      return _dataSets
    }
    set
    {
      _dataSets = newValue
      notifyDataChanged()
    }
  }
  
  /// Retrieve the index of a ChartDataSet with a specific label from the ChartData. Search can be case sensitive or not.
  ///
  /// **IMPORTANT: This method does calculations at runtime, do not over-use in performance critical situations.**
  ///
  /// - Parameters:
  ///   - dataSets: the DataSet array to search
  ///   - type:
  ///   - ignorecase: if true, the search is not case-sensitive
  /// - Returns: The index of the DataSet Object with the given label. Sensitive or not.
  internal func getDataSetIndexByLabel(_ label: String, ignorecase: Bool) -> Int
  {
    if ignorecase
    {
      for i in 0 ..< dataSets.count
      {
        if dataSets[i].label == nil
        {
          continue
        }
        if (label.caseInsensitiveCompare(dataSets[i].label!) == ComparisonResult.orderedSame)
        {
          return i
        }
      }
    }
    else
    {
      for i in 0 ..< dataSets.count
      {
        if label == dataSets[i].label
        {
          return i
        }
      }
    }
    
    return -1
  }
  
  /// - Returns: The labels of all DataSets as a string array.
  internal func dataSetLabels() -> [String]
  {
    var types = [String]()
    
    for i in 0 ..< _dataSets.count
    {
      if dataSets[i].label == nil
      {
        continue
      }
      
      types[i] = _dataSets[i].label!
    }
    
    return types
  }
  
  /// Get the Entry for a corresponding highlight object
  ///
  /// - Parameters:
  ///   - highlight:
  /// - Returns: The entry that is highlighted
  public func entryForHighlight(_ highlight: Highlight) -> ChartDataEntry?
  {
    if highlight.dataSetIndex >= dataSets.count
    {
      return nil
    }
    else
    {
      return dataSets[highlight.dataSetIndex].entryForXValue(highlight.x, closestToY: highlight.y)
    }
  }
  
  /// **IMPORTANT: This method does calculations at runtime. Use with care in performance critical situations.**
  ///
  /// - Parameters:
  ///   - label:
  ///   - ignorecase:
  /// - Returns: The DataSet Object with the given label. Sensitive or not.
  public func getDataSetByLabel(_ label: String, ignorecase: Bool) -> IChartDataSet?
  {
    let index = getDataSetIndexByLabel(label, ignorecase: ignorecase)
    
    if index < 0 || index >= _dataSets.count
    {
      return nil
    }
    else
    {
      return _dataSets[index]
    }
  }
  
  public func getDataSetByIndex(_ index: Int) -> IChartDataSet!
  {
    if index < 0 || index >= _dataSets.count
    {
      return nil
    }
    
    return _dataSets[index]
  }
  
  public func addDataSet(_ dataSet: IChartDataSet!)
  {
    calcMinMax(dataSet: dataSet)
    
    _dataSets.append(dataSet)
  }
  
  /// Removes the given DataSet from this data object.
  /// Also recalculates all minimum and maximum values.
  ///
  /// - Returns: `true` if a DataSet was removed, `false` ifno DataSet could be removed.
  @discardableResult public func removeDataSet(_ dataSet: IChartDataSet!) -> Bool
  {
    if dataSet == nil
    {
      return false
    }
    
    for i in 0 ..< _dataSets.count
    {
      if _dataSets[i] === dataSet
      {
        return removeDataSetByIndex(i)
      }
    }
    
    return false
  }
  
  /// Removes the DataSet at the given index in the DataSet array from the data object.
  /// Also recalculates all minimum and maximum values.
  ///
  /// - Returns: `true` if a DataSet was removed, `false` ifno DataSet could be removed.
  @discardableResult public func removeDataSetByIndex(_ index: Int) -> Bool
  {
    if index >= _dataSets.count || index < 0
    {
      return false
    }
    
    _dataSets.remove(at: index)
    
    calcMinMax()
    
    return true
  }
  
  /// Adds an Entry to the DataSet at the specified index. Entries are added to the end of the list.
  public func addEntry(_ e: ChartDataEntry, dataSetIndex: Int)
  {
    if _dataSets.count > dataSetIndex && dataSetIndex >= 0
    {
      let set = _dataSets[dataSetIndex]
      
      if !set.addEntry(e) { return }
      
      calcMinMax(entry: e)
    }
    else
    {
      print("ChartData.addEntry() - Cannot add Entry because dataSetIndex too high or too low.", terminator: "\n")
    }
  }
  
  /// Removes the given Entry object from the DataSet at the specified index.
  @discardableResult public func removeEntry(_ entry: ChartDataEntry, dataSetIndex: Int) -> Bool
  {
    // entry outofbounds
    if dataSetIndex >= _dataSets.count
    {
      return false
    }
    
    // remove the entry from the dataset
    let removed = _dataSets[dataSetIndex].removeEntry(entry)
    
    if removed
    {
      calcMinMax()
    }
    
    return removed
  }
  
  /// Removes the Entry object closest to the given xIndex from the ChartDataSet at the
  /// specified index.
  ///
  /// - Returns: `true` if an entry was removed, `false` ifno Entry was found that meets the specified requirements.
  @discardableResult public func removeEntry(xValue: Double, dataSetIndex: Int) -> Bool
  {
    if dataSetIndex >= _dataSets.count
    {
      return false
    }
    
    if let entry = _dataSets[dataSetIndex].entryForXValue(xValue, closestToY: Double.nan)
    {
      return removeEntry(entry, dataSetIndex: dataSetIndex)
    }
    
    return false
  }
  
  /// - Returns: The DataSet that contains the provided Entry, or null, if no DataSet contains this entry.
  public func getDataSetForEntry(_ e: ChartDataEntry!) -> IChartDataSet?
  {
    if e == nil
    {
      return nil
    }
    
    for i in 0 ..< _dataSets.count
    {
      let set = _dataSets[i]
      
      if e === set.entryForXValue(0.0, closestToY: e.value)
      {
        return set
      }
    }
    
    return nil
  }
  
  /// - Returns: The index of the provided DataSet in the DataSet array of this data object, or -1 if it does not exist.
  public func indexOfDataSet(_ dataSet: IChartDataSet) -> Int
  {
    for i in 0 ..< _dataSets.count
    {
      if _dataSets[i] === dataSet
      {
        return i
      }
    }
    
    return -1
  }
  
  /// - Returns: The first DataSet from the datasets-array that has it's dependency on the left axis. Returns null if no DataSet with left dependency could be found.
  public func getFirstLeft(dataSets: [IChartDataSet]) -> IChartDataSet?
  {
    return dataSets.first
  }
  
  /// - Returns: All colors used across all DataSet objects this object represents.
  public func getColors() -> [NSUIColor]?
  {
    var clrcnt = 0
    
    for i in 0 ..< _dataSets.count
    {
      clrcnt += _dataSets[i].colors.count
    }
    
    var colors = [NSUIColor]()
    
    for i in 0 ..< _dataSets.count
    {
      let clrs = _dataSets[i].colors
      
      for clr in clrs
      {
        colors.append(clr)
      }
    }
    
    return colors
  }
  
  /// Sets a custom ValueFormatter for all DataSets this data object contains.
  public func setValueFormatter(_ formatter: ValueFormatter?)
  {
    guard let formatter = formatter
      else { return }
    
    for set in dataSets
    {
      set.valueFormatter = formatter
    }
  }
  
  /// Sets the color of the value-text (color in which the value-labels are drawn) for all DataSets this data object contains.
  public func setValueTextColor(_ color: NSUIColor!)
  {
    for set in dataSets
    {
      set.valueTextColor = color ?? set.valueTextColor
    }
  }
  
  /// Sets the font for all value-labels for all DataSets this data object contains.
  public func setValueFont(_ font: NSUIFont!)
  {
    for set in dataSets
    {
      set.valueFont = font ?? set.valueFont
    }
  }
  
  /// Enables / disables drawing values (value-text) for all DataSets this data object contains.
  public func setDrawValues(_ enabled: Bool)
  {
    for set in dataSets
    {
      set.drawValuesEnabled = enabled
    }
  }
  
  /// Enables / disables highlighting values for all DataSets this data object contains.
  /// If set to true, this means that values can be highlighted programmatically or by touch gesture.
  public var highlightEnabled: Bool
    {
    get
    {
      for set in dataSets
      {
        if !set.highlightEnabled
        {
          return false
        }
      }
      
      return true
    }
    set
    {
      for set in dataSets
      {
        set.highlightEnabled = newValue
      }
    }
  }
  
  /// if true, value highlightning is enabled
  public var isHighlightEnabled: Bool { return highlightEnabled }
  
  /// Clears this data object from all DataSets and removes all Entries.
  /// Don't forget to invalidate the chart after this.
  public func clearValues()
  {
    dataSets.removeAll(keepingCapacity: false)
    notifyDataChanged()
  }
  
  /// Checks if this data object contains the specified DataSet.
  ///
  /// - Returns: `true` if so, `false` ifnot.
  public func contains(dataSet: IChartDataSet) -> Bool
  {
    for set in dataSets
    {
      if set === dataSet
      {
        return true
      }
    }
    
    return false
  }
  
  /// The total entry count across all DataSet objects this data object contains.
  public var entryCount: Int
  {
    var count = 0
    
    for set in _dataSets
    {
      count += set.entryCount
    }
    
    return count
  }
  
  /// The DataSet object with the maximum number of entries or null if there are no DataSets.
  public var maxEntryCountSet: IChartDataSet?
  {
    if _dataSets.count == 0
    {
      return nil
    }
    
    var max = _dataSets[0]
    
    for set in _dataSets
    {
      if set.entryCount > max.entryCount
      {
        max = set
      }
    }
    
    return max
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
}

extension ChartData : Equatable {
  public static func == (lhs: ChartData, rhs: ChartData) -> Bool {
    return lhs === rhs
  }
  
}

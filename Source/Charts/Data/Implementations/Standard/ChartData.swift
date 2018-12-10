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

  private var values: [ChartDataEntry]

  public convenience init(values: [ChartDataEntry]?) {
    self.init(label: "DataSet", values: values)
  }

  public init(label: String? = nil, values: [ChartDataEntry]? = nil) {
    // default color
    colors.append(NSUIColor(red: 140.0/255.0, green: 234.0/255.0, blue: 255.0/255.0, alpha: 1.0))
    valueColors.append(NSUIColor(named: "pie_value", bundle: Bundle(for: ChartData.self))!)
    self.valueFont = NSUIFont.systemFont(ofSize: 13.0)

    self.label = label
    self.values = values ?? []
    self.calcMinMax()
  }

  /// Get the Entry for a corresponding highlight object
  ///
  /// - Parameters:
  ///   - highlight:
  /// - Returns: The entry that is highlighted
  public func entry(for highlight: Highlight) -> ChartDataEntry?
  {
    return self[highlight.value]
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
    return values.reduce(0) { return $0 + $1.value }
  }

  // MARK: - Data functions and accessors
  /// The minimum y-value this DataSet holds
  public var yMin: Double { return _yMin }

  /// The maximum y-value this DataSet holds
  public var yMax: Double { return _yMax }

  /// The number of y-values this DataSet represents
  public var count: Int { return values.count }


  /// maximum y-value in the value array
  private var _yMax: Double = -Double.greatestFiniteMagnitude

  /// minimum y-value in the value array
  private var _yMin: Double = Double.greatestFiniteMagnitude

  private func calcMinMax()
  {
    _yMax = -Double.greatestFiniteMagnitude
    _yMin = Double.greatestFiniteMagnitude

    guard !values.isEmpty else { return }

    values.forEach { calcMinMax(entry: $0) }
  }

  private func calcMinMax(entry e: ChartDataEntry)
  {
    if e.value < _yMin
    {
      _yMin = e.value
    }
    if e.value > _yMax
    {
      _yMax = e.value
    }
  }

  /// - Throws: out of bounds
  /// if `i` is out of bounds, it may throw an out-of-bounds exception
  /// - Returns: The entry object found at the given index (not x-value!)
  public subscript(_ index: Int) -> ChartDataEntry? {
    guard index >= values.startIndex, index < values.endIndex else {
      return nil
    }
    return values[index]
  }

  // MARK: - Styling functions and accessors

  /// All the colors that are used for this DataSet.
  /// Colors are reused as soon as the number of Entries the DataSet represents is higher than the size of the colors array.
  public var colors = [NSUIColor]()

  /// List representing all colors that are used for drawing the actual values for this DataSet
  public var valueColors = [NSUIColor]()

  /// The label string that describes the DataSet.
  public var label: String? = "DataSet"

  /// - Returns: The color at the given index of the DataSet's color array.
  /// This prevents out-of-bounds by performing a modulus on the color index, so colours will repeat themselves.
  public func color(at index: Int) -> NSUIColor
  {
    return colors[abs(index) % colors.count]
  }

  /// - Returns: The color at the specified index that is used for drawing the values inside the chart. Uses modulus internally.
  public func valueColor(at index: Int) -> NSUIColor
  {
    return valueColors[abs(index) % valueColors.count]
  }

  /// if true, value highlighting is enabled
  public var highlightEnabled = true

  /// Custom formatter that is used instead of the auto-formatter if set
  public var valueFormatter: ValueFormatter?


  /// the font for the value-text labels
  public var valueFont: NSUIFont = NSUIFont.systemFont(ofSize: 7.0)

  /// The form to draw for this dataset in the legend.
  public var form = Legend.Form.default

  /// The form size to draw for this dataset in the legend.
  ///
  /// Return `NaN` to use the default legend form size.
  public var formSize: CGFloat = CGFloat.nan

  /// The line width for drawing the form of this dataset in the legend
  ///
  /// Return `NaN` to use the default legend form line width.
  public var formLineWidth: CGFloat = CGFloat.nan

  /// Line dash configuration for legend shapes that consist of lines.
  ///
  /// This is how much (in pixels) into the dash pattern are we starting from.
  public var formLineDashPhase: CGFloat = 0.0

  /// Line dash configuration for legend shapes that consist of lines.
  ///
  /// This is the actual dash pattern.
  /// I.e. [2, 3] will paint [--   --   ]
  /// [1, 3, 4, 2] will paint [-   ----  -   ----  ]
  public var formLineDashLengths: [CGFloat]? = nil

  /// Set this to true to draw y-values on the chart.
  ///
  /// - Note: For bar and line charts: if `maxVisibleCount` is reached, no values will be drawn even if this is enabled.
  public var drawsValues = true

  /// Set the visibility of this DataSet. If not visible, the DataSet will not be drawn to the chart upon refreshing it.
  public var visible = true

  // MARK: -
  // MARK: Pie Chart
  public enum ValuePosition
  {
    case insideSlice
    case outsideSlice
  }

  // MARK: - Styling functions and accessors

  private var _sliceSpace = CGFloat(0.0)

  /// the space in pixels between the pie-slices
  /// **default**: 0
  /// **maximum**: 20
  public var sliceSpace: CGFloat
  {
    get
    {
      return _sliceSpace
    }
    set
    {
      _sliceSpace = newValue.clamped(to: 0...20)
    }
  }

  /// When enabled, slice spacing will be 0.0 when the smallest value is going to be smaller than the slice spacing itself.
  public var automaticallyDisableSliceSpacing: Bool = false

  /// indicates the selection distance of a pie slice
  public var selectionShift = CGFloat(18.0)

  public var labelPosition: ValuePosition = .insideSlice
  public var valuePosition: ValuePosition = .insideSlice

  /// When valuePosition is OutsideSlice, indicates line color
  public var valueLineColor: NSUIColor? = NSUIColor.black

  /// When valuePosition is OutsideSlice, indicates line width
  public var valueLineWidth: CGFloat = 1.0

  var valueLinePart1OffsetRatio: CGFloat = 0.75

  /// When valuePosition is OutsideSlice, indicates offset as percentage out of the slice size
  public var valueLinePart1OffsetPercentage: CGFloat {
    get { return valueLinePart1OffsetRatio * 100 }
    set { valueLinePart1OffsetRatio = newValue / 100 }
  }

  /// When valuePosition is OutsideSlice, indicates length of first half of the line
  public var valueLinePart1Length: CGFloat = 0.3

  /// When valuePosition is OutsideSlice, indicates length of second half of the line
  public var valueLinePart2Length: CGFloat = 0.4

  /// When valuePosition is OutsideSlice, this allows variable line length
  public var valueLineVariableLength: Bool = true

  /// the font for the slice-text labels
  public var entryLabelFont: NSUIFont? = nil

  /// the color for the slice-text labels
  public var entryLabelColor: NSUIColor? = nil

  /// the color for the highlighted sector
  public var highlightColor: NSUIColor? = nil
}

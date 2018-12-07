//
//  ChartViewBase.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//
//  Based on https://github.com/PhilJay/MPAndroidChart/commit/c42b880

import Foundation
import CoreGraphics

#if !os(OSX)
import UIKit
#endif

public protocol ChartViewDelegate : AnyObject
{
  /// Called when a value has been selected inside the chart.
  ///
  /// - Parameters:
  ///   - entry: The selected Entry.
  ///   - highlight: The corresponding highlight object that contains information about the highlighted position such as dataSetIndex etc.
  func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight)

  // Called when nothing has been selected or an "un-select" has been made.
  func chartValueNothingSelected(_ chartView: ChartViewBase)

  // Callbacks when the chart is scaled / zoomed via pinch zoom gesture.
  func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat)

  // Callbacks when the chart is moved / translated via drag gesture.
  func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat)
}

extension ChartViewDelegate {
  func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {}
  func chartValueNothingSelected(_ chartView: ChartViewBase) {}
  func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {}
  func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {}
}

public class ChartViewBase: NSUIView, ChartDataProvider, AnimatorDelegate
{
  // MARK: - Properties
  /// The default ValueFormatter that has been determined by the chart considering the provided minimum and maximum values.
  internal var _defaultValueFormatter: ValueFormatter? = DefaultValueFormatter(decimals: 0)

  /// object that holds all data that was originally set for the chart, before it was modified or any filtering algorithms had been applied
  internal var _data: ChartData?

  /// If set to true, chart continues to scroll after touch up
  public var dragDecelerationEnabled = true

  /// Deceleration friction coefficient in [0 ; 1] interval, higher values indicate that speed will decrease slowly, for example if it set to 0, it will stop immediately.
  /// 1 is an invalid value, and will be converted to 0.999 automatically.
  private var _dragDecelerationFrictionCoef: CGFloat = 0.9

  /// if true, units are drawn next to the values in the chart
  internal var _drawUnitInChart = false

  /// The `Description` object of the chart.
  /// This should have been called just "description", but
  public let chartDescription = Description()

  /// The legend object containing all data associated with the legend
  internal let _legend = Legend()

  /// delegate to receive chart events
  public weak var delegate: ChartViewDelegate?

  /// text that is displayed when the chart is empty
  public var noDataText = "No chart data available."

  /// Font to be used for the no data text.
  public var noDataFont = NSUIFont.systemFont(ofSize: 12.0)

  /// color of the no data text
  public var noDataTextColor: NSUIColor = NSUIColor.labelColor

  /// alignment of the no data text
  public var noDataTextAlignment: NSTextAlignment = .left

  internal let _legendRenderer: LegendRenderer

  /// object responsible for rendering the data
  var renderer: PieChartRenderer!

  var highlighter: PieHighlighter?

  /// object that manages the bounds and drawing constraints of the chart
  internal var _viewPortHandler: ViewPortHandler

  /// object responsible for animations
  internal let _animator: Animator = Animator()

  /// flag that indicates if offsets calculation has already been done or not
  private var _offsetsCalculated = false

  /// array of Highlight objects that reference the highlighted slices in the chart
  internal var _indicesToHighlight = [Highlight]()

  private var _interceptTouchEvents = false

  /// An extra offset to be appended to the viewport's top
  public var extraTopOffset: CGFloat = 0.0

  /// An extra offset to be appended to the viewport's right
  public var extraRightOffset: CGFloat = 0.0

  /// An extra offset to be appended to the viewport's bottom
  public var extraBottomOffset: CGFloat = 0.0

  /// An extra offset to be appended to the viewport's left
  public var extraLeftOffset: CGFloat = 0.0

  public func setExtraOffsets(left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat)
  {
    extraLeftOffset = left
    extraTopOffset = top
    extraRightOffset = right
    extraBottomOffset = bottom
  }

  // MARK: - Initializers

  public override init(frame: CGRect)
  {
    _viewPortHandler = ViewPortHandler(frame.size)
    _legendRenderer = LegendRenderer(viewPortHandler: _viewPortHandler, legend: _legend)
    super.init(frame: frame)
    initialize()
  }

  public required init?(coder aDecoder: NSCoder)
  {
    _viewPortHandler = ViewPortHandler(CGSize.zero)
    _legendRenderer = LegendRenderer(viewPortHandler: _viewPortHandler, legend: _legend)

    super.init(coder: aDecoder)
    _viewPortHandler.setChartDimens(bounds.size)
    initialize()
  }

  deinit
  {
    self.removeObserver(self, forKeyPath: "bounds")
    self.removeObserver(self, forKeyPath: "frame")
  }

  internal func initialize()
  {
    #if os(iOS)
    self.backgroundColor = NSUIColor.clear
    #endif

    _animator.delegate = self

    self.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
    self.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
  }

  // MARK: - ChartViewBase

  /// The data for the chart
  public var data: ChartData?
  {
    get
    {
      return _data
    }
    set
    {
      _data = newValue
      _offsetsCalculated = false

      guard let _data = _data else
      {
        setNeedsDisplay()
        return
      }

      // calculate how many digits are needed
      setupDefaultFormatter(min: _data.yMin, max: _data.yMax)

      if let dataSet = _data.dataSet
      {
        if dataSet.valueFormatter == nil
        {
          dataSet.valueFormatter = _defaultValueFormatter
        }
      }

      // let the chart know there is new data
      notifyDataSetChanged()
    }
  }

  /// Clears the chart from all data (sets it to null) and refreshes it (by calling setNeedsDisplay()).
  public func clear()
  {
    _data = nil
    _offsetsCalculated = false
    _indicesToHighlight.removeAll()
    lastHighlighted = nil
    
    setNeedsDisplay()
  }

  /// Removes all DataSets (and thereby Entries) from the chart. Does not set the data object to nil. Also refreshes the chart by calling setNeedsDisplay().
  public func clearValues()
  {
    _data?.dataSet = nil
    setNeedsDisplay()
  }

  /// - Returns: `true` if the chart is empty (meaning it's data object is either null or contains no entries).
  public func isEmpty() -> Bool
  {
    guard let data = _data else { return true }

    if data.entryCount <= 0
    {
      return true
    }
    else
    {
      return false
    }
  }

  /// Lets the chart know its underlying data has changed and should perform all necessary recalculations.
  /// It is crucial that this method is called everytime data is changed dynamically. Not calling this method can lead to crashes or unexpected behaviour.
  public func notifyDataSetChanged()
  {
    fatalError("notifyDataSetChanged() cannot be called on ChartViewBase")
  }

  /// Calculates the offsets of the chart to the border depending on the position of an eventual legend or depending on the length of the y-axis and x-axis labels and their position
  internal func calculateOffsets()
  {
    fatalError("calculateOffsets() cannot be called on ChartViewBase")
  }

  /// calcualtes the y-min and y-max value and the y-delta and x-delta value
  internal func calcMinMax()
  {
    fatalError("calcMinMax() cannot be called on ChartViewBase")
  }

  /// calculates the required number of digits for the values that might be drawn in the chart (if enabled), and creates the default value formatter
  internal func setupDefaultFormatter(min: Double, max: Double)
  {
    // check if a custom formatter is set or not
    var reference = Double(0.0)

    if let data = _data , data.entryCount >= 2
    {
      reference = fabs(max - min)
    }
    else
    {
      let absMin = fabs(min)
      let absMax = fabs(max)
      reference = absMin > absMax ? absMin : absMax
    }

    
    if let defaultValueFormatter = _defaultValueFormatter as? DefaultValueFormatter
    {
      // setup the formatter with a new number of digits
      let digits = reference.decimalPlaces

      defaultValueFormatter.decimals = digits
    }
  }

  public override func draw(_ rect: CGRect)
  {
    let optionalContext = NSUIGraphicsGetCurrentContext()
    guard let context = optionalContext else { return }

    let frame = self.bounds

    if _data == nil && noDataText.count > 0
    {
      context.saveGState()
      defer { context.restoreGState() }

      let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
      paragraphStyle.minimumLineHeight = noDataFont.lineHeight
      paragraphStyle.lineBreakMode = .byWordWrapping
      paragraphStyle.alignment = noDataTextAlignment

      ChartUtils.drawMultilineText(
        context: context,
        text: noDataText,
        point: CGPoint(x: frame.width / 2.0, y: frame.height / 2.0),
        attributes:
        [.font: noDataFont,
         .foregroundColor: noDataTextColor,
         .paragraphStyle: paragraphStyle],
        constrainedToSize: self.bounds.size,
        anchor: CGPoint(x: 0.5, y: 0.5),
        angleRadians: 0.0)

      return
    }

    if !_offsetsCalculated
    {
      calculateOffsets()
      _offsetsCalculated = true
    }
  }

  /// Draws the description text in the bottom right corner of the chart (per default)
  internal func drawDescription(context: CGContext)
  {
    // check if description should be drawn
    guard chartDescription.isEnabled,
      let descriptionText = chartDescription.text,
      descriptionText.count > 0
      else { return }

    let position = chartDescription.position ?? CGPoint(x: bounds.width - _viewPortHandler.offsetRight - chartDescription.xOffset,
                                                        y: bounds.height - _viewPortHandler.offsetBottom - chartDescription.yOffset - chartDescription.font.lineHeight)

    var attrs = [NSAttributedString.Key : Any]()

    attrs[NSAttributedString.Key.font] = chartDescription.font
    attrs[NSAttributedString.Key.foregroundColor] = chartDescription.textColor

    ChartUtils.drawText(
      context: context,
      text: descriptionText,
      point: position,
      align: chartDescription.textAlign,
      attributes: attrs)
  }

  // MARK: - Accessibility

  public override func accessibilityChildren() -> [Any]? {
    return renderer?.accessibleChartElements
  }

  // MARK: - Highlighting

  /// The array of currently highlighted values. This might an empty if nothing is highlighted.
  public var highlighted: [Highlight]
  {
    return _indicesToHighlight
  }

  /// Set this to false to prevent values from being highlighted by tap gesture.
  /// Values can still be highlighted via drag or programmatically.
  /// **default**: true
  public var highlightsPerTap: Bool = true

  /// Checks if the highlight array is null, has a length of zero or if the first object is null.
  ///
  /// - Returns: `true` if there are values to highlight, `false` ifthere are no values to highlight.
  public func valuesToHighlight() -> Bool
  {
    return _indicesToHighlight.count > 0
  }

  /// Highlights the values at the given indices in the given DataSets. Provide
  /// null or an empty array to undo all highlighting.
  /// This should be used to programmatically highlight values.
  /// This method *will not* call the delegate.
  public func highlightValues(_ highs: [Highlight]?)
  {
    // set the indices to highlight
    _indicesToHighlight = highs ?? [Highlight]()

    if _indicesToHighlight.isEmpty
    {
      self.lastHighlighted = nil
    }
    else
    {
      self.lastHighlighted = _indicesToHighlight[0]
    }

    // redraw the chart
    setNeedsDisplay()
  }

  /// Highlights any y-value at the given x-value in the given DataSet.
  /// Provide -1 as the dataSetIndex to undo all highlighting.
  /// This method will call the delegate.
  ///
  /// - Parameters:
  ///   - x: The x-value to highlight
  ///   - dataSetIndex: The dataset index to search in
  ///   - dataIndex: The data index to search in (only used in CombinedChartView currently)
  public func highlightValue(x: Int, dataIndex: Int = -1)
  {
    highlightValue(x: x, dataIndex: dataIndex, callDelegate: true)
  }

  /// Highlights the value at the given x-value and y-value in the given DataSet.
  /// Provide -1 as the dataSetIndex to undo all highlighting.
  ///
  /// - Parameters:
  ///   - x: The x-value to highlight
  ///   - y: The y-value to highlight. Supply `NaN` for "any"
  ///   - dataSetIndex: The dataset index to search in
  ///   - dataIndex: The data index to search in (only used in CombinedChartView currently)
  ///   - callDelegate: Should the delegate be called for this change
  public func highlightValue(x: Int, dataIndex: Int = -1, callDelegate: Bool)
  {
    guard _data != nil else
    {
      Swift.print("Value not highlighted because data is nil")
      return
    }

    highlightValue(Highlight(value: x), callDelegate: callDelegate)
  }

  /// Highlights the values represented by the provided Highlight object
  /// This method *will not* call the delegate.
  ///
  /// - Parameters:
  ///   - highlight: contains information about which entry should be highlighted
  public func highlightValue(_ highlight: Highlight?)
  {
    highlightValue(highlight, callDelegate: false)
  }

  /// Highlights the value selected by touch gesture.
  public func highlightValue(_ highlight: Highlight?, callDelegate: Bool)
  {
    var entry: ChartDataEntry?
    var h = highlight

    if h == nil
    {
      self.lastHighlighted = nil
      _indicesToHighlight.removeAll(keepingCapacity: false)
    }
    else
    {
      // set the indices to highlight
      entry = _data?.entryForHighlight(h!)
      if entry == nil
      {
        h = nil
        _indicesToHighlight.removeAll(keepingCapacity: false)
      }
      else
      {
        _indicesToHighlight = [h!]
      }
    }

    if callDelegate, let delegate = delegate
    {
      if let h = h
      {
        // notify the listener
        delegate.chartValueSelected(self, entry: entry!, highlight: h)
      }
      else
      {
        delegate.chartValueNothingSelected(self)
      }
    }

    // redraw the chart
    setNeedsDisplay()
  }

  /// - Returns: The Highlight object (contains x-index and DataSet index) of the
  /// selected value at the given touch point inside the Line-, Scatter-, or
  /// CandleStick-Chart.
  public func getHighlightByTouchPoint(_ pt: CGPoint) -> Highlight?
  {
    if _data == nil
    {
      Swift.print("Can't select by touch. No data set.")
      return nil
    }

    return self.highlighter?.getHighlight(x: pt.x, y: pt.y)
  }

  /// The last value that was highlighted via touch.
  public var lastHighlighted: Highlight?
  
  // MARK: - Animation

  /// The animator responsible for animating chart values.
  public var chartAnimator: Animator!
  {
    return _animator
  }

  /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  ///   - yAxisDuration: duration for animating the y axis
  ///   - easingX: an easing function for the animation on the x axis
  ///   - easingY: an easing function for the animation on the y axis
  public func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingX: ChartEasingFunctionBlock?, easingY: ChartEasingFunctionBlock?)
  {
    _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingX: easingX, easingY: easingY)
  }

  /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  ///   - yAxisDuration: duration for animating the y axis
  ///   - easingOptionX: the easing function for the animation on the x axis
  ///   - easingOptionY: the easing function for the animation on the y axis
  public func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingOptionX: ChartEasingOption, easingOptionY: ChartEasingOption)
  {
    _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingOptionX: easingOptionX, easingOptionY: easingOptionY)
  }

  /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  ///   - yAxisDuration: duration for animating the y axis
  ///   - easing: an easing function for the animation
  public func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
  {
    _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easing: easing)
  }

  /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  ///   - yAxisDuration: duration for animating the y axis
  ///   - easingOption: the easing function for the animation
  public func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingOption: ChartEasingOption)
  {
    _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingOption: easingOption)
  }

  /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  ///   - yAxisDuration: duration for animating the y axis
  public func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval)
  {
    _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration)
  }

  /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  ///   - easing: an easing function for the animation
  public func animate(xAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
  {
    _animator.animate(xAxisDuration: xAxisDuration, easing: easing)
  }

  /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  ///   - easingOption: the easing function for the animation
  public func animate(xAxisDuration: TimeInterval, easingOption: ChartEasingOption)
  {
    _animator.animate(xAxisDuration: xAxisDuration, easingOption: easingOption)
  }

  /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - xAxisDuration: duration for animating the x axis
  public func animate(xAxisDuration: TimeInterval)
  {
    _animator.animate(xAxisDuration: xAxisDuration)
  }

  /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - yAxisDuration: duration for animating the y axis
  ///   - easing: an easing function for the animation
  public func animate(yAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
  {
    _animator.animate(yAxisDuration: yAxisDuration, easing: easing)
  }

  /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - yAxisDuration: duration for animating the y axis
  ///   - easingOption: the easing function for the animation
  public func animate(yAxisDuration: TimeInterval, easingOption: ChartEasingOption)
  {
    _animator.animate(yAxisDuration: yAxisDuration, easingOption: easingOption)
  }

  /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
  /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
  ///
  /// - Parameters:
  ///   - yAxisDuration: duration for animating the y axis
  public func animate(yAxisDuration: TimeInterval)
  {
    _animator.animate(yAxisDuration: yAxisDuration)
  }

  // MARK: - Accessors

  /// - Note: (Equivalent of getCenter() in MPAndroidChart, as center is already a standard in iOS that returns the center point relative to superview, and MPAndroidChart returns relative to self)*
  /// The center point of the chart (the whole View) in pixels.
  public var midPoint: CGPoint
  {
    let bounds = self.bounds
    return CGPoint(x: bounds.origin.x + bounds.size.width / 2.0, y: bounds.origin.y + bounds.size.height / 2.0)
  }

  /// The center of the chart taking offsets under consideration. (returns the center of the content rectangle)
  var centerOffsets: CGPoint
  {
    return _viewPortHandler.contentCenter
  }

  /// The Legend object of the chart. This method can be used to get an instance of the legend in order to customize the automatically generated Legend.
  public var legend: Legend
  {
    return _legend
  }

  /// The renderer object responsible for rendering / drawing the Legend.
  public var legendRenderer: LegendRenderer
  {
    return _legendRenderer
  }

  /// The rectangle that defines the borders of the chart-value surface (into which the actual values are drawn).
  public var contentRect: CGRect
  {
    return _viewPortHandler.contentRect
  }

  /// - Returns: The ViewPortHandler of the chart that is responsible for the
  /// content area of the chart and its offsets and dimensions.
  public var viewPortHandler: ViewPortHandler
  {
    return _viewPortHandler
  }

  /// - Returns: The bitmap that represents the chart.
  public func getChartImage(transparent: Bool) -> NSUIImage?
  {
    NSUIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque || !transparent, NSUIMainScreen()?.scale ?? 1.0)

    guard let context = NSUIGraphicsGetCurrentContext() else { return nil }

    let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: bounds.size)

    if isOpaque || !transparent
    {
      // Background color may be partially transparent, we must fill with white if we want to output an opaque image
      context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
      context.fill(rect)

      if let backgroundColor = self.backgroundColor
      {
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
      }
    }

    nsuiLayer?.render(in: context)

    let image = NSUIGraphicsGetImageFromCurrentImageContext()

    NSUIGraphicsEndImageContext()

    return image
  }

  public func getChartPDFData(transparent: Bool) -> Data?
  {
    guard
      let data = CFDataCreateMutable(nil, 0),
      let consumer = CGDataConsumer(data: data),
      let context = CGContext(consumer: consumer, mediaBox: &bounds, nil)
      else { return nil }

    context.beginPDFPage(nil)

    // PDF match quartz
    #if os(macOS)
    if isFlipped {
      context.translateBy(x: 0, y: bounds.size.height)
      context.scaleBy(x: 1, y: -1)
    }
    #endif
    let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: bounds.size)

    if isOpaque || !transparent
    {
      // Background color may be partially transparent, we must fill with white if we want to output an opaque image
      context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
      context.fill(rect)

      if let backgroundColor = self.backgroundColor
      {
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
      }
    }

    nsuiLayer?.render(in: context)

    context.endPDFPage()
    context.closePDF()
    return data as Data
  }

  public enum ImageFormat
  {
    case jpeg(quality: Double)
    case png
    case pdf

    var hasAlpha : Bool {
      switch self {
      case .png, .pdf:
        return true
      case .jpeg:
        return false
      }
    }
  }

  /// Saves the current chart state with the given name to the given path on
  /// the sdcard leaving the path empty "" will put the saved file directly on
  /// the SD card chart is saved as a PNG image, example:
  /// saveToPath("myfilename", "foldername1/foldername2")
  ///
  /// - Parameters:
  ///   - to: path to the image to save
  ///   - format: the format to save
  ///   - compressionQuality: compression quality for lossless formats (JPEG)
  /// - Returns: `true` if the image was saved successfully
  public func save(to url: URL, format: ImageFormat) -> Bool
  {
    let imageData: Data?
    switch (format)
    {
    case .png:
      if let image = getChartImage(transparent: format.hasAlpha) {
        imageData = NSUIImagePNGRepresentation(image)
      } else {
        imageData = nil
      }
    case .pdf: imageData = getChartPDFData(transparent: format.hasAlpha)
    case let .jpeg(quality):
      if let image = getChartImage(transparent: format.hasAlpha) {
        imageData = NSUIImageJPEGRepresentation(image, quality)
      } else {
        imageData = nil
      }
    }

    guard let data = imageData else { return false }

    do
    {
      try data.write(to: url, options: .atomic)
    }
    catch
    {
      return false
    }

    return true
  }

  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
  {
    if keyPath == "bounds" || keyPath == "frame"
    {
      let bounds = self.bounds

      if (bounds.size.width != _viewPortHandler.chartWidth || bounds.size.height != _viewPortHandler.chartHeight)
      {
        _viewPortHandler.setChartDimens(bounds.size)

        // This may cause the chart view to mutate properties affecting the view port -- lets do this
        // before we try to run any pending jobs on the view port itself
        notifyDataSetChanged()
      }
    }
  }

  /// **default**: true
  /// `true` if chart continues to scroll after touch up, `false` ifnot.
  public var isDragDecelerationEnabled: Bool
  {
    return dragDecelerationEnabled
  }

  /// Deceleration friction coefficient in [0 ; 1] interval, higher values indicate that speed will decrease slowly, for example if it set to 0, it will stop immediately.
  /// 1 is an invalid value, and will be converted to 0.999 automatically.
  ///
  /// **default**: true
  public var dragDecelerationFrictionCoef: CGFloat
  {
    get
    {
      return _dragDecelerationFrictionCoef
    }
    set
    {
      var val = newValue
      if val < 0.0
      {
        val = 0.0
      }
      if val >= 1.0
      {
        val = 0.999
      }

      _dragDecelerationFrictionCoef = val
    }
  }

  /// The maximum distance in screen pixels away from an entry causing it to highlight.
  /// **default**: 500.0
  public var maxHighlightDistance: CGFloat = 500.0

  /// the number of maximum visible drawn values on the chart only active when `drawValuesEnabled` is enabled
  public var maxVisibleCount: Int
  {
    return Int(INT_MAX)
  }

  // MARK: - AnimatorDelegate

  public func animatorUpdated(_ chartAnimator: Animator)
  {
    setNeedsDisplay()
  }

  public func animatorStopped(_ chartAnimator: Animator)
  {

  }

  // MARK: - Touches

  public override func nsuiTouchesBegan(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
  {
    if !_interceptTouchEvents
    {
      super.nsuiTouchesBegan(touches, withEvent: event)
    }
  }

  public override func nsuiTouchesMoved(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
  {
    if !_interceptTouchEvents
    {
      super.nsuiTouchesMoved(touches, withEvent: event)
    }
  }

  public override func nsuiTouchesEnded(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
  {
    if !_interceptTouchEvents
    {
      super.nsuiTouchesEnded(touches, withEvent: event)
    }
  }

  public override func nsuiTouchesCancelled(_ touches: Set<NSUITouch>?, withEvent event: NSUIEvent?)
  {
    if !_interceptTouchEvents
    {
      super.nsuiTouchesCancelled(touches, withEvent: event)
    }
  }
}

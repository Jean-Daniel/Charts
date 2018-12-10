//
//  PieRadarChartViewBase.swift
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

#if !os(OSX)
import UIKit
#endif

/// Base class of PieChartView and RadarChartView.
public class PieChartView: ChartViewBase
{
  /// holds the normalized version of the current rotation angle of the chart
  private var _rotationAngle = CGFloat(270.0)

  /// holds the raw version of the current rotation angle of the chart
  private var _rawRotationAngle = CGFloat(270.0)

  /// flag that indicates if rotation is enabled or not
  public var rotationEnabled = true

  /// Sets the minimum offset (padding) around the chart, defaults to 0.0
  public var minOffset = CGFloat(0.0)

  /// rect object that represents the bounds of the piechart, needed for drawing the circle
  private var _circleBox = CGRect()

  /// array that holds the width of each pie-slice in degrees
  private var _drawAngles = [CGFloat]()

  /// array that holds the absolute angle in degrees of each slice
  private var _absoluteAngles = [CGFloat]()

  /// maximum angle for this pie
  private var _maxAngle: CGFloat = 360.0

  /// iOS && OSX only: Enabled multi-touch rotation using two fingers.
  private var _rotationWithTwoFingers = false

  private let _tapGestureRecognizer = NSUITapGestureRecognizer(target: nil, action: nil)
  #if !os(tvOS)
  private let _rotationGestureRecognizer = NSUIRotationGestureRecognizer(target: nil, action: nil)
  #endif

  public override init(frame: CGRect)
  {
    super.init(frame: frame)
  }

  public required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
  }

  deinit
  {
    stopDeceleration()
  }

  internal override func initialize()
  {
    super.initialize()

    renderer = PieChartRenderer(chart: self, animator: _animator)
    
    _tapGestureRecognizer.addTarget(self, action: #selector(tapGestureRecognized(_:)))

    self.addGestureRecognizer(_tapGestureRecognizer)

    #if !os(tvOS)
    _rotationGestureRecognizer.addTarget(self, action: #selector(rotationGestureRecognized(_:)))
    self.addGestureRecognizer(_rotationGestureRecognizer)
    _rotationGestureRecognizer.isEnabled = rotationWithTwoFingers
    #endif
  }

  /// calculates the needed angles for the chart slices
  internal override func calcMinMax()
  {
    _drawAngles = [CGFloat]()
    _absoluteAngles = [CGFloat]()

    guard let data = _data else { return }

    let entryCount = data.count

    _drawAngles.reserveCapacity(entryCount)
    _absoluteAngles.reserveCapacity(entryCount)

    var cnt = 0

    for j in 0 ..< entryCount
    {
      guard let e = data[j] else { continue }

      _drawAngles.append(calcAngle(value: abs(e.value), yValueSum: _data?.yValueSum ?? 0))

      if cnt == 0
      {
        _absoluteAngles.append(_drawAngles[cnt])
      }
      else
      {
        _absoluteAngles.append(_absoluteAngles[cnt - 1] + _drawAngles[cnt])
      }

      cnt += 1
    }
  }

  /// calculates the needed angle for a given value
  private func calcAngle(_ value: Double) -> CGFloat
  {
    return calcAngle(value: value, yValueSum: _data?.yValueSum ?? 0)
  }

  /// calculates the needed angle for a given value
  private func calcAngle(value: Double, yValueSum: Double) -> CGFloat
  {
    return CGFloat(value) / CGFloat(yValueSum) * _maxAngle
  }
  
  public override var maxVisibleCount: Int
  {
    get
    {
      return data?.count ?? 0
    }
  }

  public override func notifyDataSetChanged()
  {
    calcMinMax()

    if let data = _data
    {
      legendRenderer.computeLegend(data: data)
    }

    calculateOffsets()

    setNeedsDisplay()
  }

  public override func draw(_ rect: CGRect)
  {
    super.draw(rect)

    if _data == nil
    {
      return
    }

    guard let context = NSUIGraphicsGetCurrentContext(), let renderer = renderer else
    {
      return
    }

    renderer.drawData(context: context)

    if (isHighlighted)
    {
      renderer.drawHighlighted(context: context, indices: _indicesToHighlight)
    }

    renderer.drawExtras(context: context)

    renderer.drawValues(context: context)

    legendRenderer.renderLegend(context: context)

    drawDescription(context: context)
  }

  /// Checks if the given index is set to be highlighted.
  public func isHighlighted(at index: Int) -> Bool
  {
    // no highlight
    guard isHighlighted else {
      return false
    }

    for i in 0 ..< _indicesToHighlight.count
    {
      // check if the xvalue for the given dataset needs highlight
      if _indicesToHighlight[i].value == index
      {
        return true
      }
    }

    return false
  }

  /// - Parameters:
  ///   - x:
  ///   - y:
  /// - Returns: A Highlight object corresponding to the given x- and y- touch positions in pixels.
  public override func getHighlight(x: CGFloat, y: CGFloat) -> Highlight?
  {
    let touchDistanceToCenter = distanceToCenter(x: x, y: y)

    // check if a slice was touched
    guard touchDistanceToCenter <= radius else
    {
      // if no slice was touched, highlight nothing
      return nil
    }

    var angle = angleForPoint(x: x ,y: y)

    angle /= CGFloat(chartAnimator.phase)

    let index = indexForAngle(angle)

    // check if the index could be found
    if index < 0 || index >= data?.count ?? 0
    {
      return nil
    }
    else
    {
      return Highlight(value: index)
    }

  }

  internal override func calculateOffsets()
  {
    var legendLeft = CGFloat(0.0)
    var legendRight = CGFloat(0.0)
    var legendBottom = CGFloat(0.0)
    var legendTop = CGFloat(0.0)

    if _legend.enabled && !_legend.drawInside
    {
      let fullLegendWidth = min(_legend.neededWidth, _viewPortHandler.chartWidth * _legend.maxSizePercent)

      switch _legend.orientation
      {
      case .vertical:

        var xLegendOffset: CGFloat = 0.0

        if _legend.horizontalAlignment == .left || _legend.horizontalAlignment == .right
        {
          if _legend.verticalAlignment == .center
          {
            // this is the space between the legend and the chart
            let spacing = CGFloat(13.0)

            xLegendOffset = fullLegendWidth + spacing
          }
          else
          {
            // this is the space between the legend and the chart
            let spacing = CGFloat(8.0)

            let legendWidth = fullLegendWidth + spacing
            let legendHeight = _legend.neededHeight + _legend.textHeightMax

            let c = self.midPoint

            let bottomX = _legend.horizontalAlignment == .right
              ? self.bounds.width - legendWidth + 15.0
              : legendWidth - 15.0
            let bottomY = legendHeight + 15
            let distLegend = distanceToCenter(x: bottomX, y: bottomY)

            let reference = getPosition(center: c, dist: self.radius,
                                        angle: angleForPoint(x: bottomX, y: bottomY))

            let distReference = distanceToCenter(x: reference.x, y: reference.y)
            let minOffset = CGFloat(5.0)

            if bottomY >= c.y
              && self.bounds.height - legendWidth > self.bounds.width
            {
              xLegendOffset = legendWidth
            }
            else if distLegend < distReference
            {
              let diff = distReference - distLegend
              xLegendOffset = minOffset + diff
            }
          }
        }

        switch _legend.horizontalAlignment
        {
        case .left:
          legendLeft = xLegendOffset

        case .right:
          legendRight = xLegendOffset

        case .center:

          switch _legend.verticalAlignment
          {
          case .top:
            legendTop = min(_legend.neededHeight, _viewPortHandler.chartHeight * _legend.maxSizePercent)

          case .bottom:
            legendBottom = min(_legend.neededHeight, _viewPortHandler.chartHeight * _legend.maxSizePercent)

          default:
            break
          }
        }

      case .horizontal:

        var yLegendOffset: CGFloat = 0.0

        if _legend.verticalAlignment == .top
          || _legend.verticalAlignment == .bottom
        {
          // It's possible that we do not need this offset anymore as it
          //   is available through the extraOffsets, but changing it can mean
          //   changing default visibility for existing apps.
          let yOffset = self.requiredLegendOffset

          yLegendOffset = min(
            _legend.neededHeight + yOffset,
            _viewPortHandler.chartHeight * _legend.maxSizePercent)
        }

        switch _legend.verticalAlignment
        {
        case .top:

          legendTop = yLegendOffset

        case .bottom:

          legendBottom = yLegendOffset

        default:
          break
        }
      }

      legendLeft += self.requiredBaseOffset
      legendRight += self.requiredBaseOffset
      legendTop += self.requiredBaseOffset
      legendBottom += self.requiredBaseOffset
    }

    let minOffset = self.minOffset

    let offsetLeft = max(minOffset, legendLeft)
    let offsetTop = max(minOffset, legendTop)
    let offsetRight = max(minOffset, legendRight)
    let offsetBottom = max(minOffset, max(self.requiredBaseOffset, legendBottom))

    _viewPortHandler.restrainViewPort(offsetLeft: offsetLeft, offsetTop: offsetTop, offsetRight: offsetRight, offsetBottom: offsetBottom)

    // prevent nullpointer when no data set
    let radius = diameter / 2.0

    let c = self.centerOffsets

    let shift = data?.selectionShift ?? 0.0

    // create the circle box that will contain the pie-chart (the bounds of the pie-chart)
    _circleBox.origin.x = (c.x - radius) + shift
    _circleBox.origin.y = (c.y - radius) + shift
    _circleBox.size.width = diameter - shift * 2.0
    _circleBox.size.height = diameter - shift * 2.0
  }
  
  /// - Returns: The angle relative to the chart center for the given point on the chart in degrees.
  /// The angle is always between 0 and 360°, 0° is NORTH, 90° is EAST, ...
  public func angleForPoint(x: CGFloat, y: CGFloat) -> CGFloat
  {
    let c = centerOffsets

    let tx = Double(x - c.x)
    let ty = Double(y - c.y)
    let length = sqrt(tx * tx + ty * ty)
    let r = acos(ty / length)

    var angle = r.RAD2DEG

    if x > c.x
    {
      angle = 360.0 - angle
    }

    // add 90° because chart starts EAST
    angle = angle + 90.0

    // neutralize overflow
    if angle > 360.0
    {
      angle = angle - 360.0
    }

    return CGFloat(angle)
  }

  /// Calculates the position around a center point, depending on the distance
  /// from the center, and the angle of the position around the center.
  public func getPosition(center: CGPoint, dist: CGFloat, angle: CGFloat) -> CGPoint
  {
    return CGPoint(x: center.x + dist * cos(angle.DEG2RAD),
                   y: center.y + dist * sin(angle.DEG2RAD))
  }

  /// - Returns: The distance of a certain point on the chart to the center of the chart.
  public func distanceToCenter(x: CGFloat, y: CGFloat) -> CGFloat
  {
    let c = self.centerOffsets

    var dist = CGFloat(0.0)

    var xDist = CGFloat(0.0)
    var yDist = CGFloat(0.0)

    if x > c.x
    {
      xDist = x - c.x
    }
    else
    {
      xDist = c.x - x
    }

    if y > c.y
    {
      yDist = y - c.y
    }
    else
    {
      yDist = c.y - y
    }

    // pythagoras
    dist = sqrt(pow(xDist, 2.0) + pow(yDist, 2.0))

    return dist
  }

  /// - Returns: The xIndex for the given angle around the center of the chart.
  /// -1 if not found / outofbounds.
  public func indexForAngle(_ angle: CGFloat) -> Int
  {
    // take the current angle of the chart into consideration
    let a = (angle - self.rotationAngle).normalizedAngle
    for i in 0 ..< _absoluteAngles.count
    {
      if _absoluteAngles[i] > a
      {
        return i
      }
    }

    return -1 // return -1 if no index found
  }

  /// current rotation angle of the pie chart
  ///
  /// **default**: 270 --> top (NORTH)
  /// Will always return a normalized value, which will be between 0.0 < 360.0
  public var rotationAngle: CGFloat
  {
    get
    {
      return _rotationAngle
    }
    set
    {
      _rawRotationAngle = newValue
      _rotationAngle = newValue.normalizedAngle
      setNeedsDisplay()
    }
  }

  /// gets the raw version of the current rotation angle of the pie chart the returned value could be any value, negative or positive, outside of the 360 degrees.
  /// this is used when working with rotation direction, mainly by gestures and animations.
  public var rawRotationAngle: CGFloat
  {
    return _rawRotationAngle
  }

  /// The diameter of the pie- or radar-chart
  public var diameter: CGFloat
  {
    let content = _viewPortHandler.contentRect
    return min(content.width, content.height)
  }

  /// The radius of the chart in pixels.
  public var radius: CGFloat
  {
    return _circleBox.width / 2.0
  }

  /// The required offset for the chart legend.
  internal var requiredLegendOffset: CGFloat
  {
    return _legend.font.pointSize * 2.0
  }

  /// - Returns: The base offset needed for the chart without calculating the
  /// legend size.
  internal var requiredBaseOffset: CGFloat
  {
    return 0.0
  }

  /// flag that indicates if rotation is done with two fingers or one.
  /// when the chart is inside a scrollview, you need a two-finger rotation because a one-finger rotation eats up all touch events.
  ///
  /// On iOS this will disable one-finger rotation.
  /// On OSX this will keep two-finger multitouch rotation, and one-pointer mouse rotation.
  ///
  /// **default**: false
  public var rotationWithTwoFingers: Bool
  {
    get
    {
      return _rotationWithTwoFingers
    }
    set
    {
      _rotationWithTwoFingers = newValue
      #if !os(tvOS)
      _rotationGestureRecognizer.isEnabled = _rotationWithTwoFingers
      #endif
    }
  }

  // MARK: - Animation

  private var _spinAnimator: Animator!

  /// Applys a spin animation to the Chart.
  public func spin(duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat, easing: ChartEasingFunctionBlock?)
  {
    if _spinAnimator != nil
    {
      _spinAnimator.stop()
    }

    _spinAnimator = Animator()
    _spinAnimator.updateBlock = {
      self.rotationAngle = (toAngle - fromAngle) * CGFloat(self._spinAnimator.phase) + fromAngle
    }
    _spinAnimator.stopBlock = { self._spinAnimator = nil }

    _spinAnimator.animate(duration: duration, easing: easing)
  }

  public func spin(duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat, easingOption: ChartEasingOption)
  {
    spin(duration: duration, fromAngle: fromAngle, toAngle: toAngle, easing: easingFunctionFromOption(easingOption))
  }

  public func spin(duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat)
  {
    spin(duration: duration, fromAngle: fromAngle, toAngle: toAngle, easing: nil)
  }

  public func stopSpinAnimation()
  {
    if _spinAnimator != nil
    {
      _spinAnimator.stop()
    }
  }

  // MARK: - Gestures

  private var _rotationGestureStartPoint: CGPoint!
  private var _isRotating = false
  private var _startAngle = CGFloat(0.0)

  private struct AngularVelocitySample
  {
    var time: TimeInterval
    var angle: CGFloat
  }

  private var _velocitySamples = [AngularVelocitySample]()

  private var _decelerationLastTime: TimeInterval = 0.0
  private var _decelerationDisplayLink: DisplayLink!
  private var _decelerationAngularVelocity: CGFloat = 0.0

  internal final func processRotationGestureBegan(location: CGPoint)
  {
    self.resetVelocity()

    if rotationEnabled
    {
      self.sampleVelocity(touchLocation: location)
    }

    self.setGestureStartAngle(x: location.x, y: location.y)

    _rotationGestureStartPoint = location
  }

  internal final func processRotationGestureMoved(location: CGPoint)
  {
    if dragDecelerationEnabled
    {
      sampleVelocity(touchLocation: location)
    }

    if !_isRotating &&
      distance(
        eventX: location.x,
        startX: _rotationGestureStartPoint.x,
        eventY: location.y,
        startY: _rotationGestureStartPoint.y) > CGFloat(8.0)
    {
      _isRotating = true
    }
    else
    {
      self.updateGestureRotation(x: location.x, y: location.y)
      setNeedsDisplay()
    }
  }

  internal final func processRotationGestureEnded(location: CGPoint)
  {
    if dragDecelerationEnabled
    {
      stopDeceleration()

      sampleVelocity(touchLocation: location)

      _decelerationAngularVelocity = calculateVelocity()

      if _decelerationAngularVelocity != 0.0
      {
        _decelerationDisplayLink = DisplayLink{ self.decelerationLoop($0) }
        _decelerationLastTime = _decelerationDisplayLink.start()
      }
    }
  }

  internal final func processRotationGestureCancelled()
  {
    if _isRotating
    {
      _isRotating = false
    }
  }

  #if !os(OSX)
  public override func nsuiTouchesBegan(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
  {
    // if rotation by touch is enabled
    if rotationEnabled
    {
      stopDeceleration()

      if !rotationWithTwoFingers, let touchLocation = touches.first?.location(in: self)
      {
        processRotationGestureBegan(location: touchLocation)
      }
    }

    if !_isRotating
    {
      super.nsuiTouchesBegan(touches, withEvent: event)
    }
  }

  public override func nsuiTouchesMoved(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
  {
    if rotationEnabled && !rotationWithTwoFingers, let touch = touches.first
    {
      let touchLocation = touch.location(in: self)
      processRotationGestureMoved(location: touchLocation)
    }

    if !_isRotating
    {
      super.nsuiTouchesMoved(touches, withEvent: event)
    }
  }

  public override func nsuiTouchesEnded(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
  {
    if !_isRotating
    {
      super.nsuiTouchesEnded(touches, withEvent: event)
    }

    if rotationEnabled && !rotationWithTwoFingers, let touch = touches.first
    {
      let touchLocation = touch.location(in: self)
      processRotationGestureEnded(location: touchLocation)
    }

    if _isRotating
    {
      _isRotating = false
    }
  }

  public override func nsuiTouchesCancelled(_ touches: Set<NSUITouch>?, withEvent event: NSUIEvent?)
  {
    super.nsuiTouchesCancelled(touches, withEvent: event)

    processRotationGestureCancelled()
  }
  #endif

  #if os(OSX)
  public override func mouseDown(with theEvent: NSEvent)
  {
    // if rotation by touch is enabled
    if rotationEnabled
    {
      stopDeceleration()

      let location = self.convert(theEvent.locationInWindow, from: nil)

      processRotationGestureBegan(location: location)
    }

    if !_isRotating
    {
      super.mouseDown(with: theEvent)
    }
  }

  public override func mouseDragged(with theEvent: NSEvent)
  {
    if rotationEnabled
    {
      let location = self.convert(theEvent.locationInWindow, from: nil)

      processRotationGestureMoved(location: location)
    }

    if !_isRotating
    {
      super.mouseDragged(with: theEvent)
    }
  }

  public override func mouseUp(with theEvent: NSEvent)
  {
    if !_isRotating
    {
      super.mouseUp(with: theEvent)
    }

    if rotationEnabled
    {
      let location = self.convert(theEvent.locationInWindow, from: nil)

      processRotationGestureEnded(location: location)
    }

    if _isRotating
    {
      _isRotating = false
    }
  }
  #endif

  private func resetVelocity()
  {
    _velocitySamples.removeAll(keepingCapacity: false)
  }

  private func sampleVelocity(touchLocation: CGPoint)
  {
    let currentTime = CACurrentMediaTime()

    _velocitySamples.append(AngularVelocitySample(time: currentTime, angle: angleForPoint(x: touchLocation.x, y: touchLocation.y)))

    // Remove samples older than our sample time - 1 seconds
    var i = 0, count = _velocitySamples.count
    while (i < count - 2)
    {
      if currentTime - _velocitySamples[i].time > 1.0
      {
        _velocitySamples.remove(at: 0)
        i -= 1
        count -= 1
      }
      else
      {
        break
      }

      i += 1
    }
  }

  private func calculateVelocity() -> CGFloat
  {
    if _velocitySamples.isEmpty
    {
      return 0.0
    }

    var firstSample = _velocitySamples[0]
    var lastSample = _velocitySamples[_velocitySamples.count - 1]

    // Look for a sample that's closest to the latest sample, but not the same, so we can deduce the direction
    var beforeLastSample = firstSample
    for i in stride(from: (_velocitySamples.count - 1), through: 0, by: -1)
    {
      beforeLastSample = _velocitySamples[i]
      if beforeLastSample.angle != lastSample.angle
      {
        break
      }
    }

    // Calculate the sampling time
    var timeDelta = lastSample.time - firstSample.time
    if timeDelta == 0.0
    {
      timeDelta = 0.1
    }

    // Calculate clockwise/ccw by choosing two values that should be closest to each other,
    // so if the angles are two far from each other we know they are inverted "for sure"
    var clockwise = lastSample.angle >= beforeLastSample.angle
    if (abs(lastSample.angle - beforeLastSample.angle) > 270.0)
    {
      clockwise = !clockwise
    }

    // Now if the "gesture" is over a too big of an angle - then we know the angles are inverted, and we need to move them closer to each other from both sides of the 360.0 wrapping point
    if lastSample.angle - firstSample.angle > 180.0
    {
      firstSample.angle += 360.0
    }
    else if firstSample.angle - lastSample.angle > 180.0
    {
      lastSample.angle += 360.0
    }

    // The velocity
    var velocity = abs((lastSample.angle - firstSample.angle) / CGFloat(timeDelta))

    // Direction?
    if !clockwise
    {
      velocity = -velocity
    }

    return velocity
  }

  /// sets the starting angle of the rotation, this is only used by the touch listener, x and y is the touch position
  private func setGestureStartAngle(x: CGFloat, y: CGFloat)
  {
    _startAngle = angleForPoint(x: x, y: y)

    // take the current angle into consideration when starting a new drag
    _startAngle -= _rotationAngle
  }

  /// updates the view rotation depending on the given touch position, also takes the starting angle into consideration
  private func updateGestureRotation(x: CGFloat, y: CGFloat)
  {
    self.rotationAngle = angleForPoint(x: x, y: y) - _startAngle
  }

  public func stopDeceleration()
  {
    _decelerationDisplayLink?.stop()
    _decelerationDisplayLink = nil
  }

  private func decelerationLoop(_ targetTime: TimeInterval)
  {
    _decelerationAngularVelocity *= self.dragDecelerationFrictionCoef

    let timeInterval = CGFloat(targetTime - _decelerationLastTime)

    self.rotationAngle += _decelerationAngularVelocity * timeInterval

    _decelerationLastTime = targetTime

    if(abs(_decelerationAngularVelocity) < 0.001)
    {
      stopDeceleration()
    }
  }

  /// - Returns: The distance between two points
  private func distance(eventX: CGFloat, startX: CGFloat, eventY: CGFloat, startY: CGFloat) -> CGFloat
  {
    let dx = eventX - startX
    let dy = eventY - startY
    return sqrt(dx * dx + dy * dy)
  }

  /// - Returns: The distance between two points
  private func distance(from: CGPoint, to: CGPoint) -> CGFloat
  {
    let dx = from.x - to.x
    let dy = from.y - to.y
    return sqrt(dx * dx + dy * dy)
  }

  @objc private func tapGestureRecognized(_ recognizer: NSUITapGestureRecognizer)
  {
    if recognizer.state == .ended
    {
      if !self.highlightsPerTap { return }

      let location = recognizer.location(in: self)

      let high = self.getHighlightByTouchPoint(location)
      self.highlightValue(high, callDelegate: true)
    }
  }

  #if !os(tvOS)
  @objc private func rotationGestureRecognized(_ recognizer: NSUIRotationGestureRecognizer)
  {
    if recognizer.state == .began
    {
      stopDeceleration()

      _startAngle = self.rawRotationAngle
    }

    if recognizer.state == .began || recognizer.state == .changed
    {
      let angle = recognizer.nsuiRotation.RAD2DEG

      self.rotationAngle = _startAngle + angle
      setNeedsDisplay()
    }
    else if recognizer.state == .ended
    {
      let angle = recognizer.nsuiRotation.RAD2DEG

      self.rotationAngle = _startAngle + angle
      setNeedsDisplay()

      if dragDecelerationEnabled
      {
        stopDeceleration()

        _decelerationAngularVelocity = recognizer.velocity.RAD2DEG

        if _decelerationAngularVelocity != 0.0
        {
          _decelerationDisplayLink = DisplayLink(callback: self.decelerationLoop)
          _decelerationLastTime = _decelerationDisplayLink.start()
        }
      }
    }
  }
  #endif

  // MARK: -
  // MARK: Pie Chart Specific

  /// - Returns: An integer array of all the different angles the chart slices
  /// have the angles in the returned array determine how much space (of 360°)
  /// each slice takes
  public var drawAngles: [CGFloat]
  {
    return _drawAngles
  }

  /// - Returns: The absolute angles of the different chart slices (where the
  /// slices end)
  public var absoluteAngles: [CGFloat]
  {
    return _absoluteAngles
  }

  /// The color for the hole that is drawn in the center of the PieChart (if enabled).
  ///
  /// - Note: Use holeTransparent with holeColor = nil to make the hole transparent.*
  public var holeColor: NSUIColor? = NSUIColor(named: "pie_hole", bundle: Bundle(for: PieChartView.self))
  {
    didSet { setNeedsDisplay() }
  }

  /// if true, the hole will see-through to the inner tips of the slices
  ///
  /// **default**: `false`
  public var drawsSlicesUnderHole: Bool = false
  {
    didSet { setNeedsDisplay() }
  }

  /// `true` if the hole in the center of the pie-chart is set to be visible, `false` ifnot
  public var drawsHole: Bool = true
  {
    didSet { setNeedsDisplay() }
  }

  /// the text that is displayed in the center of the pie-chart
  public var centerText: String?
  {
    get
    {
      return self.centerAttributedText?.string
    }
    set
    {
      var attrString: NSMutableAttributedString?
      if newValue == nil
      {
        attrString = nil
      }
      else
      {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
        paragraphStyle.alignment = .center

        attrString = NSMutableAttributedString(string: newValue!)
        attrString?.setAttributes([
          .foregroundColor: NSUIColor(named: "pie_center_text", bundle: Bundle(for: PieChartView.self))!,
          .font: NSUIFont.systemFont(ofSize: 12.0),
          .paragraphStyle: paragraphStyle
          ], range: NSMakeRange(0, attrString!.length))
      }
      self.centerAttributedText = attrString
    }
  }

  /// the text that is displayed in the center of the pie-chart
  public var centerAttributedText: NSAttributedString?
  {
    didSet { setNeedsDisplay() }
  }

  /// Sets the offset the center text should have from it's original position in dp. Default x = 0, y = 0
  public var centerTextOffset: CGPoint = CGPoint.zero
  {
    didSet { setNeedsDisplay() }
  }

  /// `true` if drawing the center text is enabled
  public var drawsCenterText: Bool = true
  {
    didSet { setNeedsDisplay() }
  }

  /// The circlebox, the boundingbox of the pie-chart slices
  public var circleBox: CGRect
  {
    return _circleBox
  }

  /// The center of the circlebox
  public var centerCircleBox: CGPoint
  {
    return CGPoint(x: _circleBox.midX, y: _circleBox.midY)
  }

  /// the radius of the hole in the center of the piechart in percent of the maximum radius (max = the radius of the whole chart)
  ///
  /// **default**: 0.5 (50%) (half the pie)
  var holeRadiusRatio: CGFloat = CGFloat(0.5)
  {
    didSet { setNeedsDisplay() }
  }

  public var holeRadiusPercent: CGFloat
  {
    get { return holeRadiusRatio * 100 }
    set { holeRadiusRatio = newValue / 100 }
  }

  /// The color that the transparent-circle should have.
  ///
  /// **default**: `nil`
  public var transparentCircleColor: NSUIColor? = NSUIColor(named: "pie_hole", bundle: Bundle(for: PieChartView.self))?.withAlphaComponent(0.5)
  {
    didSet { setNeedsDisplay() }
  }

  /// the radius of the transparent circle that is drawn next to the hole in the piechart in percent of the maximum radius (max = the radius of the whole chart)
  ///
  /// **default**: 0.55 (55%) -> means 5% larger than the center-hole by default
  var transparentCircleRadiusRatio: CGFloat = CGFloat(0.55)
  {
    didSet { setNeedsDisplay() }
  }

  public var transparentCircleRadiusPercent: CGFloat
  {
    get { return transparentCircleRadiusRatio * 100 }
    set { transparentCircleRadiusRatio = newValue / 100 }
  }

  /// The color the entry labels are drawn with.
  public var entryLabelColor: NSUIColor? = NSUIColor(named: "pie_label", bundle: Bundle(for: PieChartView.self))
  {
    didSet { setNeedsDisplay() }
  }

  /// The font the entry labels are drawn with.
  public var entryLabelFont: NSUIFont? = NSUIFont.systemFont(ofSize: 13.0)
  {
    didSet { setNeedsDisplay() }
  }

  /// Set this to true to draw the enrty labels into the pie slices
  public var drawsEntryLabels: Bool = true
  {
    didSet { setNeedsDisplay() }
  }

  /// If this is enabled, values inside the PieChart are drawn in percent and not with their original value. Values provided for the ValueFormatter to format are then provided in percent.
  public var usesPercentValues: Bool = false
  {
    didSet { setNeedsDisplay() }
  }

  /// the rectangular radius of the bounding box for the center text, as a percentage of the pie hole
  var centerTextRadiusRatio: CGFloat = 1.0
  {
    didSet { setNeedsDisplay() }
  }

  public var centerTextRadiusPercent: CGFloat
  {
    get { return centerTextRadiusRatio * 100 }
    set { centerTextRadiusRatio = newValue / 100 }
  }

  /// The max angle that is used for calculating the pie-circle.
  /// 360 means it's a full pie-chart, 180 results in a half-pie-chart.
  /// **default**: 360.0
  public var maxAngle: CGFloat
  {
    get
    {
      return _maxAngle
    }
    set
    {
      _maxAngle = newValue

      if _maxAngle > 360.0
      {
        _maxAngle = 360.0
      }

      if _maxAngle < 90.0
      {
        _maxAngle = 90.0
      }
    }
  }
}

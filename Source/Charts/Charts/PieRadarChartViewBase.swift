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
open class PieRadarChartViewBase: ChartViewBase
{
    /// holds the normalized version of the current rotation angle of the chart
    private var _rotationAngle = CGFloat(270.0)
    
    /// holds the raw version of the current rotation angle of the chart
    private var _rawRotationAngle = CGFloat(270.0)
    
    /// flag that indicates if rotation is enabled or not
    open var rotationEnabled = true
    
    /// Sets the minimum offset (padding) around the chart, defaults to 0.0
    open var minOffset = CGFloat(0.0)

    /// iOS && OSX only: Enabled multi-touch rotation using two fingers.
    private var _rotationWithTwoFingers = false
    
    private var _tapGestureRecognizer: NSUITapGestureRecognizer!
    #if !os(tvOS)
    private var _rotationGestureRecognizer: NSUIRotationGestureRecognizer!
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
        
        _tapGestureRecognizer = NSUITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:)))
        
        self.addGestureRecognizer(_tapGestureRecognizer)

        #if !os(tvOS)
            _rotationGestureRecognizer = NSUIRotationGestureRecognizer(target: self, action: #selector(rotationGestureRecognized(_:)))
            self.addGestureRecognizer(_rotationGestureRecognizer)
            _rotationGestureRecognizer.isEnabled = rotationWithTwoFingers
        #endif
    }
    
    internal override func calcMinMax()
    {
        /*_xAxis.axisRange = Double((_data?.xVals.count ?? 0) - 1)*/
    }
    
    open override var maxVisibleCount: Int
    {
        get
        {
            return data?.entryCount ?? 0
        }
    }
    
    open override func notifyDataSetChanged()
    {
        calcMinMax()
        
        if let data = _data , _legend !== nil
        {
            legendRenderer.computeLegend(data: data)
        }
        
        calculateOffsets()
        
        setNeedsDisplay()
    }
  
    internal override func calculateOffsets()
    {
        var legendLeft = CGFloat(0.0)
        var legendRight = CGFloat(0.0)
        var legendBottom = CGFloat(0.0)
        var legendTop = CGFloat(0.0)

        if _legend != nil && _legend.enabled && !_legend.drawInside
        {
            let fullLegendWidth = min(_legend.neededWidth, _viewPortHandler.chartWidth * _legend.maxSizePercent)
            
            switch _legend.orientation
            {
            case .vertical:
                
                var xLegendOffset: CGFloat = 0.0
                
                if _legend.horizontalAlignment == .left
                    || _legend.horizontalAlignment == .right
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
        
        legendTop += self.extraTopOffset
        legendRight += self.extraRightOffset
        legendBottom += self.extraBottomOffset
        legendLeft += self.extraLeftOffset
        
        var minOffset = self.minOffset
        
        if self is RadarChartView
        {
            let x = self.xAxis
            
            if x.isEnabled && x.drawLabelsEnabled
            {
                minOffset = max(minOffset, x.labelRotatedWidth)
            }
        }

        let offsetLeft = max(minOffset, legendLeft)
        let offsetTop = max(minOffset, legendTop)
        let offsetRight = max(minOffset, legendRight)
        let offsetBottom = max(minOffset, max(self.requiredBaseOffset, legendBottom))

        _viewPortHandler.restrainViewPort(offsetLeft: offsetLeft, offsetTop: offsetTop, offsetRight: offsetRight, offsetBottom: offsetBottom)
    }

    /// - Returns: The angle relative to the chart center for the given point on the chart in degrees.
    /// The angle is always between 0 and 360°, 0° is NORTH, 90° is EAST, ...
    open func angleForPoint(x: CGFloat, y: CGFloat) -> CGFloat
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
    open func getPosition(center: CGPoint, dist: CGFloat, angle: CGFloat) -> CGPoint
    {
        return CGPoint(x: center.x + dist * cos(angle.DEG2RAD),
                y: center.y + dist * sin(angle.DEG2RAD))
    }

    /// - Returns: The distance of a certain point on the chart to the center of the chart.
    open func distanceToCenter(x: CGFloat, y: CGFloat) -> CGFloat
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
    open func indexForAngle(_ angle: CGFloat) -> Int
    {
        fatalError("indexForAngle() cannot be called on PieRadarChartViewBase")
    }

    /// current rotation angle of the pie chart
    ///
    /// **default**: 270 --> top (NORTH)
    /// Will always return a normalized value, which will be between 0.0 < 360.0
    open var rotationAngle: CGFloat
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
    open var rawRotationAngle: CGFloat
    {
        return _rawRotationAngle
    }

    /// The diameter of the pie- or radar-chart
    open var diameter: CGFloat
    {
        var content = _viewPortHandler.contentRect
        content.origin.x += extraLeftOffset
        content.origin.y += extraTopOffset
        content.size.width -= extraLeftOffset + extraRightOffset
        content.size.height -= extraTopOffset + extraBottomOffset
        return min(content.width, content.height)
    }

    /// The radius of the chart in pixels.
    open var radius: CGFloat
    {
        fatalError("radius cannot be called on PieRadarChartViewBase")
    }

    /// The required offset for the chart legend.
    internal var requiredLegendOffset: CGFloat
    {
        fatalError("requiredLegendOffset cannot be called on PieRadarChartViewBase")
    }

    /// - Returns: The base offset needed for the chart without calculating the
    /// legend size.
    internal var requiredBaseOffset: CGFloat
    {
        fatalError("requiredBaseOffset cannot be called on PieRadarChartViewBase")
    }
    
    open override var chartYMax: Double
    {
        return 0.0
    }
    
    open override var chartYMin: Double
    {
        return 0.0
    }
    
    open var isRotationEnabled: Bool { return rotationEnabled }
    
    /// flag that indicates if rotation is done with two fingers or one.
    /// when the chart is inside a scrollview, you need a two-finger rotation because a one-finger rotation eats up all touch events.
    ///
    /// On iOS this will disable one-finger rotation.
    /// On OSX this will keep two-finger multitouch rotation, and one-pointer mouse rotation.
    /// 
    /// **default**: false
    open var rotationWithTwoFingers: Bool
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
    
    /// flag that indicates if rotation is done with two fingers or one.
    /// when the chart is inside a scrollview, you need a two-finger rotation because a one-finger rotation eats up all touch events.
    ///
    /// On iOS this will disable one-finger rotation.
    /// On OSX this will keep two-finger multitouch rotation, and one-pointer mouse rotation.
    ///
    /// **default**: false
    open var isRotationWithTwoFingers: Bool
    {
        return _rotationWithTwoFingers
    }
    
    // MARK: - Animation
    
    private var _spinAnimator: Animator!
    
    /// Applys a spin animation to the Chart.
    open func spin(duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat, easing: ChartEasingFunctionBlock?)
    {
        if _spinAnimator != nil
        {
            _spinAnimator.stop()
        }
        
        _spinAnimator = Animator()
        _spinAnimator.updateBlock = {
            self.rotationAngle = (toAngle - fromAngle) * CGFloat(self._spinAnimator.phaseX) + fromAngle
        }
        _spinAnimator.stopBlock = { self._spinAnimator = nil }
        
        _spinAnimator.animate(xAxisDuration: duration, easing: easing)
    }
    
    open func spin(duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat, easingOption: ChartEasingOption)
    {
        spin(duration: duration, fromAngle: fromAngle, toAngle: toAngle, easing: easingFunctionFromOption(easingOption))
    }
    
    open func spin(duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat)
    {
        spin(duration: duration, fromAngle: fromAngle, toAngle: toAngle, easing: nil)
    }
    
    open func stopSpinAnimation()
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
        if isDragDecelerationEnabled
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
        if isDragDecelerationEnabled
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
    open override func nsuiTouchesBegan(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
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
    
    open override func nsuiTouchesMoved(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
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
    
    open override func nsuiTouchesEnded(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
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
    
    open override func nsuiTouchesCancelled(_ touches: Set<NSUITouch>?, withEvent event: NSUIEvent?)
    {
        super.nsuiTouchesCancelled(touches, withEvent: event)
        
        processRotationGestureCancelled()
    }
    #endif
    
    #if os(OSX)
    open override func mouseDown(with theEvent: NSEvent)
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
    
    open override func mouseDragged(with theEvent: NSEvent)
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
    
    open override func mouseUp(with theEvent: NSEvent)
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
    
    open func stopDeceleration()
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
    
    /// reference to the last highlighted object
    private var _lastHighlight: Highlight!
    
    @objc private func tapGestureRecognized(_ recognizer: NSUITapGestureRecognizer)
    {
        if recognizer.state == NSUIGestureRecognizerState.ended
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
        if recognizer.state == NSUIGestureRecognizerState.began
        {
            stopDeceleration()
            
            _startAngle = self.rawRotationAngle
        }
        
        if recognizer.state == NSUIGestureRecognizerState.began || recognizer.state == NSUIGestureRecognizerState.changed
        {
            let angle = recognizer.nsuiRotation.RAD2DEG
            
            self.rotationAngle = _startAngle + angle
            setNeedsDisplay()
        }
        else if recognizer.state == NSUIGestureRecognizerState.ended
        {
            let angle = recognizer.nsuiRotation.RAD2DEG
            
            self.rotationAngle = _startAngle + angle
            setNeedsDisplay()
            
            if isDragDecelerationEnabled
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
}

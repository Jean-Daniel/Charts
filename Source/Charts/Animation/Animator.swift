//
//  Animator.swift
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

public protocol AnimatorDelegate : AnyObject
{
    /// Called when the Animator has stepped.
    func animatorUpdated(_ animator: Animator)
    
    /// Called when the Animator has stopped.
    func animatorStopped(_ animator: Animator)
}

open class Animator
{
    open weak var delegate: AnimatorDelegate?
    open var updateBlock: (() -> Void)?
    open var stopBlock: (() -> Void)?
    
    /// the phase that is animated and influences the drawn values on the x-axis
    open var phaseX: Double = 1.0
    
    /// the phase that is animated and influences the drawn values on the y-axis
    open var phaseY: Double = 1.0
    
    private var _startTimeX: TimeInterval = 0.0
    private var _startTimeY: TimeInterval = 0.0
    private var _displayLink: DisplayLink?
    
    private var _durationX: TimeInterval = 0.0
    private var _durationY: TimeInterval = 0.0
    
    private var _endTimeX: TimeInterval = 0.0
    private var _endTimeY: TimeInterval = 0.0
    private var _endTime: TimeInterval = 0.0
    
    private var _enabledX: Bool = false
    private var _enabledY: Bool = false
    
    private var _easingX: ChartEasingFunctionBlock?
    private var _easingY: ChartEasingFunctionBlock?

    public init()
    {
    }
    
    deinit
    {
        stop()
    }
    
    open func stop()
    {
        guard _displayLink != nil else { return }

        _displayLink?.stop()
        _displayLink = nil

        _enabledX = false
        _enabledY = false

        // If we stopped an animation in the middle, we do not want to leave it like this
        if phaseX != 1.0 || phaseY != 1.0
        {
            phaseX = 1.0
            phaseY = 1.0

            delegate?.animatorUpdated(self)
            updateBlock?()
        }

        delegate?.animatorStopped(self)
        stopBlock?()
    }
    
    private func updateAnimationPhases(_ currentTime: TimeInterval)
    {
        if _enabledX
        {
            let elapsedTime: TimeInterval = currentTime - _startTimeX
            let duration: TimeInterval = _durationX
            var elapsed: TimeInterval = elapsedTime
            if elapsed > duration
            {
                elapsed = duration
            }
           
            phaseX = _easingX?(elapsed, duration) ?? elapsed / duration
        }
        
        if _enabledY
        {
            let elapsedTime: TimeInterval = currentTime - _startTimeY
            let duration: TimeInterval = _durationY
            var elapsed: TimeInterval = elapsedTime
            if elapsed > duration
            {
                elapsed = duration
            }

            phaseY = _easingY?(elapsed, duration) ?? elapsed / duration
        }
    }
    
  private func animationLoop(_ targetTime: TimeInterval)
    {
        updateAnimationPhases(targetTime)

        delegate?.animatorUpdated(self)
        updateBlock?()
        
        if targetTime >= _endTime
        {
            stop()
        }
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - xAxisDuration: duration for animating the x axis
    ///   - yAxisDuration: duration for animating the y axis
    ///   - easingX: an easing function for the animation on the x axis
    ///   - easingY: an easing function for the animation on the y axis
    open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingX: ChartEasingFunctionBlock?, easingY: ChartEasingFunctionBlock?)
    {
        stop()
        
        _startTimeX = CACurrentMediaTime()
        _startTimeY = _startTimeX
        _durationX = xAxisDuration
        _durationY = yAxisDuration
        _endTimeX = _startTimeX + xAxisDuration
        _endTimeY = _startTimeY + yAxisDuration
        _endTime = _endTimeX > _endTimeY ? _endTimeX : _endTimeY
        _enabledX = xAxisDuration > 0.0
        _enabledY = yAxisDuration > 0.0
        
        _easingX = easingX
        _easingY = easingY
        
        // Take care of the first frame if rendering is already scheduled...
        updateAnimationPhases(_startTimeX)
        
        if _enabledX || _enabledY
        {
          _displayLink = DisplayLink(callback: self.animationLoop)
            let _ = _displayLink?.start()
        }
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - xAxisDuration: duration for animating the x axis
    ///   - yAxisDuration: duration for animating the y axis
    ///   - easingOptionX: the easing function for the animation on the x axis
    ///   - easingOptionY: the easing function for the animation on the y axis
    open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingOptionX: ChartEasingOption, easingOptionY: ChartEasingOption)
    {
        animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingX: easingFunctionFromOption(easingOptionX), easingY: easingFunctionFromOption(easingOptionY))
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - xAxisDuration: duration for animating the x axis
    ///   - yAxisDuration: duration for animating the y axis
    ///   - easing: an easing function for the animation
    open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
    {
        animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingX: easing, easingY: easing)
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - xAxisDuration: duration for animating the x axis
    ///   - yAxisDuration: duration for animating the y axis
    ///   - easingOption: the easing function for the animation
    open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingOption: ChartEasingOption = .easeInOutSine)
    {
        animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easing: easingFunctionFromOption(easingOption))
    }

    /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - xAxisDuration: duration for animating the x axis
    ///   - easing: an easing function for the animation
    open func animate(xAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
    {
        _startTimeX = CACurrentMediaTime()
        _durationX = xAxisDuration
        _endTimeX = _startTimeX + xAxisDuration
        _endTime = _endTimeX > _endTimeY ? _endTimeX : _endTimeY
        _enabledX = xAxisDuration > 0.0
        
        _easingX = easing
        
        // Take care of the first frame if rendering is already scheduled...
        updateAnimationPhases(_startTimeX)
        
        if _enabledX || _enabledY, _displayLink == nil
        {
            _displayLink = DisplayLink(callback: self.animationLoop)
            let _ = _displayLink?.start()
        }
    }
    
    /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - xAxisDuration: duration for animating the x axis
    ///   - easingOption: the easing function for the animation
    open func animate(xAxisDuration: TimeInterval, easingOption: ChartEasingOption = .easeInOutSine)
    {
        animate(xAxisDuration: xAxisDuration, easing: easingFunctionFromOption(easingOption))
    }

    /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - yAxisDuration: duration for animating the y axis
    ///   - easing: an easing function for the animation
    open func animate(yAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
    {
        _startTimeY = CACurrentMediaTime()
        _durationY = yAxisDuration
        _endTimeY = _startTimeY + yAxisDuration
        _endTime = _endTimeX > _endTimeY ? _endTimeX : _endTimeY
        _enabledY = yAxisDuration > 0.0
        
        _easingY = easing
        
        // Take care of the first frame if rendering is already scheduled...
        updateAnimationPhases(_startTimeY)
        
        if _enabledX || _enabledY,
            _displayLink == nil
        {
            _displayLink = DisplayLink(callback: self.animationLoop)
            let _ = _displayLink?.start()
        }
    }
    
    /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    ///
    /// - Parameters:
    ///   - yAxisDuration: duration for animating the y axis
    ///   - easingOption: the easing function for the animation
    open func animate(yAxisDuration: TimeInterval, easingOption: ChartEasingOption = .easeInOutSine)
    {
        animate(yAxisDuration: yAxisDuration, easing: easingFunctionFromOption(easingOption))
    }
}

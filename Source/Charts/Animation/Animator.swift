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

public class Animator
{
    public weak var delegate: AnimatorDelegate?
    public var updateBlock: ((Double) -> Void)?
    public var stopBlock: (() -> Void)?

    /// the phase that is animated and influences the drawn values on the y-axis
    public var phase: Double = 1.0

    private var _startTime: TimeInterval = 0.0
    private var _displayLink: DisplayLink?

    private var _duration: TimeInterval = 0.0

    private var _endTime: TimeInterval = 0.0

    private var _enabled: Bool = false

    private var _easing: ChartEasingFunctionBlock?

    public init()
    {
    }
    
    deinit
    {
        stop()
    }
    
    public func stop()
    {
        guard _displayLink != nil else { return }

        _displayLink?.stop()
        _displayLink = nil

        _enabled = false

        // If we stopped an animation in the middle, we do not want to leave it like this
        if phase != 1.0
        {
            phase = 1.0

            delegate?.animatorUpdated(self)
            updateBlock?(phase)
        }

        delegate?.animatorStopped(self)
        stopBlock?()
    }
    
    private func updateAnimationPhases(_ currentTime: TimeInterval)
    {
        if _enabled
        {
            let elapsedTime: TimeInterval = currentTime - _startTime
            let duration: TimeInterval = _duration
            var elapsed: TimeInterval = elapsedTime
            if elapsed > duration
            {
                elapsed = duration
            }

            phase = _easing?(elapsed, duration) ?? elapsed / duration
        }
    }
    
  private func animationLoop(_ targetTime: TimeInterval)
    {
        updateAnimationPhases(targetTime)

        delegate?.animatorUpdated(self)
        updateBlock?(phase)
        
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
    public func animate(duration: TimeInterval, easing: ChartEasingFunctionBlock?)
    {
        stop()

        _startTime = CACurrentMediaTime()
        _duration = duration
        _endTime = _startTime + duration
        _enabled = duration > 0.0

        _easing = easing
        
        // Take care of the first frame if rendering is already scheduled...
        updateAnimationPhases(_startTime)
        
        if _enabled, _displayLink == nil
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
    ///   - easingOption: the easing function for the animation
    public func animate(duration: TimeInterval, easing: ChartEasingOption = .easeInOutSine)
    {
        animate(duration: duration, easing: easingFunctionFromOption(easing))
    }
}

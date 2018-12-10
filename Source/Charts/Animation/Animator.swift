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

import os

#if !os(OSX)
import UIKit
#endif

public class Animator
{
  public var progressBlock: ((Double?) -> Void)?

  #if os(macOS)
  private class Animation : NSAnimation {
    private var _easing: ChartEasingFunctionBlock?
    private let progressBlock: ((Double?) -> Void)

    init(duration: TimeInterval, animationCurve: NSAnimation.Curve, progress: @escaping ((Double?) -> Void), easing: ChartEasingFunctionBlock?) {
      self.progressBlock = progress
      self._easing = easing
      super.init(duration: duration, animationCurve: animationCurve)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override var currentProgress: NSAnimation.Progress {
      didSet {
        progressBlock(Double(currentValue))
        if currentProgress >= 1.0 {
          stop()
        }
      }
    }

    override var currentValue: Float {
      if let easing = _easing {
        return Float(easing(Double(currentProgress)))
      }
      return super.currentValue
    }
    
    override func stop() {
      super.stop()
      progressBlock(nil)
    }
  }

  /// the phase that is animated and influences the drawn values on the y-axis
  private var _animation : NSAnimation?

  public var phase: Double {
    return Double(_animation?.currentValue ?? 1.0)
  }
  #else
  private var _startTime: TimeInterval = 0.0
  private var _displayLink: DisplayLink?

  private var _duration: TimeInterval = 0.0

  private var _endTime: TimeInterval = 0.0

  private var _enabled: Bool = false

  private var _easing: ChartEasingFunctionBlock?

  public var phase: Double = 1.0

  #endif

  public init()
  {
  }

  deinit
  {
    stop()
  }

  public func stop()
  {
    #if os(macOS)
    _animation?.stop()
    _animation = nil
    #else
    guard _displayLink != nil else { return }

    _displayLink?.stop()
    _displayLink = nil

    _enabled = false

    // If we stopped an animation in the middle, we do not want to leave it like this
    if phase != 1.0
    {
      phase = 1.0

      progressBlock?(1.0)
    }

    progressBlock?(nil)
    #endif
  }

  #if !os(macOS)
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

      let progress = elapsed / duration
      phase = _easing?(progress) ?? progress
    }
  }

  private func animationLoop(_ targetTime: TimeInterval)
  {
    updateAnimationPhases(targetTime)

    progressBlock?(phase)

    if targetTime >= _endTime
    {
      stop()
    }
  }
  #endif

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
    #if os(macOS)
    _animation?.stop()
    _animation = nil

    if let block = progressBlock {
      _animation = Animation(duration: duration, animationCurve: .linear, progress: block, easing: easing)
      if (easing == nil) {
        _animation?.animationCurve = .easeInOut
      }
      //_animation?.animationBlockingMode = .nonblocking
      _animation?.start()
    }
    #else
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
    #endif
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

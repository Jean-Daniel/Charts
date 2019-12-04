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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public class Animator
{
  public var progressBlock: ((Double?) -> Void)?

  #if os(macOS)
  private class Animation : NSAnimation {
    private var _easing: ChartEasingFunctionBlock?
    private let progressBlock: ((Double?) -> Void)

    init(duration: TimeInterval, easing: ChartEasingFunctionBlock?, progress: @escaping ((Double?) -> Void)) {
      self.progressBlock = progress
      self._easing = easing
      super.init(duration: duration, animationCurve: easing != nil ? .linear : .easeInOut)
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
      if isAnimating {
        super.stop()
        progressBlock(nil)
      }
    }
  }
  #else
  private class Animation : NSObject {

    private var _displayLink: CADisplayLink!

    private var _duration: TimeInterval = 0

    private var _startTimestamp : TimeInterval = 0

    private(set) var currentProgress: Float = 1.0

    private var _running = false

    private var _easing: ChartEasingFunctionBlock
    private let progressBlock: ((Double?) -> Void)

    init(duration: TimeInterval, easing: ChartEasingFunctionBlock?, progress: @escaping ((Double?) -> Void)) {
      _duration = duration
      progressBlock = progress
      _easing = easing ?? easingFunctionFromOption(.easeInOutSine)

      super.init()
      
      _displayLink = CADisplayLink(target: self, selector: #selector(animationProgress(_:)))
    }

    func start() {
      guard !_running else { return }

      currentProgress = 0
      _startTimestamp = CACurrentMediaTime()
      _running = true

      // TODO: Should we call the callback a first time here ?

      _displayLink.add(to: .main, forMode: .common)
    }

    @objc
    func animationProgress(_ link: CADisplayLink) {
      let elapsed = min(link.targetTimestamp - _startTimestamp, _duration)
      currentProgress = Float(elapsed / _duration)
      progressBlock(Double(currentValue))
      if currentProgress >= 1.0 {
        stop()
      }
    }

    func stop() {
      guard _running else { return }

      _displayLink.remove(from: .main, forMode: .common)
      _running = false

      // If we stopped an animation in the middle, we do not want to leave it like this
      if currentProgress != 1.0 {
        currentProgress = 1.0

        progressBlock(1.0)
      }

      progressBlock(nil)
    }

    var currentValue: Float {
      return Float(_easing(Double(currentProgress)))
    }
  }

  #endif

  /// the phase that is animated and influences the drawn values on the y-axis
  private var _animation : Animation?

  public var phase: Double {
    return Double(_animation?.currentValue ?? 1.0)
  }

  public init()
  {
  }

  deinit
  {
    stop()
  }

  public func stop()
  {
    _animation?.stop()
    _animation = nil
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
    _animation?.stop()
    _animation = nil

    if let block = progressBlock {
      _animation = Animation(duration: duration, easing: easing, progress: block)
      //_animation?.animationBlockingMode = .nonblocking
      _animation?.start()
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

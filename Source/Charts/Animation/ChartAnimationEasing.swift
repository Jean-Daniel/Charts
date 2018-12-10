//
//  ChartAnimationUtils.swift
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

public enum ChartEasingOption
{
  case linear
  case easeInQuad
  case easeOutQuad
  case easeInOutQuad
  case easeInCubic
  case easeOutCubic
  case easeInOutCubic
  case easeInQuart
  case easeOutQuart
  case easeInOutQuart
  case easeInQuint
  case easeOutQuint
  case easeInOutQuint
  case easeInSine
  case easeOutSine
  case easeInOutSine
  case easeInExpo
  case easeOutExpo
  case easeInOutExpo
  case easeInCirc
  case easeOutCirc
  case easeInOutCirc
  case easeInElastic
  case easeOutElastic
  case easeInOutElastic
  case easeInBack
  case easeOutBack
  case easeInOutBack
  case easeInBounce
  case easeOutBounce
  case easeInOutBounce
}

public typealias ChartEasingFunctionBlock = ((_ progress: TimeInterval) -> Double)

internal func easingFunctionFromOption(_ easing: ChartEasingOption) -> ChartEasingFunctionBlock
{
  switch easing
  {
  case .linear:
    return EasingFunctions.Linear
  case .easeInQuad:
    return EasingFunctions.EaseInQuad
  case .easeOutQuad:
    return EasingFunctions.EaseOutQuad
  case .easeInOutQuad:
    return EasingFunctions.EaseInOutQuad
  case .easeInCubic:
    return EasingFunctions.EaseInCubic
  case .easeOutCubic:
    return EasingFunctions.EaseOutCubic
  case .easeInOutCubic:
    return EasingFunctions.EaseInOutCubic
  case .easeInQuart:
    return EasingFunctions.EaseInQuart
  case .easeOutQuart:
    return EasingFunctions.EaseOutQuart
  case .easeInOutQuart:
    return EasingFunctions.EaseInOutQuart
  case .easeInQuint:
    return EasingFunctions.EaseInQuint
  case .easeOutQuint:
    return EasingFunctions.EaseOutQuint
  case .easeInOutQuint:
    return EasingFunctions.EaseInOutQuint
  case .easeInSine:
    return EasingFunctions.EaseInSine
  case .easeOutSine:
    return EasingFunctions.EaseOutSine
  case .easeInOutSine:
    return EasingFunctions.EaseInOutSine
  case .easeInExpo:
    return EasingFunctions.EaseInExpo
  case .easeOutExpo:
    return EasingFunctions.EaseOutExpo
  case .easeInOutExpo:
    return EasingFunctions.EaseInOutExpo
  case .easeInCirc:
    return EasingFunctions.EaseInCirc
  case .easeOutCirc:
    return EasingFunctions.EaseOutCirc
  case .easeInOutCirc:
    return EasingFunctions.EaseInOutCirc
  case .easeInElastic:
    return EasingFunctions.EaseInElastic
  case .easeOutElastic:
    return EasingFunctions.EaseOutElastic
  case .easeInOutElastic:
    return EasingFunctions.EaseInOutElastic
  case .easeInBack:
    return EasingFunctions.EaseInBack
  case .easeOutBack:
    return EasingFunctions.EaseOutBack
  case .easeInOutBack:
    return EasingFunctions.EaseInOutBack
  case .easeInBounce:
    return EasingFunctions.EaseInBounce
  case .easeOutBounce:
    return EasingFunctions.EaseOutBounce
  case .easeInOutBounce:
    return EasingFunctions.EaseInOutBounce
  }
}

internal struct EasingFunctions
{
  internal static let Linear = { (progress: Double) -> Double in return progress }

  internal static let EaseInQuad = { (progress: Double) -> Double in
    return progress * progress
  }

  internal static let EaseOutQuad = { (progress: Double) -> Double in
    return -progress * (progress - 2.0)
  }

  internal static let EaseInOutQuad = { (progress: Double) -> Double in
    var position = progress * 2.0
    if position < 1.0
    {
      return 0.5 * position * position
    }

    return -0.5 * ((position - 1.0) * (position - 3.0) - 1.0)
  }

  internal static let EaseInCubic = { (progress: Double) -> Double in
    return progress * progress * progress
  }

  internal static let EaseOutCubic = { (progress: Double) -> Double in
    var position = progress - 1.0
    return (position * position * position + 1.0)
  }

  internal static let EaseInOutCubic = { (progress: Double) -> Double in
    var position = progress * 2.0
    if position < 1.0
    {
      return 0.5 * position * position * position
    }
    position -= 2.0
    return 0.5 * (position * position * position + 2.0)
  }

  internal static let EaseInQuart = { (progress: Double) -> Double in
    return progress * progress * progress * progress
  }

  internal static let EaseOutQuart = { (progress: Double) -> Double in
    var position = progress - 1.0
    return -(position * position * position * position - 1.0)
  }

  internal static let EaseInOutQuart = { (progress: Double) -> Double in
    var position = progress * 2.0
    if position < 1.0
    {
      return 0.5 * position * position * position * position
    }
    position -= 2.0
    return -0.5 * (position * position * position * position - 2.0)
  }

  internal static let EaseInQuint = { (progress: Double) -> Double in
    return progress * progress * progress * progress * progress
  }

  internal static let EaseOutQuint = { (progress: Double) -> Double in
    var position = progress - 1.0
    return (position * position * position * position * position + 1.0)
  }

  internal static let EaseInOutQuint = { (progress: Double) -> Double in
    var position = progress * 2.0
    if position < 1.0
    {
      return 0.5 * position * position * position * position * position
    }
    else
    {
      position -= 2.0
      return 0.5 * (position * position * position * position * position + 2.0)
    }
  }

  internal static let EaseInSine = { (progress: Double) -> Double in
    return Double( -cos(progress * Double.pi / 2) + 1.0 )
  }

  internal static let EaseOutSine = { (progress: Double) -> Double in
    return Double( sin(progress * Double.pi / 2) )
  }

  internal static let EaseInOutSine = { (progress: Double) -> Double in
    return Double( -0.5 * (cos(Double.pi * progress) - 1.0) )
  }

  internal static let EaseInExpo = { (progress: Double) -> Double in
    return (progress <= 0) ? 0.0 : Double(pow(2.0, 10.0 * (progress - 1.0)))
  }

  internal static let EaseOutExpo = { (progress: Double) -> Double in
    return (progress >= 1.0) ? 1.0 : (-Double(pow(2.0, -10.0 * progress)) + 1.0)
  }

  internal static let EaseInOutExpo = { (progress: Double) -> Double in
    if progress <= 0
    {
      return 0.0
    }
    if progress >= 1.0
    {
      return 1.0
    }

    var position = progress * 2.0
    if position < 1.0
    {
      return Double( 0.5 * pow(2.0, 10.0 * (position - 1.0)) )
    }

    position = position - 1.0
    return Double( 0.5 * (-pow(2.0, -10.0 * position) + 2.0) )
  }

  internal static let EaseInCirc = { (progress: Double) -> Double in
    return -(Double(sqrt(1.0 - progress * progress)) - 1.0)
  }

  internal static let EaseOutCirc = { (progress: Double) -> Double in
    var position = progress - 1.0
    return Double( sqrt(1 - position * position) )
  }

  internal static let EaseInOutCirc = { (progress: Double) -> Double in
    var position = progress * 2.0
    if position < 1.0
    {
      return Double( -0.5 * (sqrt(1.0 - position * position) - 1.0) )
    }
    position -= 2.0
    return Double( 0.5 * (sqrt(1.0 - position * position) + 1.0) )
  }

  internal static let EaseInElastic = { (progress: Double) -> Double in
    if progress <= 0.0
    {
      return 0.0
    }

    if progress >= 1.0
    {
      return 1.0
    }

    let position = progress - 1.0
    var p = 1.0 * 0.3

    var s = p / (2.0 * Double.pi) * asin(1.0)

    return Double( -(pow(2.0, 10.0 * position) * sin((position - s) * (2.0 * Double.pi) / p)) )
  }

  internal static let EaseOutElastic = { (progress: Double) -> Double in
    if progress <= 0.0
    {
      return 0.0
    }

    if progress >= 1.0
    {
      return 1.0
    }

    var p = 1.0 * 0.3
    var s = p / (2.0 * Double.pi) * asin(1.0)
    return Double( pow(2.0, -10.0 * progress) * sin((progress - s) * (2.0 * Double.pi) / p) + 1.0 )
  }

  internal static let EaseInOutElastic = { (progress: Double) -> Double in
    if progress <= 0.0
    {
      return 0.0
    }

    if progress >= 1.0
    {
      return 1.0
    }
    var position = progress * 2.0
    var p = 0.3 * 1.5
    var s = p / (2.0 * Double.pi) * asin(1.0)
    if position < 1.0
    {
      position -= 1.0
      return Double( -0.5 * (pow(2.0, 10.0 * position) * sin((position - s) * (2.0 * Double.pi) / p)) )
    }
    position -= 1.0
    return Double( pow(2.0, -10.0 * position) * sin((position - s) * (2.0 * Double.pi) / p) * 0.5 + 1.0 )
  }

  internal static let EaseInBack = { (progress: Double) -> Double in
    let s: Double = 1.70158
    return Double( progress * progress * ((s + 1.0) * progress - s) )
  }

  internal static let EaseOutBack = { (progress: Double) -> Double in
    let s: Double = 1.70158
    var position = progress - 1.0
    return Double( position * position * ((s + 1.0) * position + s) + 1.0 )
  }

  internal static let EaseInOutBack = { (progress: Double) -> Double in
    var s: Double = 1.70158
    var position = progress * 2.0
    if position < 1.0
    {
      s *= 1.525
      return Double( 0.5 * (position * position * ((s + 1.0) * position - s)) )
    }
    s *= 1.525
    position -= 2.0
    return Double( 0.5 * (position * position * ((s + 1.0) * position + s) + 2.0) )
  }

  internal static let EaseInBounce = { (progress: Double) -> Double in
    return 1.0 - EaseOutBounce(1.0 - progress)
  }

  internal static let EaseOutBounce = { (progress: Double) -> Double in
    var position = progress
    if position < (1.0 / 2.75)
    {
      return Double( 7.5625 * position * position )
    }
    else if position < (2.0 / 2.75)
    {
      position -= (1.5 / 2.75)
      return Double( 7.5625 * position * position + 0.75 )
    }
    else if position < (2.5 / 2.75)
    {
      position -= (2.25 / 2.75)
      return Double( 7.5625 * position * position + 0.9375 )
    }
    else
    {
      position -= (2.625 / 2.75)
      return Double( 7.5625 * position * position + 0.984375 )
    }
  }

  internal static let EaseInOutBounce = { (progress: Double) -> Double in
    if progress < 0.5
    {
      return EaseInBounce(progress * 2.0) * 0.5
    }
    return EaseOutBounce(progress * 2.0 - 1.0) * 0.5 + 0.5
  }
}

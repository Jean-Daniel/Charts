//
//  Highlight.swift
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

public struct Highlight
{
  /// the x-value of the highlighted value
  fileprivate let _value: Int

  init(value: Int) {
    _value = value
  }

  var value: Int { return _value }
}

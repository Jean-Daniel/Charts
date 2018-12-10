//
//  ChartDataEntryBase.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

open class ChartDataEntry
{
  /// the y value
  public var value = Double(0.0)

  public var label: String?

  public init(value: Double, label: String) {
    self.value = value
    self.label = label
  }
}

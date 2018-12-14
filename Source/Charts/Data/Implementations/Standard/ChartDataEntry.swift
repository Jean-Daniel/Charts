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

public struct ChartDataEntry
{

  public let label: String?
  /// the y value
  public let value : Double

  public init(label: String, value: Double) {
    self.value = value
    self.label = label
  }
}

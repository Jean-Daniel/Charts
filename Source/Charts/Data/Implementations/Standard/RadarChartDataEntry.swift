//
//  RadarChartDataEntry.swift
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

open class RadarChartDataEntry: ChartDataEntry
{
    public required init()
    {
        super.init()
    }
    
    /// - Parameters:
    ///   - value: The value on the y-axis.
    ///   - data: Spot for additional data this Entry represents.
    public init(value: Double, data: AnyObject?)
    {
        super.init(x: 0.0, y: value, data: data)
    }
    
    /// - Parameters:
    ///   - value: The value on the y-axis.
    public convenience init(value: Double)
    {
        self.init(value: value, data: nil)
    }
    
    // MARK: Data property accessors
    
    open var value: Double
    {
        get { return y }
        set { y = value }
    }
}

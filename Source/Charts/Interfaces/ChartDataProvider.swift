//
//  ChartDataProvider.swift
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

public protocol ChartDataProvider : AnyObject
{   
    var maxHighlightDistance: CGFloat { get }
    
    var centerOffsets: CGPoint { get }
    
    var data: PieChartData? { get }
    
    var maxVisibleCount: Int { get }
}

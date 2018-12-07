//
//  PieChartDataSet.swift
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

public class PieChartDataSet: ChartDataSet, IPieChartDataSet
{
    public enum ValuePosition
    {
        case insideSlice
        case outsideSlice
    }

    private func initialize()
    {
        self.valueTextColor = NSUIColor(named: "pie_value", bundle: Bundle(for: PieChartDataSet.self))!
        self.valueFont = NSUIFont.systemFont(ofSize: 13.0)
    }

    public required init()
    {
        super.init()
        initialize()
    }

    public override init(values: [ChartDataEntry]?, label: String?)
    {
        super.init(values: values, label: label)
        initialize()
    }

    internal override func calcMinMax(entry e: ChartDataEntry)
    {
        calcMinMaxY(entry: e)
    }

    // MARK: - Styling functions and accessors

    private var _sliceSpace = CGFloat(0.0)

    /// the space in pixels between the pie-slices
    /// **default**: 0
    /// **maximum**: 20
    public var sliceSpace: CGFloat
    {
        get
        {
            return _sliceSpace
        }
        set
        {
            var space = newValue
            if space > 20.0
            {
                space = 20.0
            }
            if space < 0.0
            {
                space = 0.0
            }
            _sliceSpace = space
        }
    }

    /// When enabled, slice spacing will be 0.0 when the smallest value is going to be smaller than the slice spacing itself.
    public var automaticallyDisableSliceSpacing: Bool = false

    /// indicates the selection distance of a pie slice
    public var selectionShift = CGFloat(18.0)

    public var xValuePosition: ValuePosition = .insideSlice
    public var yValuePosition: ValuePosition = .insideSlice

    /// When valuePosition is OutsideSlice, indicates line color
    public var valueLineColor: NSUIColor? = NSUIColor.black

    /// When valuePosition is OutsideSlice, indicates line width
    public var valueLineWidth: CGFloat = 1.0

    /// When valuePosition is OutsideSlice, indicates offset as percentage out of the slice size
    public var valueLinePart1OffsetPercentage: CGFloat = 0.75

    /// When valuePosition is OutsideSlice, indicates length of first half of the line
    public var valueLinePart1Length: CGFloat = 0.3

    /// When valuePosition is OutsideSlice, indicates length of second half of the line
    public var valueLinePart2Length: CGFloat = 0.4

    /// When valuePosition is OutsideSlice, this allows variable line length
    public var valueLineVariableLength: Bool = true

    /// the font for the slice-text labels
    public var entryLabelFont: NSUIFont? = nil

    /// the color for the slice-text labels
    public var entryLabelColor: NSUIColor? = nil

    /// the color for the highlighted sector
    public var highlightColor: NSUIColor? = nil
}

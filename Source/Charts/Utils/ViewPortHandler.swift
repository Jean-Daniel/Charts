//
//  ViewPortHandler.swift
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

/// Class that contains information about the charts current viewport settings, including offsets, scale & translation levels, ...
public class ViewPortHandler
{
    /// this rectangle defines the area in which graph values can be drawn
    private var _contentRect = CGRect()

    private var _chartWidth = CGFloat(0.0)
    private var _chartHeight = CGFloat(0.0)

    /// Constructor - don't forget calling setChartDimens(...)
    public init(_ chartDimension: CGSize)
    {
        setChartDimens(chartDimension)
    }

    func setChartDimens(_ size: CGSize)
    {
        let offsetLeft = self.offsetLeft
        let offsetTop = self.offsetTop
        let offsetRight = self.offsetRight
        let offsetBottom = self.offsetBottom

        _chartHeight = size.height
        _chartWidth = size.width

        restrainViewPort(offsetLeft: offsetLeft, offsetTop: offsetTop, offsetRight: offsetRight, offsetBottom: offsetBottom)
    }

    func restrainViewPort(offsetLeft: CGFloat, offsetTop: CGFloat, offsetRight: CGFloat, offsetBottom: CGFloat)
    {
        _contentRect.origin.x = offsetLeft
        _contentRect.origin.y = offsetTop
        _contentRect.size.width = _chartWidth - offsetLeft - offsetRight
        _contentRect.size.height = _chartHeight - offsetBottom - offsetTop
    }

    public var offsetLeft: CGFloat
    {
        return _contentRect.origin.x
    }

    public var offsetRight: CGFloat
    {
        return _chartWidth - _contentRect.size.width - _contentRect.origin.x
    }

    public var offsetTop: CGFloat
    {
        return _contentRect.origin.y
    }

    public var offsetBottom: CGFloat
    {
        return _chartHeight - _contentRect.size.height - _contentRect.origin.y
    }

    public var contentTop: CGFloat
    {
        return _contentRect.origin.y
    }

    public var contentLeft: CGFloat
    {
        return _contentRect.origin.x
    }

    public var contentRight: CGFloat
    {
        return _contentRect.origin.x + _contentRect.size.width
    }

    public var contentBottom: CGFloat
    {
        return _contentRect.origin.y + _contentRect.size.height
    }

    public var contentWidth: CGFloat
    {
        return _contentRect.size.width
    }

    public var contentHeight: CGFloat
    {
        return _contentRect.size.height
    }

    public var contentRect: CGRect
    {
        return _contentRect
    }

    public var contentCenter: CGPoint
    {
        return CGPoint(x: _contentRect.origin.x + _contentRect.size.width / 2.0, y: _contentRect.origin.y + _contentRect.size.height / 2.0)
    }

    public var chartHeight: CGFloat
    {
        return _chartHeight
    }

    public var chartWidth: CGFloat
    {
        return _chartWidth
    }
}

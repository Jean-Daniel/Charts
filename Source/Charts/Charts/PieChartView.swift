//
//  PieChartView.swift
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

#if !os(OSX)
    import UIKit
#endif

/// View that represents a pie chart. Draws cake like slices.
open class PieChartView: PieRadarChartViewBase
{
    /// rect object that represents the bounds of the piechart, needed for drawing the circle
    private var _circleBox = CGRect()

    /// array that holds the width of each pie-slice in degrees
    private var _drawAngles = [CGFloat]()
    
    /// array that holds the absolute angle in degrees of each slice
    private var _absoluteAngles = [CGFloat]()

    /// maximum angle for this pie
    private var _maxAngle: CGFloat = 360.0

    public override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    internal override func initialize()
    {
        super.initialize()
        
        renderer = PieChartRenderer(chart: self, animator: _animator, viewPortHandler: _viewPortHandler)
        
        self.highlighter = PieHighlighter(chart: self)
    }
    
    open override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
        if _data == nil
        {
            return
        }
        
        guard let context = NSUIGraphicsGetCurrentContext(), let renderer = renderer else
        {
            return
        }
        
        renderer.drawData(context: context)
        
        if (valuesToHighlight())
        {
            renderer.drawHighlighted(context: context, indices: _indicesToHighlight)
        }
        
        renderer.drawExtras(context: context)
        
        renderer.drawValues(context: context)
        
        legendRenderer.renderLegend(context: context)
        
        drawDescription(context: context)
        
        drawMarkers(context: context)
    }
    
    internal override func calculateOffsets()
    {
        super.calculateOffsets()
        
        // prevent nullpointer when no data set
        if _data == nil
        {
            return
        }
        
        let radius = diameter / 2.0
        
        let c = self.centerOffsets
        
        let shift = (data as? PieChartData)?.dataSet?.selectionShift ?? 0.0
        
        // create the circle box that will contain the pie-chart (the bounds of the pie-chart)
        _circleBox.origin.x = (c.x - radius) + shift
        _circleBox.origin.y = (c.y - radius) + shift
        _circleBox.size.width = diameter - shift * 2.0
        _circleBox.size.height = diameter - shift * 2.0
    }
    
    internal override func calcMinMax()
    {
        calcAngles()
    }
    
    open override func getMarkerPosition(highlight: Highlight) -> CGPoint
    {
        let center = self.centerCircleBox
        var r = self.radius
        
        var off = r / 10.0 * 3.6
        
        if self.drawsHole
        {
            off = (r - (r * self.holeRadiusRatio)) / 2.0
        }
        
        r -= off // offset to keep things inside the chart
        
        let rotationAngle = self.rotationAngle
        
        let entryIndex = Int(highlight.x)
        
        // offset needed to center the drawn text in the slice
        let offset = drawAngles[entryIndex] / 2.0
        
        // calculate the text position
        let x: CGFloat = (r * cos(((rotationAngle + absoluteAngles[entryIndex] - offset) * CGFloat(_animator.phaseY)).DEG2RAD) + center.x)
        let y: CGFloat = (r * sin(((rotationAngle + absoluteAngles[entryIndex] - offset) * CGFloat(_animator.phaseY)).DEG2RAD) + center.y)
        
        return CGPoint(x: x, y: y)
    }
    
    /// calculates the needed angles for the chart slices
    private func calcAngles()
    {
        _drawAngles = [CGFloat]()
        _absoluteAngles = [CGFloat]()
        
        guard let data = _data else { return }

        let entryCount = data.entryCount
        
        _drawAngles.reserveCapacity(entryCount)
        _absoluteAngles.reserveCapacity(entryCount)
        
        let yValueSum = (_data as! PieChartData).yValueSum
        
        var dataSets = data.dataSets

        var cnt = 0

        for i in 0 ..< data.dataSetCount
        {
            let set = dataSets[i]
            let entryCount = set.entryCount

            for j in 0 ..< entryCount
            {
                guard let e = set.entryForIndex(j) else { continue }
                
                _drawAngles.append(calcAngle(value: abs(e.y), yValueSum: yValueSum))

                if cnt == 0
                {
                    _absoluteAngles.append(_drawAngles[cnt])
                }
                else
                {
                    _absoluteAngles.append(_absoluteAngles[cnt - 1] + _drawAngles[cnt])
                }

                cnt += 1
            }
        }
    }
    
    /// Checks if the given index is set to be highlighted.
    open func needsHighlight(index: Int) -> Bool
    {
        // no highlight
        if !valuesToHighlight()
        {
            return false
        }
        
        for i in 0 ..< _indicesToHighlight.count
        {
            // check if the xvalue for the given dataset needs highlight
            if Int(_indicesToHighlight[i].x) == index
            {
                return true
            }
        }
        
        return false
    }
    
    /// calculates the needed angle for a given value
    private func calcAngle(_ value: Double) -> CGFloat
    {
        return calcAngle(value: value, yValueSum: (_data as! PieChartData).yValueSum)
    }
    
    /// calculates the needed angle for a given value
    private func calcAngle(value: Double, yValueSum: Double) -> CGFloat
    {
        return CGFloat(value) / CGFloat(yValueSum) * _maxAngle
    }

    /// This will throw an exception, PieChart has no XAxis object.
    open override var xAxis: XAxis?
    {
        return nil
    }

    open override func indexForAngle(_ angle: CGFloat) -> Int
    {
        // take the current angle of the chart into consideration
        let a = (angle - self.rotationAngle).normalizedAngle
        for i in 0 ..< _absoluteAngles.count
        {
            if _absoluteAngles[i] > a
            {
                return i
            }
        }
        
        return -1 // return -1 if no index found
    }
    
    /// - Returns: The index of the DataSet this x-index belongs to.
    open func dataSetIndexForIndex(_ xValue: Double) -> Int
    {
        var dataSets = _data?.dataSets ?? []
        
        for i in 0 ..< dataSets.count
        {
            if (dataSets[i].entryForXValue(xValue, closestToY: Double.nan) != nil)
            {
                return i
            }
        }
        
        return -1
    }
    
    /// - Returns: An integer array of all the different angles the chart slices
    /// have the angles in the returned array determine how much space (of 360°)
    /// each slice takes
    open var drawAngles: [CGFloat]
    {
        return _drawAngles
    }

    /// - Returns: The absolute angles of the different chart slices (where the
    /// slices end)
    open var absoluteAngles: [CGFloat]
    {
        return _absoluteAngles
    }
    
    /// The color for the hole that is drawn in the center of the PieChart (if enabled).
    /// 
    /// - Note: Use holeTransparent with holeColor = nil to make the hole transparent.*
    open var holeColor: NSUIColor? = NSUIColor(named: "pie_hole", bundle: Bundle(for: PieChartView.self))
    {
        didSet { setNeedsDisplay() }
    }
    
    /// if true, the hole will see-through to the inner tips of the slices
    ///
    /// **default**: `false`
    open var drawsSlicesUnderHole: Bool = false
    {
      didSet { setNeedsDisplay() }
    }
    
    /// `true` if the hole in the center of the pie-chart is set to be visible, `false` ifnot
    open var drawsHole: Bool = true
    {
      didSet { setNeedsDisplay() }
    }
    
    /// the text that is displayed in the center of the pie-chart
    open var centerText: String?
    {
        get
        {
            return self.centerAttributedText?.string
        }
        set
        {
            var attrString: NSMutableAttributedString?
            if newValue == nil
            {
                attrString = nil
            }
            else
            {
                #if os(OSX)
                    let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
                #else
                    let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
                #endif
                paragraphStyle.alignment = .center
                
                attrString = NSMutableAttributedString(string: newValue!)
                attrString?.setAttributes([
                    .foregroundColor: NSUIColor(named: "pie_center_text", bundle: Bundle(for: PieChartView.self))!,
                    .font: NSUIFont.systemFont(ofSize: 12.0),
                    .paragraphStyle: paragraphStyle
                    ], range: NSMakeRange(0, attrString!.length))
            }
            self.centerAttributedText = attrString
        }
    }
    
    /// the text that is displayed in the center of the pie-chart
    open var centerAttributedText: NSAttributedString?
    {
        didSet { setNeedsDisplay() }
    }
    
    /// Sets the offset the center text should have from it's original position in dp. Default x = 0, y = 0
    open var centerTextOffset: CGPoint = CGPoint.zero
    {
        didSet { setNeedsDisplay() }
    }
    
    /// `true` if drawing the center text is enabled
    open var drawsCenterText: Bool = true
    {
        didSet { setNeedsDisplay() }
    }
    
    internal override var requiredLegendOffset: CGFloat
    {
        return _legend.font.pointSize * 2.0
    }
    
    internal override var requiredBaseOffset: CGFloat
    {
        return 0.0
    }
    
    open override var radius: CGFloat
    {
        return _circleBox.width / 2.0
    }
    
    /// The circlebox, the boundingbox of the pie-chart slices
    open var circleBox: CGRect
    {
        return _circleBox
    }
    
    /// The center of the circlebox
    open var centerCircleBox: CGPoint
    {
        return CGPoint(x: _circleBox.midX, y: _circleBox.midY)
    }
    
    /// the radius of the hole in the center of the piechart in percent of the maximum radius (max = the radius of the whole chart)
    /// 
    /// **default**: 0.5 (50%) (half the pie)
    var holeRadiusRatio: CGFloat = CGFloat(0.5)
    {
      didSet { setNeedsDisplay() }
    }

    open var holeRadiusPercent: CGFloat
    {
      get { return holeRadiusRatio * 100 }
      set { holeRadiusRatio = newValue / 100 }
    }

    /// The color that the transparent-circle should have.
    ///
    /// **default**: `nil`
    open var transparentCircleColor: NSUIColor? = NSUIColor(named: "pie_hole", bundle: Bundle(for: PieChartView.self))?.withAlphaComponent(0.5)
    {
        didSet { setNeedsDisplay() }
    }
    
    /// the radius of the transparent circle that is drawn next to the hole in the piechart in percent of the maximum radius (max = the radius of the whole chart)
    /// 
    /// **default**: 0.55 (55%) -> means 5% larger than the center-hole by default
    var transparentCircleRadiusRatio: CGFloat = CGFloat(0.55)
    {
      didSet { setNeedsDisplay() }
    }

    open var transparentCircleRadiusPercent: CGFloat
    {
      get { return transparentCircleRadiusRatio * 100 }
      set { transparentCircleRadiusRatio = newValue / 100 }
    }

    /// The color the entry labels are drawn with.
    open var entryLabelColor: NSUIColor? = NSUIColor(named: "pie_label", bundle: Bundle(for: PieChartView.self))
    {
        didSet { setNeedsDisplay() }
    }
    
    /// The font the entry labels are drawn with.
    open var entryLabelFont: NSUIFont? = NSUIFont.systemFont(ofSize: 13.0)
    {
        didSet { setNeedsDisplay() }
    }
    
    /// Set this to true to draw the enrty labels into the pie slices
    open var drawsEntryLabels: Bool = true
    {
        didSet { setNeedsDisplay() }
    }
    
    /// If this is enabled, values inside the PieChart are drawn in percent and not with their original value. Values provided for the ValueFormatter to format are then provided in percent.
    open var usesPercentValues: Bool = false
    {
        didSet { setNeedsDisplay() }
    }

    /// the rectangular radius of the bounding box for the center text, as a percentage of the pie hole
    var centerTextRadiusRatio: CGFloat = 1.0
    {
      didSet { setNeedsDisplay() }
    }

    open var centerTextRadiusPercent: CGFloat
    {
        get { return centerTextRadiusRatio * 100 }
        set { centerTextRadiusRatio = newValue / 100 }
    }

    /// The max angle that is used for calculating the pie-circle.
    /// 360 means it's a full pie-chart, 180 results in a half-pie-chart.
    /// **default**: 360.0
    open var maxAngle: CGFloat
    {
        get
        {
            return _maxAngle
        }
        set
        {
            _maxAngle = newValue
            
            if _maxAngle > 360.0
            {
                _maxAngle = 360.0
            }
            
            if _maxAngle < 90.0
            {
                _maxAngle = 90.0
            }
        }
    }
}

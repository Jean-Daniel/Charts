//
//  CombinedChartRenderer.swift
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

open class CombinedChartRenderer: DataRenderer
{
    open weak var chart: CombinedChartView?
    
    /// if set to true, all values are drawn above their bars, instead of below their top
    open var drawValueAboveBarEnabled = true
    
    /// if set to true, a grey area is drawn behind each bar that indicates the maximum value
    open var drawBarShadowEnabled = false
    
    internal var _renderers = [DataRenderer]()
    
    internal var _drawOrder: [CombinedChartView.DrawOrder] = [.bar, .bubble, .line, .candle, .scatter]
    
    public init(chart: CombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.chart = chart
        
        createRenderers()
    }
    
    /// Creates the renderers needed for this combined-renderer in the required order. Also takes the DrawOrder into consideration.
    internal func createRenderers()
    {
        _renderers = [DataRenderer]()
        
        guard let chart = chart else { return }

        for order in drawOrder
        {
            switch (order)
            {
            case .bar:
                if chart.barData != nil
                {
                    _renderers.append(BarChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .line:
                if chart.lineData != nil
                {
                    _renderers.append(LineChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .candle:
                if chart.candleData != nil
                {
                    _renderers.append(CandleStickChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .scatter:
                if chart.scatterData != nil
                {
                    _renderers.append(ScatterChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .bubble:
                if chart.bubbleData != nil
                {
                    _renderers.append(BubbleChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
            }
        }

    }
    
    open override func initBuffers()
    {
        for renderer in _renderers
        {
            renderer.initBuffers()
        }
    }
    
    open override func drawData(context: CGContext)
    {
        // If we redraw the data, remove and repopulate accessible elements to update label values and frames
        accessibleChartElements.removeAll()

        if
            let combinedChart = chart,
            let data = combinedChart.data {
            // Make the chart header the first element in the accessible elements array
            let element = createAccessibleHeader(usingChart: combinedChart,
                                                 andData: data,
                                                 withDefaultDescription: "Combined Chart")
            accessibleChartElements.append(element)
        }

        // TODO: Due to the potential complexity of data presented in Combined charts, a more usable way
        // for VO accessibility would be to use axis based traversal rather than by dataset.
        // Hence, accessibleChartElements is not populated below. (Individual renderers guard against dataSource being their respective views)
        for renderer in _renderers
        {
            renderer.drawData(context: context)
        }
    }
    
    open override func drawValues(context: CGContext)
    {
        for renderer in _renderers
        {
            renderer.drawValues(context: context)
        }
    }
    
    open override func drawExtras(context: CGContext)
    {
        for renderer in _renderers
        {
            renderer.drawExtras(context: context)
        }
    }
    
    open override func drawHighlighted(context: CGContext, indices: [Highlight])
    {
        for renderer in _renderers
        {
            var data: ChartData?
            switch renderer {
            case let renderer as BarChartRenderer:
              data = renderer.dataProvider?.barData
            case let renderer as LineChartRenderer:
              data = renderer.dataProvider?.lineData
            case let renderer as CandleStickChartRenderer:
              data = renderer.dataProvider?.candleData
            case let renderer as ScatterChartRenderer:
              data = renderer.dataProvider?.scatterData
            case let renderer as BubbleChartRenderer:
              data = renderer.dataProvider?.bubbleData
            default:
              break
            }
            
            let dataIndex = data == nil ? nil : (chart?.data as? CombinedChartData)?.allData.index(of: data!)
            
            let dataIndices = indices.filter{ $0.dataIndex == dataIndex || $0.dataIndex == -1 }
            
            renderer.drawHighlighted(context: context, indices: dataIndices)
        }
    }

    /// - Returns: The sub-renderer object at the specified index.
    open func getSubRenderer(index: Int) -> DataRenderer?
    {
        if index >= _renderers.count || index < 0
        {
            return nil
        }
        else
        {
            return _renderers[index]
        }
    }

    /// All sub-renderers.
    open var subRenderers: [DataRenderer]
    {
        get { return _renderers }
        set { _renderers = newValue }
    }
    
    // MARK: Accessors
    
    /// `true` if drawing values above bars is enabled, `false` ifnot
    open var isDrawValueAboveBarEnabled: Bool { return drawValueAboveBarEnabled }
    
    /// `true` if drawing shadows (maxvalue) for each bar is enabled, `false` ifnot
    open var isDrawBarShadowEnabled: Bool { return drawBarShadowEnabled }
    
    /// the order in which the provided data objects should be drawn.
    /// The earlier you place them in the provided array, the further they will be in the background.
    /// e.g. if you provide [DrawOrder.Bar, DrawOrder.Line], the bars will be drawn behind the lines.
    open var drawOrder: [CombinedChartView.DrawOrder]
    {
        get
        {
            return _drawOrder
        }
        set
        {
            if newValue.count > 0
            {
                _drawOrder = newValue
            }
        }
    }
}

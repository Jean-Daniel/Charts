//
//  CombinedChartData.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

open class CombinedChartData: BarLineScatterCandleBubbleChartData
{
    private var _lineData: LineChartData?
    private var _barData: BarChartData?
    private var _scatterData: ScatterChartData?
    private var _candleData: CandleChartData?
    private var _bubbleData: BubbleChartData?

    public override init(dataSets: [IChartDataSet]? = nil)
    {
        super.init(dataSets: dataSets)
    }
    
    open var lineData: LineChartData?
    {
        get
        {
            return _lineData
        }
        set
        {
            _lineData = newValue
            notifyDataChanged()
        }
    }
    
    open var barData: BarChartData?
    {
        get
        {
            return _barData
        }
        set
        {
            _barData = newValue
            notifyDataChanged()
        }
    }
    
    open var scatterData: ScatterChartData?
    {
        get
        {
            return _scatterData
        }
        set
        {
            _scatterData = newValue
            notifyDataChanged()
        }
    }
    
    open var candleData: CandleChartData?
    {
        get
        {
            return _candleData
        }
        set
        {
            _candleData = newValue
            notifyDataChanged()
        }
    }
    
    open var bubbleData: BubbleChartData?
    {
        get
        {
            return _bubbleData
        }
        set
        {
            _bubbleData = newValue
            notifyDataChanged()
        }
    }
    
    open override func calcMinMax()
    {
        _dataSets.removeAll()
        
        _yMax = -Double.greatestFiniteMagnitude
        _yMin = Double.greatestFiniteMagnitude
        _xMax = -Double.greatestFiniteMagnitude
        _xMin = Double.greatestFiniteMagnitude
        
        _leftAxisMax = -Double.greatestFiniteMagnitude
        _leftAxisMin = Double.greatestFiniteMagnitude
        _rightAxisMax = -Double.greatestFiniteMagnitude
        _rightAxisMin = Double.greatestFiniteMagnitude
        
        let allData = self.allData
        
        for data in allData
        {
            data.calcMinMax()
            
            let sets = data.dataSets
            _dataSets.append(contentsOf: sets)
            
            if data.yMax > _yMax
            {
                _yMax = data.yMax
            }
            
            if data.yMin < _yMin
            {
                _yMin = data.yMin
            }
            
            if data.xMax > _xMax
            {
                _xMax = data.xMax
            }
            
            if data.xMin < _xMin
            {
                _xMin = data.xMin
            }

            for dataset in sets
            {
                if dataset.axisDependency == .left
                {
                    if dataset.yMax > _leftAxisMax
                    {
                        _leftAxisMax = dataset.yMax
                    }
                    if dataset.yMin < _leftAxisMin
                    {
                        _leftAxisMin = dataset.yMin
                    }
                }
                else
                {
                    if dataset.yMax > _rightAxisMax
                    {
                        _rightAxisMax = dataset.yMax
                    }
                    if dataset.yMin < _rightAxisMin
                    {
                        _rightAxisMin = dataset.yMin
                    }
                }
            }
        }
    }
    
    /// All data objects in row: line-bar-scatter-candle-bubble if not null.
    open var allData: [ChartData]
    {
        var data = [ChartData]()
        
        if let lineData = lineData
        {
            data.append(lineData)
        }
        if let barData = barData
        {
            data.append(barData)
        }
        if let scatterData = scatterData
        {
            data.append(scatterData)
        }
        if let candleData = candleData
        {
            data.append(candleData)
        }
        if let bubbleData = bubbleData
        {
            data.append(bubbleData)
        }
        
        return data
    }
    
    open func dataByIndex(_ index: Int) -> ChartData
    {
        return allData[index]
    }
    
    open func dataIndex(_ data: ChartData) -> Int?
    {
        return allData.index(of: data)
    }
    
    open override func removeDataSet(_ dataSet: IChartDataSet!) -> Bool
    {
        let datas = allData
        
        var success = false
        
        for data in datas
        {
            success = data.removeDataSet(dataSet)
            
            if success
            {
                break
            }
        }
        
        return success
    }
    
    open override func removeDataSetByIndex(_ index: Int) -> Bool
    {
        print("removeDataSet(index) not supported for CombinedData", terminator: "\n")
        return false
    }
    
    open override func removeEntry(_ entry: ChartDataEntry, dataSetIndex: Int) -> Bool
    {
        print("removeEntry(entry, dataSetIndex) not supported for CombinedData", terminator: "\n")
        return false
    }
    
    open override func removeEntry(xValue: Double, dataSetIndex: Int) -> Bool
    {
        print("removeEntry(xValue, dataSetIndex) not supported for CombinedData", terminator: "\n")
        return false
    }
    
    open override func notifyDataChanged()
    {
        _lineData?.notifyDataChanged()
        _barData?.notifyDataChanged()
        _scatterData?.notifyDataChanged()
        _candleData?.notifyDataChanged()
        _bubbleData?.notifyDataChanged()
        
        super.notifyDataChanged() // recalculate everything
    }
    
    /// Get the Entry for a corresponding highlight object
    ///
    /// - Parameters:
    ///   - highlight:
    /// - Returns: The entry that is highlighted
    open override func entryForHighlight(_ highlight: Highlight) -> ChartDataEntry?
    {
        if highlight.dataIndex >= allData.count
        {
            return nil
        }
        
        let data = dataByIndex(highlight.dataIndex)
        
        if highlight.dataSetIndex >= data.dataSetCount
        {
            return nil
        }
        
        // The value of the highlighted entry could be NaN - if we are not interested in highlighting a specific value.
        let entries = data.getDataSetByIndex(highlight.dataSetIndex).entriesForXValue(highlight.x)
        for e in entries
        {
            if e.y == highlight.y || highlight.y.isNaN
            {
                return e
            }
        }
        return nil
    }
    
    /// Get dataset for highlight
    ///
    /// - Parameters:
    ///   - highlight: current highlight
    /// - Returns: dataset related to highlight
    open func getDataSetByHighlight(_ highlight: Highlight) -> IChartDataSet?
    {  
        if highlight.dataIndex >= allData.count
        {
            return nil
        }
        
        let data = dataByIndex(highlight.dataIndex)
        
        if highlight.dataSetIndex >= data.dataSetCount
        {
            return nil
        }
        
        return data.dataSets[highlight.dataSetIndex]
    }
}

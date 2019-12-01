//
//  ChartColorTemplates.swift
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

private let bundle = Bundle(for: ChartViewBase.self)

public struct ChartColorTemplates
{
    public static func liberty () -> [NSUIColor]
    {
      return (1...5).map { NSUIColor(named: "liberty_\($0)", bundle: bundle)! }
    }
    
    public static func joyful () -> [NSUIColor]
    {
      return (1...5).map { NSUIColor(named: "joyful_\($0)", bundle: bundle)! }
    }
    
    public static func pastel () -> [NSUIColor]
    {
      return (1...5).map { NSUIColor(named: "pastel_\($0)", bundle: bundle)! }
    }
    
    public static func colorful () -> [NSUIColor]
    {
      return (1...5).map { NSUIColor(named: "colorful_\($0)", bundle: bundle)! }
    }
    
    public static func vordiplom () -> [NSUIColor]
    {
      return (1...5).map { NSUIColor(named: "vordiplom_\($0)", bundle: bundle)! }
    }
    
    public static func material () -> [NSUIColor]
    {
      return (1...4).map { NSUIColor(named: "material_\($0)", bundle: bundle)! }
    }
    
    public static func colorFromString(_ colorString: String) -> NSUIColor
    {
        let leftParenCharset: CharacterSet = CharacterSet(charactersIn: "( ")
        let commaCharset: CharacterSet = CharacterSet(charactersIn: ", ")

        let colorString = colorString.lowercased()
        
        if colorString.hasPrefix("#")
        {
            var argb: [UInt] = [255, 0, 0, 0]
            let colorString = colorString.unicodeScalars
            var length = colorString.count
            var index = colorString.startIndex
            let endIndex = colorString.endIndex
            
            index = colorString.index(after: index)
            length = length - 1
            
            if length == 3 || length == 6 || length == 8
            {
                var i = length == 8 ? 0 : 1
                while index < endIndex
                {
                    var c = colorString[index]
                    index = colorString.index(after: index)
                    
                    var val = (c.value >= 0x61 && c.value <= 0x66) ? (c.value - 0x61 + 10) : c.value - 0x30
                    argb[i] = UInt(val) * 16
                    if length == 3
                    {
                        argb[i] = argb[i] + UInt(val)
                    }
                    else
                    {
                        c = colorString[index]
                        index = colorString.index(after: index)
                        
                        val = (c.value >= 0x61 && c.value <= 0x66) ? (c.value - 0x61 + 10) : c.value - 0x30
                        argb[i] = argb[i] + UInt(val)
                    }
                    
                    i += 1
                }
            }
            
            return NSUIColor(red: CGFloat(argb[1]) / 255.0, green: CGFloat(argb[2]) / 255.0, blue: CGFloat(argb[3]) / 255.0, alpha: CGFloat(argb[0]) / 255.0)
        }
        else if colorString.hasPrefix("rgba")
        {
            var a: Float = 1.0
            var r: Int32 = 0
            var g: Int32 = 0
            var b: Int32 = 0
            let scanner: Scanner = Scanner(string: colorString)
            _ = scanner.scanString("rgba")
            _ = scanner.scanCharacters(from: leftParenCharset)
            r = scanner.scanInt32() ?? 0
            _ = scanner.scanCharacters(from: commaCharset)
            g = scanner.scanInt32() ?? 0
            _ = scanner.scanCharacters(from: commaCharset)
            b = scanner.scanInt32() ?? 0
            _ = scanner.scanCharacters(from: commaCharset)
            a = scanner.scanFloat() ?? 1.0
            return NSUIColor(
                red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: CGFloat(a)
            )
        }
        else if colorString.hasPrefix("argb")
        {
            var a: Float = 1.0
            var r: Int32 = 0
            var g: Int32 = 0
            var b: Int32 = 0
            let scanner: Scanner = Scanner(string: colorString)
            _ = scanner.scanString("argb")
            _ = scanner.scanCharacters(from: leftParenCharset)
            a = scanner.scanFloat() ?? 1.0
            _ = scanner.scanCharacters(from: commaCharset)
            r = scanner.scanInt32() ?? 0
            _ = scanner.scanCharacters(from: commaCharset)
            g = scanner.scanInt32() ?? 0
            _ = scanner.scanCharacters(from: commaCharset)
            b = scanner.scanInt32() ?? 0
            return NSUIColor(
                red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: CGFloat(a)
            )
        }
        else if colorString.hasPrefix("rgb")
        {
            var r: Int32 = 0
            var g: Int32 = 0
            var b: Int32 = 0
            let scanner: Scanner = Scanner(string: colorString)
            _ = scanner.scanString("rgb")
            _ = scanner.scanCharacters(from: leftParenCharset)
            r = scanner.scanInt32() ?? 0
            _ = scanner.scanCharacters(from: commaCharset)
            g = scanner.scanInt32() ?? 0
            _ = scanner.scanCharacters(from: commaCharset)
            b = scanner.scanInt32() ?? 0
            return NSUIColor(
                red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: 1.0
            )
        }
        
        return NSUIColor.clear
    }
}

//
//  Description.swift
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

public class Description: ComponentBase
{
    public override init()
    {
        #if os(tvOS)
            // 23 is the smallest recommended font size on the TV
            font = NSUIFont.systemFont(ofSize: 23)
        #elseif os(OSX)
            font = NSUIFont.systemFont(ofSize: NSUIFont.systemFontSize)
        #else
            font = NSUIFont.systemFont(ofSize: 8.0)
        #endif
        
        super.init()
    }
    
    /// The text to be shown as the description.
    public var text: String?
    
    /// Custom position for the description text in pixels on the screen.
    public var position: CGPoint? = nil
    
    /// The text alignment of the description text. Default RIGHT.
    public var textAlign: NSTextAlignment = NSTextAlignment.right
    
    /// Font object used for drawing the description text.
    public var font: NSUIFont
    
    /// Text color used for drawing the description text
    public var textColor = NSUIColor.labelColor
}

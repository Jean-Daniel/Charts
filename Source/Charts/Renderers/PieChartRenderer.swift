//
//  PieChartRenderer.swift
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

public class PieChartRenderer
{
  /// An array of accessibility elements that are presented to the ChartViewBase accessibility methods.
  ///
  /// Note that the order of elements in this array determines the order in which they are presented and navigated by
  /// Accessibility clients such as VoiceOver.
  ///
  /// Renderers should ensure that the order of elements makes sense to a client presenting an audio-only interface to a user.
  /// Subclasses should populate this array in drawData() or drawDataSet() to make the chart accessible.
  final var accessibleChartElements: [NSUIAccessibilityElement] = []

  private let animator: Animator

  private weak var chart: PieChartView?

  private let viewPortHandler: ViewPortHandler

  public init(chart: PieChartView, animator: Animator)
  {
    self.chart = chart
    self.animator = animator
    self.viewPortHandler = chart.viewPortHandler
  }

  /// An opportunity for initializing internal buffers used for rendering with a new size.
  /// Since this might do memory allocations, it should only be called if necessary.
  public func initBuffers() { }

  /// Creates an ```NSUIAccessibilityElement``` that acts as the first and primary header describing a chart view.
  ///
  /// - Parameters:
  ///   - chart: The chartView object being described
  ///   - data: A non optional data source about the chart
  ///   - defaultDescription: A simple string describing the type/design of Chart.
  /// - Returns: A header ```NSUIAccessibilityElement``` that can be added to accessibleChartElements.
  internal func createAccessibleHeader(usingChart chart: ChartViewBase,
                                       andData data: ChartData,
                                       withDefaultDescription defaultDescription: String = "Chart") -> NSUIAccessibilityElement
  {
    let chartDescriptionText = chart.chartDescription.text ?? defaultDescription
    let dataSetDescriptionText = data.label ?? ""

    let
    element = NSUIAccessibilityElement(accessibilityContainer: chart)
    element.accessibilityLabel = chartDescriptionText + ". \(dataSetDescriptionText)"
    element.accessibilityFrame = chart.bounds
    element.isHeader = true

    return element
  }

  public func drawData(context: CGContext)
  {
    guard let data = chart?.data else { return }

    // If we redraw the data, remove and repopulate accessible elements to update label values and frames
    accessibleChartElements.removeAll()

    if data.visible && data.count > 0 {
      draw(data: data, into: context)
    }
  }

  public func calculateMinimumRadiusForSpacedSlice(
    center: CGPoint,
    radius: CGFloat,
    angle: CGFloat,
    arcStartPointX: CGFloat,
    arcStartPointY: CGFloat,
    startAngle: CGFloat,
    sweepAngle: CGFloat) -> CGFloat
  {
    let angleMiddle = startAngle + sweepAngle / 2.0

    // Other point of the arc
    let arcEndPointX = center.x + radius * cos((startAngle + sweepAngle).DEG2RAD)
    let arcEndPointY = center.y + radius * sin((startAngle + sweepAngle).DEG2RAD)

    // Middle point on the arc
    let arcMidPointX = center.x + radius * cos(angleMiddle.DEG2RAD)
    let arcMidPointY = center.y + radius * sin(angleMiddle.DEG2RAD)

    // This is the base of the contained triangle
    let basePointsDistance = sqrt(
      pow(arcEndPointX - arcStartPointX, 2) +
        pow(arcEndPointY - arcStartPointY, 2))

    // After reducing space from both sides of the "slice",
    //   the angle of the contained triangle should stay the same.
    // So let's find out the height of that triangle.
    let containedTriangleHeight = (basePointsDistance / 2.0 *
      tan((180.0 - angle).DEG2RAD / 2.0))

    // Now we subtract that from the radius
    var spacedRadius = radius - containedTriangleHeight

    // And now subtract the height of the arc that's between the triangle and the outer circle
    spacedRadius -= sqrt(
      pow(arcMidPointX - (arcEndPointX + arcStartPointX) / 2.0, 2) +
        pow(arcMidPointY - (arcEndPointY + arcStartPointY) / 2.0, 2))

    return spacedRadius
  }

  /// Calculates the sliceSpace to use based on visible values and their size compared to the set sliceSpace.
  public func getSliceSpace(for data: ChartData) -> CGFloat
  {
    guard data.automaticallyDisableSliceSpacing else { return data.sliceSpace }

    let spaceSizeRatio = data.sliceSpace / min(viewPortHandler.contentWidth, viewPortHandler.contentHeight)
    let minValueRatio = data.yMin / data.yValueSum * 2.0

    let sliceSpace = spaceSizeRatio > CGFloat(minValueRatio) ? 0.0 : data.sliceSpace

    return sliceSpace
  }

  public func draw(data: ChartData, into context: CGContext)
  {
    guard let chart = chart else {return }

    var angle: CGFloat = 0.0
    let rotationAngle = chart.rotationAngle

    let phaseX = animator.phaseX
    let phaseY = animator.phaseY

    let entryCount = data.count
    var drawAngles = chart.drawAngles
    let center = chart.centerCircleBox
    let radius = chart.radius
    let drawInnerArc = chart.drawsHole && !chart.drawsSlicesUnderHole
    let userInnerRadius = drawInnerArc ? radius * chart.holeRadiusRatio : 0.0

    var visibleAngleCount = 0
    for j in 0 ..< entryCount
    {
      guard let e = data[j] else { continue }
      if ((abs(e.value) > Double.ulpOfOne))
      {
        visibleAngleCount += 1
      }
    }

    let sliceSpace = visibleAngleCount <= 1 ? 0.0 : getSliceSpace(for: data)

    context.saveGState()

    // Make the chart header the first element in the accessible elements array
    // We can do this in drawDataSet, since we know PieChartView can have only 1 dataSet
    // Also since there's only 1 dataset, we don't use the typical createAccessibleHeader() here.
    // NOTE: - Since we want to summarize the total count of slices/portions/elements, use a default string here
    // This is unlike when we are naming individual slices, wherein it's alright to not use a prefix as descriptor.
    // i.e. We want to VO to say "3 Elements" even if the developer didn't specify an accessibility prefix
    // If prefix is unspecified it is safe to assume they did not want to use "Element 1", so that uses a default empty string
    let prefix: String = chart.data?.accessibilityEntryLabelPrefix ?? "Element"
    let description = chart.chartDescription.text ?? data.label ?? chart.centerText ??  "Pie Chart"

    let
    element = NSUIAccessibilityElement(accessibilityContainer: chart)
    element.accessibilityLabel = description + ". \(entryCount) \(prefix + (entryCount == 1 ? "" : "s"))"
    element.accessibilityFrame = chart.bounds
    element.isHeader = true
    accessibleChartElements.append(element)

    for j in 0 ..< entryCount
    {
      guard let e = data[j] else { continue }

      let sliceAngle = drawAngles[j]
      var innerRadius = userInnerRadius

      // draw only if the value is greater than zero
      if (abs(e.value) > Double.ulpOfOne) && !chart.isHighlighted(at: j) {
        let accountForSliceSpacing = sliceSpace > 0.0 && sliceAngle <= 180.0

        context.setFillColor(data.color(at: j).cgColor)

        let sliceSpaceAngleOuter = visibleAngleCount == 1 ?
          0.0 :
          sliceSpace / radius.DEG2RAD
        let startAngleOuter = rotationAngle + (angle + sliceSpaceAngleOuter / 2.0) * CGFloat(phaseY)
        var sweepAngleOuter = (sliceAngle - sliceSpaceAngleOuter) * CGFloat(phaseY)
        if sweepAngleOuter < 0.0
        {
          sweepAngleOuter = 0.0
        }

        let arcStartPointX = center.x + radius * cos(startAngleOuter.DEG2RAD)
        let arcStartPointY = center.y + radius * sin(startAngleOuter.DEG2RAD)

        let path = CGMutablePath()

        path.move(to: CGPoint(x: arcStartPointX,
                              y: arcStartPointY))

        path.addRelativeArc(center: center, radius: radius, startAngle: startAngleOuter.DEG2RAD, delta: sweepAngleOuter.DEG2RAD)

        if drawInnerArc &&
          (innerRadius > 0.0 || accountForSliceSpacing)
        {
          if accountForSliceSpacing
          {
            var minSpacedRadius = calculateMinimumRadiusForSpacedSlice(
              center: center,
              radius: radius,
              angle: sliceAngle * CGFloat(phaseY),
              arcStartPointX: arcStartPointX,
              arcStartPointY: arcStartPointY,
              startAngle: startAngleOuter,
              sweepAngle: sweepAngleOuter)
            if minSpacedRadius < 0.0
            {
              minSpacedRadius = -minSpacedRadius
            }
            innerRadius = min(max(innerRadius, minSpacedRadius), radius)
          }

          let sliceSpaceAngleInner = visibleAngleCount == 1 || innerRadius == 0.0 ?
            0.0 :
            sliceSpace / innerRadius.DEG2RAD
          let startAngleInner = rotationAngle + (angle + sliceSpaceAngleInner / 2.0) * CGFloat(phaseY)
          var sweepAngleInner = (sliceAngle - sliceSpaceAngleInner) * CGFloat(phaseY)
          if sweepAngleInner < 0.0
          {
            sweepAngleInner = 0.0
          }
          let endAngleInner = startAngleInner + sweepAngleInner

          path.addLine(
            to: CGPoint(
              x: center.x + innerRadius * cos(endAngleInner.DEG2RAD),
              y: center.y + innerRadius * sin(endAngleInner.DEG2RAD)))

          path.addRelativeArc(center: center, radius: innerRadius, startAngle: endAngleInner.DEG2RAD, delta: -sweepAngleInner.DEG2RAD)
        }
        else
        {
          if accountForSliceSpacing
          {
            let angleMiddle = startAngleOuter + sweepAngleOuter / 2.0

            let sliceSpaceOffset =
              calculateMinimumRadiusForSpacedSlice(
                center: center,
                radius: radius,
                angle: sliceAngle * CGFloat(phaseY),
                arcStartPointX: arcStartPointX,
                arcStartPointY: arcStartPointY,
                startAngle: startAngleOuter,
                sweepAngle: sweepAngleOuter)

            let arcEndPointX = center.x + sliceSpaceOffset * cos(angleMiddle.DEG2RAD)
            let arcEndPointY = center.y + sliceSpaceOffset * sin(angleMiddle.DEG2RAD)

            path.addLine(
              to: CGPoint(
                x: arcEndPointX,
                y: arcEndPointY))
          }
          else
          {
            path.addLine(to: center)
          }
        }

        path.closeSubpath()

        context.beginPath()
        context.addPath(path)
        context.fillPath(using: .evenOdd)

        let axElement = createAccessibleElement(withIndex: j, container: chart, data: data)
        { (element) in
          element.accessibilityFrame = path.boundingBoxOfPath
        }

        accessibleChartElements.append(axElement)
      }

      angle += sliceAngle * CGFloat(phaseX)
    }

    // Post this notification to let VoiceOver account for the redrawn frames
    accessibilityPostLayoutChangedNotification()

    context.restoreGState()
  }

  public func drawValues(context: CGContext)
  {
    guard
      let chart = chart,
      let data = chart.data
      else { return }

    let center = chart.centerCircleBox

    // get whole the radius
    let radius = chart.radius
    let rotationAngle = chart.rotationAngle
    var drawAngles = chart.drawAngles
    var absoluteAngles = chart.absoluteAngles

    let phaseX = animator.phaseX
    let phaseY = animator.phaseY

    var labelRadiusOffset = radius / 10.0 * 3.0

    if chart.drawsHole
    {
      labelRadiusOffset = (radius - (radius * chart.holeRadiusRatio)) / 2.0
    }

    let labelRadius = radius - labelRadiusOffset

    let yValueSum = data.yValueSum

    let drawEntryLabels = chart.drawsEntryLabels
    let usePercentValuesEnabled = chart.usesPercentValues
    let entryLabelColor = chart.entryLabelColor

    var angle: CGFloat = 0.0
    var xIndex = 0

    context.saveGState()
    defer { context.restoreGState() }

    let drawValues = data.drawsValues

    if !drawValues && !drawEntryLabels
    {
      return
    }

    let labelPosition = data.labelPosition
    let valuePosition = data.valuePosition

    let valueFont = data.valueFont
    let entryLabelFont = data.entryLabelFont ?? chart.entryLabelFont
    let lineHeight = valueFont.lineHeight

    for j in 0 ..< data.count
    {
      guard let e = data[j] else { continue }
      let pe = e

      if xIndex == 0
      {
        angle = 0.0
      }
      else
      {
        angle = absoluteAngles[xIndex - 1] * CGFloat(phaseX)
      }

      let sliceAngle = drawAngles[xIndex]
      let sliceSpace = getSliceSpace(for: data)
      let sliceSpaceMiddleAngle = sliceSpace / labelRadius.DEG2RAD

      // offset needed to center the drawn text in the slice
      let angleOffset = (sliceAngle - sliceSpaceMiddleAngle / 2.0) / 2.0

      angle = angle + angleOffset

      let transformedAngle = rotationAngle + angle * CGFloat(phaseY)

      let formatter = data.valueFormatter ?? ChartUtils.defaultValueFormatter
      let value = usePercentValuesEnabled ? e.value / yValueSum * 100.0 : e.value

      let valueText = formatter.stringForValue(
        value,
        entry: e,
        viewPortHandler: viewPortHandler)

      let sliceXBase = cos(transformedAngle.DEG2RAD)
      let sliceYBase = sin(transformedAngle.DEG2RAD)

      let drawXOutside = drawEntryLabels && labelPosition == .outsideSlice
      let drawYOutside = drawValues && valuePosition == .outsideSlice
      let drawXInside = drawEntryLabels && labelPosition == .insideSlice
      let drawYInside = drawValues && valuePosition == .insideSlice

      let valueTextColor = data.valueColor(at: j)
      let entryLabelColor = data.entryLabelColor

      if drawXOutside || drawYOutside
      {
        let valueLineLength1 = data.valueLinePart1Length
        let valueLineLength2 = data.valueLinePart2Length
        let valueLinePart1OffsetPercentage = data.valueLinePart1OffsetRatio

        var pt2: CGPoint
        var labelPoint: CGPoint
        var align: NSTextAlignment

        var line1Radius: CGFloat

        if chart.drawsHole
        {
          line1Radius = (radius - (radius * chart.holeRadiusRatio)) * valueLinePart1OffsetPercentage + (radius * chart.holeRadiusRatio)
        }
        else
        {
          line1Radius = radius * valueLinePart1OffsetPercentage
        }

        let polyline2Length = data.valueLineVariableLength
          ? labelRadius * valueLineLength2 * abs(sin(transformedAngle.DEG2RAD))
          : labelRadius * valueLineLength2

        let pt0 = CGPoint(
          x: line1Radius * sliceXBase + center.x,
          y: line1Radius * sliceYBase + center.y)

        let pt1 = CGPoint(
          x: labelRadius * (1 + valueLineLength1) * sliceXBase + center.x,
          y: labelRadius * (1 + valueLineLength1) * sliceYBase + center.y)

        if transformedAngle.truncatingRemainder(dividingBy: 360.0) >= 90.0 && transformedAngle.truncatingRemainder(dividingBy: 360.0) <= 270.0
        {
          pt2 = CGPoint(x: pt1.x - polyline2Length, y: pt1.y)
          align = .right
          labelPoint = CGPoint(x: pt2.x - 5, y: pt2.y - lineHeight)
        }
        else
        {
          pt2 = CGPoint(x: pt1.x + polyline2Length, y: pt1.y)
          align = .left
          labelPoint = CGPoint(x: pt2.x + 5, y: pt2.y - lineHeight)
        }

        if data.valueLineColor != nil
        {
          context.setStrokeColor(data.valueLineColor!.cgColor)
          context.setLineWidth(data.valueLineWidth)

          context.move(to: CGPoint(x: pt0.x, y: pt0.y))
          context.addLine(to: CGPoint(x: pt1.x, y: pt1.y))
          context.addLine(to: CGPoint(x: pt2.x, y: pt2.y))

          context.drawPath(using: CGPathDrawingMode.stroke)
        }

        if drawXOutside && drawYOutside
        {
          ChartUtils.drawText(
            context: context,
            text: valueText,
            point: labelPoint,
            align: align,
            attributes: [.font: valueFont, .foregroundColor: valueTextColor]
          )

          if j < data.count, let label = pe.label
          {
            ChartUtils.drawText(
              context: context,
              text: label,
              point: CGPoint(x: labelPoint.x, y: labelPoint.y + lineHeight),
              align: align,
              attributes: [
                .font: entryLabelFont ?? valueFont,
                .foregroundColor: entryLabelColor ?? valueTextColor]
            )
          }
        }
        else if drawXOutside
        {
          if j < data.count, let label = pe.label
          {
            ChartUtils.drawText(
              context: context,
              text: label,
              point: CGPoint(x: labelPoint.x, y: labelPoint.y + lineHeight / 2.0),
              align: align,
              attributes: [
                .font: entryLabelFont ?? valueFont,
                .foregroundColor: entryLabelColor ?? valueTextColor]
            )
          }
        }
        else if drawYOutside
        {
          ChartUtils.drawText(
            context: context,
            text: valueText,
            point: CGPoint(x: labelPoint.x, y: labelPoint.y + lineHeight / 2.0),
            align: align,
            attributes: [.font: valueFont, .foregroundColor: valueTextColor]
          )
        }
      }

      if drawXInside || drawYInside
      {
        // calculate the text position
        let x = labelRadius * sliceXBase + center.x
        let y = labelRadius * sliceYBase + center.y - lineHeight

        if drawXInside && drawYInside
        {
          ChartUtils.drawText(
            context: context,
            text: valueText,
            point: CGPoint(x: x, y: y),
            align: .center,
            attributes: [.font: valueFont, .foregroundColor: valueTextColor]
          )

          if j < data.count, let label = pe.label
          {
            ChartUtils.drawText(
              context: context,
              text: label,
              point: CGPoint(x: x, y: y + lineHeight),
              align: .center,
              attributes: [
                .font: entryLabelFont ?? valueFont,
                .foregroundColor: entryLabelColor ?? valueTextColor]
            )
          }
        }
        else if drawXInside
        {
          if j < data.count, let label = pe.label
          {
            ChartUtils.drawText(
              context: context,
              text: label,
              point: CGPoint(x: x, y: y + lineHeight / 2.0),
              align: .center,
              attributes: [
                .font: entryLabelFont ?? valueFont,
                .foregroundColor: entryLabelColor ?? valueTextColor]
            )
          }
        }
        else if drawYInside
        {
          ChartUtils.drawText(
            context: context,
            text: valueText,
            point: CGPoint(x: x, y: y + lineHeight / 2.0),
            align: .center,
            attributes: [.font: valueFont, .foregroundColor: valueTextColor]
          )
        }
      }

      xIndex += 1
    }
  }

  public func drawExtras(context: CGContext)
  {
    drawHole(context: context)
    drawCenterText(context: context)
  }

  /// draws the hole in the center of the chart and the transparent circle / hole
  private func drawHole(context: CGContext)
  {
    guard let chart = chart else { return }

    if chart.drawsHole
    {
      context.saveGState()

      let radius = chart.radius
      let holeRadius = radius * chart.holeRadiusRatio
      let center = chart.centerCircleBox

      if let holeColor = chart.holeColor
      {
        if holeColor != NSUIColor.clear
        {
          // draw the hole-circle
          context.setFillColor(holeColor.cgColor)
          context.fillEllipse(in: CGRect(x: center.x - holeRadius, y: center.y - holeRadius, width: holeRadius * 2.0, height: holeRadius * 2.0))
        }
      }

      // only draw the circle if it can be seen (not covered by the hole)
      if let transparentCircleColor = chart.transparentCircleColor
      {
        if transparentCircleColor != NSUIColor.clear &&
          chart.transparentCircleRadiusRatio > chart.holeRadiusRatio
        {
          let alpha = animator.phaseX * animator.phaseY
          let secondHoleRadius = radius * chart.transparentCircleRadiusRatio

          // make transparent
          context.setAlpha(CGFloat(alpha))
          context.setFillColor(transparentCircleColor.cgColor)

          // draw the transparent-circle
          context.beginPath()
          context.addEllipse(in: CGRect(
            x: center.x - secondHoleRadius,
            y: center.y - secondHoleRadius,
            width: secondHoleRadius * 2.0,
            height: secondHoleRadius * 2.0))
          context.addEllipse(in: CGRect(
            x: center.x - holeRadius,
            y: center.y - holeRadius,
            width: holeRadius * 2.0,
            height: holeRadius * 2.0))
          context.fillPath(using: .evenOdd)
        }
      }

      context.restoreGState()
    }
  }

  /// draws the description text in the center of the pie chart makes most sense when center-hole is enabled
  private func drawCenterText(context: CGContext)
  {
    guard
      let chart = chart,
      let centerAttributedText = chart.centerAttributedText
      else { return }

    if chart.drawsCenterText && centerAttributedText.length > 0
    {
      let center = chart.centerCircleBox
      let offset = chart.centerTextOffset
      let innerRadius = chart.drawsHole && !chart.drawsSlicesUnderHole ? chart.radius * chart.holeRadiusRatio : chart.radius

      let x = center.x + offset.x
      let y = center.y + offset.y

      let holeRect = CGRect(
        x: x - innerRadius,
        y: y - innerRadius,
        width: innerRadius * 2.0,
        height: innerRadius * 2.0)
      var boundingRect = holeRect

      if chart.centerTextRadiusRatio > 0.0
      {
        boundingRect = boundingRect.insetBy(dx: (boundingRect.width - boundingRect.width * chart.centerTextRadiusRatio) / 2.0, dy: (boundingRect.height - boundingRect.height * chart.centerTextRadiusRatio) / 2.0)
      }

      let textBounds = centerAttributedText.boundingRect(with: boundingRect.size, options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine], context: nil)

      var drawingRect = boundingRect
      drawingRect.origin.x += (boundingRect.size.width - textBounds.size.width) / 2.0
      drawingRect.origin.y += (boundingRect.size.height - textBounds.size.height) / 2.0
      drawingRect.size = textBounds.size

      context.saveGState()

      let clippingPath = CGPath(ellipseIn: holeRect, transform: nil)
      context.beginPath()
      context.addPath(clippingPath)
      context.clip()

      centerAttributedText.draw(with: drawingRect, options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine], context: nil)

      context.restoreGState()
    }
  }

  public func drawHighlighted(context: CGContext, indices: [Highlight])
  {
    guard
      let chart = chart,
      let data = chart.data
      else { return }

    guard data.highlightEnabled else { return }

    context.saveGState()

    let phaseX = animator.phaseX
    let phaseY = animator.phaseY

    var angle: CGFloat = 0.0
    let rotationAngle = chart.rotationAngle

    var drawAngles = chart.drawAngles
    var absoluteAngles = chart.absoluteAngles
    let center = chart.centerCircleBox
    let radius = chart.radius
    let drawInnerArc = chart.drawsHole && !chart.drawsSlicesUnderHole
    let userInnerRadius = drawInnerArc ? radius * chart.holeRadiusRatio : 0.0

    // Append highlighted accessibility slices into this array, so we can prioritize them over unselected slices
    var highlightedAccessibleElements: [NSUIAccessibilityElement] = []

    for i in 0 ..< indices.count
    {
      // get the index to highlight
      let index = indices[i].value
      if index >= drawAngles.count
      {
        continue
      }

      let entryCount = data.count
      var visibleAngleCount = 0
      for j in 0 ..< entryCount
      {
        guard let e = data[j] else { continue }
        if ((abs(e.value) > Double.ulpOfOne))
        {
          visibleAngleCount += 1
        }
      }

      if index == 0
      {
        angle = 0.0
      }
      else
      {
        angle = absoluteAngles[index - 1] * CGFloat(phaseX)
      }

      let sliceSpace = visibleAngleCount <= 1 ? 0.0 : data.sliceSpace

      let sliceAngle = drawAngles[index]
      var innerRadius = userInnerRadius

      let shift = data.selectionShift
      let highlightedRadius = radius + shift

      let accountForSliceSpacing = sliceSpace > 0.0 && sliceAngle <= 180.0

      context.setFillColor(data.highlightColor?.cgColor ?? data.color(at: index).cgColor)

      let sliceSpaceAngleOuter = visibleAngleCount == 1 ?
        0.0 :
        sliceSpace / radius.DEG2RAD

      let sliceSpaceAngleShifted = visibleAngleCount == 1 ?
        0.0 :
        sliceSpace / highlightedRadius.DEG2RAD

      let startAngleOuter = rotationAngle + (angle + sliceSpaceAngleOuter / 2.0) * CGFloat(phaseY)
      var sweepAngleOuter = (sliceAngle - sliceSpaceAngleOuter) * CGFloat(phaseY)
      if sweepAngleOuter < 0.0
      {
        sweepAngleOuter = 0.0
      }

      let startAngleShifted = rotationAngle + (angle + sliceSpaceAngleShifted / 2.0) * CGFloat(phaseY)
      var sweepAngleShifted = (sliceAngle - sliceSpaceAngleShifted) * CGFloat(phaseY)
      if sweepAngleShifted < 0.0
      {
        sweepAngleShifted = 0.0
      }

      let path = CGMutablePath()

      path.move(to: CGPoint(x: center.x + highlightedRadius * cos(startAngleShifted.DEG2RAD),
                            y: center.y + highlightedRadius * sin(startAngleShifted.DEG2RAD)))

      path.addRelativeArc(center: center, radius: highlightedRadius, startAngle: startAngleShifted.DEG2RAD,
                          delta: sweepAngleShifted.DEG2RAD)

      var sliceSpaceRadius: CGFloat = 0.0
      if accountForSliceSpacing
      {
        sliceSpaceRadius = calculateMinimumRadiusForSpacedSlice(
          center: center,
          radius: radius,
          angle: sliceAngle * CGFloat(phaseY),
          arcStartPointX: center.x + radius * cos(startAngleOuter.DEG2RAD),
          arcStartPointY: center.y + radius * sin(startAngleOuter.DEG2RAD),
          startAngle: startAngleOuter,
          sweepAngle: sweepAngleOuter)
      }

      if drawInnerArc &&
        (innerRadius > 0.0 || accountForSliceSpacing)
      {
        if accountForSliceSpacing
        {
          var minSpacedRadius = sliceSpaceRadius
          if minSpacedRadius < 0.0
          {
            minSpacedRadius = -minSpacedRadius
          }
          innerRadius = min(max(innerRadius, minSpacedRadius), radius)
        }

        let sliceSpaceAngleInner = visibleAngleCount == 1 || innerRadius == 0.0 ?
          0.0 :
          sliceSpace / innerRadius.DEG2RAD
        let startAngleInner = rotationAngle + (angle + sliceSpaceAngleInner / 2.0) * CGFloat(phaseY)
        var sweepAngleInner = (sliceAngle - sliceSpaceAngleInner) * CGFloat(phaseY)
        if sweepAngleInner < 0.0
        {
          sweepAngleInner = 0.0
        }
        let endAngleInner = startAngleInner + sweepAngleInner

        path.addLine(
          to: CGPoint(
            x: center.x + innerRadius * cos(endAngleInner.DEG2RAD),
            y: center.y + innerRadius * sin(endAngleInner.DEG2RAD)))

        path.addRelativeArc(center: center, radius: innerRadius,
                            startAngle: endAngleInner.DEG2RAD,
                            delta: -sweepAngleInner.DEG2RAD)
      }
      else
      {
        if accountForSliceSpacing
        {
          let angleMiddle = startAngleOuter + sweepAngleOuter / 2.0

          let arcEndPointX = center.x + sliceSpaceRadius * cos(angleMiddle.DEG2RAD)
          let arcEndPointY = center.y + sliceSpaceRadius * sin(angleMiddle.DEG2RAD)

          path.addLine(
            to: CGPoint(
              x: arcEndPointX,
              y: arcEndPointY))
        }
        else
        {
          path.addLine(to: center)
        }
      }

      path.closeSubpath()

      context.beginPath()
      context.addPath(path)
      context.fillPath(using: .evenOdd)

      let axElement = createAccessibleElement(withIndex: index,
                                              container: chart,
                                              data: data)
      { (element) in
        element.accessibilityFrame = path.boundingBoxOfPath
        element.isSelected = true
      }

      highlightedAccessibleElements.append(axElement)
    }

    // Prepend selected slices before the already rendered unselected ones.
    // NOTE: - This relies on drawDataSet() being called before drawHighlighted in PieChartView.
    accessibleChartElements.insert(contentsOf: highlightedAccessibleElements, at: 1)

    context.restoreGState()
  }

  /// Creates an NSUIAccessibilityElement representing a slice of the PieChart.
  /// The element only has it's container and label set based on the chart and dataSet. Use the modifier to alter traits and frame.
  private func createAccessibleElement(withIndex idx: Int,
                                       container: PieChartView,
                                       data: ChartData,
                                       modifier: (NSUIAccessibilityElement) -> ()) -> NSUIAccessibilityElement {

    let element = NSUIAccessibilityElement(accessibilityContainer: container)
    
    guard let e = data[idx] else { return element }
    guard let data = container.data else { return element }

    let formatter = data.valueFormatter ?? ChartUtils.defaultValueFormatter
    var elementValueText = formatter.stringForValue(
      e.value,
      entry: e,
      viewPortHandler: viewPortHandler)

    if container.usesPercentValues {
      let value = e.value / data.yValueSum * 100.0
      let valueText = formatter.stringForValue(
        value,
        entry: e,
        viewPortHandler: viewPortHandler)

      elementValueText = valueText
    }

    let pieChartDataEntry = data[idx]
    let isCount = data.accessibilityEntryLabelSuffixIsCount
    let prefix = data.accessibilityEntryLabelPrefix?.appending("\(idx + 1)") ?? pieChartDataEntry?.label ?? ""
    let suffix = data.accessibilityEntryLabelSuffix ?? ""
    element.accessibilityLabel = "\(prefix) : \(elementValueText) \(suffix  + (isCount ? (e.value == 1.0 ? "" : "s") : "") )"

    // The modifier allows changing of traits and frame depending on highlight, rotation, etc
    modifier(element)

    return element
  }
}

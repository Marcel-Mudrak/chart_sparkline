import 'dart:math' as math;
import 'dart:ui' as ui show PointMode;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Strategy used when filling the area of a sparkline.
enum FillMode {
  /// Do not fill, draw only the sparkline.
  none,

  /// Fill the area above the sparkline: creating a closed path from the line
  /// to the upper edge of the widget.
  above,

  /// Fill the area below the sparkline: creating a closed path from the line
  /// to the lower edge of the widget.
  below,
}

/// Strategy used when drawing individual data points over the sparkline.
enum PointsMode {
  /// Do not draw individual points.
  none,

  /// Draw all the points in the data set.
  all,

  /// Draw only the last point in the data set.
  last,

  /// Draw a point at a given index in the data set.
  atIndex,
}

/// A widget that draws a sparkline chart.
///
/// Represents the given [data] in a sparkline chart that spans the available
/// space.
///
/// By default only the sparkline is drawn, with its looks defined by
/// the [lineWidth], [lineColor], and [lineGradient] properties.
///
/// The y-scale of the sparkline will be determined by using the [data]'s
/// minimum and maximum value, unless overridden with [min] and/or [max].
///
/// The corners between two segments of the sparkline can be made sharper by
/// setting [sharpCorners] to true.
///
/// Conversely, to smooth out the curve drawn even more, set [useCubicSmoothing]
/// to true. The degree to which the cubic smoothing is applied can be changed
/// using [cubicSmoothingFactor]. A good range for [cubicSmoothingFactor]
/// is usually between 0.1 and 0.3.
///
/// The area above or below the sparkline can be filled with the provided
/// [fillColor] or [fillGradient] by setting the desired [fillMode].
///
/// [pointsMode] controls how individual points are drawn over the sparkline
/// at the provided data point. Their appearance is determined by the
/// [pointSize] and [pointColor] properties.
///
/// By default, the sparkline is sized to fit its container. If the
/// sparkline is in an unbounded space, it will size itself according to the
/// given [fallbackWidth] and [fallbackHeight].
class Sparkline extends StatelessWidget {
  /// Creates a widget that represents provided [data] in a Sparkline chart.
  Sparkline({
    Key? key,
    required this.data,
    this.animationController,
    this.xLabels = const [],
    this.xLabelsStyle = const TextStyle(
        color: Colors.black87, fontSize: 10.0, fontWeight: FontWeight.bold),
    this.xValueShow = false,
    this.xValueStyle = const TextStyle(
        color: Colors.black87, fontSize: 10.0, fontWeight: FontWeight.bold),
    this.backgroundColor,
    this.lineWidth = 1.0,
    this.lineColor = Colors.blue,
    this.lineGradient,
    // point
    this.pointsMode = PointsMode.none,
    this.pointIndex,
    this.pointSize = 4.0,
    this.pointColor = const Color(0xFF0277BD),
    this.pointsShape = StrokeCap.round,
    this.sharpCorners = false,
    // Smoothing
    this.useCubicSmoothing = false,
    this.cubicSmoothingFactor = 0.15,
    // Fill
    this.fillMode = FillMode.none,
    this.fillColor = const Color(0xFF81D4FA),
    this.fillGradient,
    this.fallbackHeight = 100.0,
    this.fallbackWidth = 300.0,
    //grid lines
    @Deprecated('Use gridLinesEnable instead.') this.enableGridLines = false,
    this.gridLinesEnable = false,
    this.gridLinelabel,
    this.gridLineColor = Colors.grey,
    this.gridLineAmount = 5,
    this.gridLineWidth = 0.5,
    this.gridLineLabelStyle = const TextStyle(
        color: Colors.grey, fontSize: 10.0, fontWeight: FontWeight.bold),
    this.gridLineLabelFixed = false,
    this.gridLinelabelPrefix = "",
    this.gridLinelabelSuffix = "",
    this.gridLineLabelPrecision = 3,
    @Deprecated('Use gridLineLabelStyle instead.') this.gridLineLabelColor,
    // threshold
    this.enableThreshold = false,
    this.thresholdSize = 0.3,
    this.max,
    this.min,
    // averageLine
    this.averageLine = false,
    this.averageLabel = true,
    this.averageLineColor = Colors.grey,
    this.maxLine = false,
    this.maxLabel = false,
    this.kLine,
  }) : super(key: key);

  /// List of values to be represented by the sparkline.
  ///
  /// Each data entry represents an individual point on the chart, with a path
  /// drawn connecting the consecutive points to form the sparkline.
  ///
  /// The values are normalized to fit within the bounds of the chart.
  final List<double> data;

  /// The width of the sparkline.
  ///
  /// Defaults to 1.0.
  final double lineWidth;

  /// The color of the sparkline.
  ///
  /// Defaults to Colors.lightBlue.
  ///
  /// This is ignored if [lineGradient] is non-null.
  final Color lineColor;

  /// A gradient to use when coloring the sparkline.
  ///
  /// If this is specified, [lineColor] has no effect.
  final Gradient? lineGradient;

  /// Determines how individual data points should be drawn over the sparkline.
  ///
  /// Defaults to [PointsMode.none].
  final PointsMode pointsMode;

  /// The shape of the points.
  /// defaults to [StrokeCap.round]
  final StrokeCap pointsShape;

  /// The index to draw a point at when pointsMode is atIndex.
  ///
  /// This is ignored if pointsMode is not atIndex.
  final int? pointIndex;

  /// The size to use when drawing individual data points over the sparkline.
  ///
  /// Defaults to 4.0.
  final double pointSize;

  /// The color used when drawing individual data points over the sparkline.
  ///
  /// Defaults to Colors.lightBlue[800].
  final Color pointColor;

  /// Determines if the sparkline path should have sharp corners where two
  /// segments intersect.
  ///
  /// Defaults to false.
  final bool sharpCorners;

  /// Determines if the sparkline path should use cubic beziers to smooth
  /// the curve when drawing. Read more about the algorithm used, here:
  ///
  /// https://medium.com/@francoisromain/smooth-a-svg-path-with-cubic-bezier-curves-e37b49d46c74
  ///
  /// Defaults to false.
  final bool useCubicSmoothing;

  /// How aggressively the sparkline should apply cubic beziers to smooth
  /// the curves. A good value is usually between 0.1 and 0.3.
  ///
  /// Defaults to 0.15.
  final double cubicSmoothingFactor;

  /// Determines the area that should be filled with [fillColor].
  ///
  /// Defaults to [FillMode.none].
  final FillMode fillMode;

  /// The fill color used in the chart, as determined by [fillMode].
  ///
  /// Defaults to Colors.lightBlue[200].
  ///
  /// This is ignored if [fillGradient] is non-null.
  final Color fillColor;

  /// A gradient to use when filling the chart, as determined by [fillMode].
  ///
  /// If this is specified, [fillColor] has no effect.
  final Gradient? fillGradient;

  /// The width to use when the sparkline is in a situation with an unbounded
  /// width.
  ///
  /// See also:
  ///
  ///  * [fallbackHeight], the same but vertically.
  final double fallbackWidth;

  /// The height to use when the sparkline is in a situation with an unbounded
  /// height.
  ///
  /// See also:
  ///
  ///  * [fallbackWidth], the same but horizontally.
  final double fallbackHeight;

  /// Enable or disable grid lines
  final bool enableGridLines;

  /// Enable or disable grid lines
  final bool gridLinesEnable;

  /// Grid line labels callback
  /// Takes the grid line Value and returns a string
  final String Function(double gridLineValue)? gridLinelabel;

  /// Color of grid lines and label text
  final Color gridLineColor;

  /// Color of grid line label text
  final Color? gridLineLabelColor;

  /// Style of grid line labels
  final TextStyle gridLineLabelStyle;

  /// Number of grid lines
  final int gridLineAmount;

  /// Width of grid lines
  final double gridLineWidth;

  /// Symbol prefix for grid line labels
  // final String labelPrefix;
  final String gridLinelabelPrefix;

  /// Symbol suffix for grid line labels
  // final String labelSuffix;
  final String gridLinelabelSuffix;

  /// Digit precision of grid line labels
  final int gridLineLabelPrecision;

  /// Define if graph should have threshold
  final bool enableThreshold;

  /// size of default threshold (in Percent) 0.0 ~ 1.0
  final double thresholdSize;

  /// The maximum value for the rendering box. Will default to the largest
  /// value in [data].
  final double? max;

  /// The minimum value for the rendering box. Will default to the largest
  /// value in [data].
  final double? min;

  /// kLine= ['max', 'min', 'first', 'last', 'all']
  final List? kLine;

  /// average Line
  final bool averageLine;

  /// average Line Color
  final Color averageLineColor;

  ///average Label
  final bool averageLabel;

  ///max Line
  final bool maxLine;

  ///max Label
  final bool maxLabel;

  ///backgroudColor
  final Color? backgroundColor;

  ///gridLineLabelFixed
  ///use toStringAsFixed format gridLineLabel
  final bool gridLineLabelFixed;

  /// xlabels
  final List<String> xLabels;

  /// xlabels style
  final TextStyle xLabelsStyle;

  /// xValueShow
  final bool xValueShow;

  /// xValueStyle
  final TextStyle xValueStyle;

  /// animationController
  final AnimationController? animationController;

  @override
  Widget build(BuildContext context) {
    return LimitedBox(
      maxWidth: fallbackWidth,
      maxHeight: fallbackHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparklinePainter(
          data,
          animationController: animationController,
          backgroundColor: backgroundColor,
          xLabels: xLabels,
          xLabelsStyle: xLabelsStyle,
          xValueShow: xValueShow,
          xValueStyle: xValueStyle,
          //
          lineWidth: lineWidth,
          lineColor: lineColor,
          lineGradient: lineGradient,
          sharpCorners: sharpCorners,
          //
          useCubicSmoothing: useCubicSmoothing,
          cubicSmoothingFactor: cubicSmoothingFactor,
          //
          fillMode: fillMode,
          fillColor: fillColor,
          fillGradient: fillGradient,
          //
          pointsMode: pointsMode,
          pointIndex: pointIndex,
          pointSize: pointSize,
          pointColor: pointColor,
          pointsShape: pointsShape,
          //
          gridLinesEnable: gridLinesEnable,
          gridLinelabel: gridLinelabel,
          gridLineColor: gridLineColor,
          gridLineAmount: gridLineAmount,
          gridLineLabelStyle: gridLineLabelStyle,
          gridLineWidth: gridLineWidth,
          gridLinelabelPrefix: gridLinelabelPrefix,
          gridLinelabelSuffix: gridLinelabelSuffix,
          gridLineLabelFixed: gridLineLabelFixed,
          gridLineLabelPrecision: gridLineLabelPrecision,
          //
          enableThreshold: enableThreshold,
          thresholdSize: thresholdSize,
          //
          max: max,
          min: min,
          //
          averageLine: averageLine,
          averageLineColor: averageLineColor,
          averageLabel: averageLabel,
          //
          maxLine: maxLine,
          maxLabel: maxLabel,
          //
          kLine: kLine,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(
    this.dataPoints, {
    this.animationController,
    required this.xLabels,
    required this.xLabelsStyle,
    required this.xValueShow,
    required this.xValueStyle,
    required this.lineWidth,
    required this.lineColor,
    required this.lineGradient,
    required this.sharpCorners,
    required this.useCubicSmoothing,
    required this.cubicSmoothingFactor,
    required this.fillMode,
    required this.fillColor,
    required this.fillGradient,
    required this.pointsMode,
    required this.pointIndex,
    required this.pointSize,
    required this.pointColor,
    required this.pointsShape,
    required this.enableThreshold,
    required this.thresholdSize,
    required this.gridLinesEnable,
    required this.gridLineColor,
    required this.gridLineAmount,
    required this.gridLineWidth,
    required this.gridLineLabelStyle,
    required this.gridLinelabelPrefix,
    required this.gridLinelabelSuffix,
    required this.gridLineLabelFixed,
    required this.gridLineLabelPrecision,
    required this.gridLinelabel,
    required double? max,
    required double? min,
    required this.maxLine,
    required this.maxLabel,
    required this.kLine,
    required this.averageLine,
    required this.averageLineColor,
    required this.averageLabel,
    required this.backgroundColor,
  })  : _max = max != null
            ? max
            : (dataPoints.isNotEmpty ? dataPoints.reduce(math.max) : 0.0),
        _min = min != null
            ? min
            : (dataPoints.isNotEmpty ? dataPoints.reduce(math.min) : 0.0);

  List<double> dataPoints;
  final AnimationController? animationController;
  final List<String> xLabels;
  final TextStyle xLabelsStyle;
  final bool xValueShow;
  final TextStyle xValueStyle;
  final double lineWidth;
  final Color lineColor;
  final Gradient? lineGradient;

  final bool sharpCorners;
  final bool useCubicSmoothing;
  final double cubicSmoothingFactor;

  final FillMode fillMode;
  final Color fillColor;
  final Gradient? fillGradient;

  final PointsMode pointsMode;
  final int? pointIndex;
  final double pointSize;
  final Color pointColor;
  final StrokeCap pointsShape;

  final bool enableThreshold;
  final double thresholdSize;

  final double _max;
  final double _min;

  final bool gridLinesEnable;
  final String Function(double gridLineValue)? gridLinelabel;
  final Color gridLineColor;
  final int gridLineAmount;
  final double gridLineWidth;
  final TextStyle gridLineLabelStyle;
  final String gridLinelabelPrefix;
  final String gridLinelabelSuffix;
  final int gridLineLabelPrecision;
  final bool averageLine;
  final Color averageLineColor;
  final bool averageLabel;
  final bool maxLine;
  final bool maxLabel;
  final List? kLine;
  final Color? backgroundColor;
  final bool gridLineLabelFixed;

  List<TextPainter> gridLineTextPainters = [];

  update() {
    if (gridLinesEnable) {
      double gridLineValue;
      for (int i = 0; i < gridLineAmount; i++) {
        // Label grid lines
        gridLineValue = _max - (((_max - _min) / (gridLineAmount - 1)) * i);

        String gridLineText = gridLinelabel != null
            ? gridLinelabel!(gridLineValue)
            : (gridLineLabelFixed
                ? gridLineValue.toStringAsFixed(gridLineLabelPrecision)
                : gridLineValue.toStringAsPrecision(gridLineLabelPrecision));

        gridLineTextPainters.add(TextPainter(
            text: TextSpan(
              text: gridLinelabelPrefix + gridLineText + gridLinelabelSuffix,
              style: gridLineLabelStyle,
            ),
            textDirection: TextDirection.ltr));
        gridLineTextPainters[i].layout();
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) {
      dataPoints = [0.0, 0.0];
    }
    if (dataPoints.length == 1) {
      dataPoints = [dataPoints[0], dataPoints[0]];
    }

    double width = size.width - lineWidth;

    if (xLabels.isNotEmpty) {
      var spPainter = TextPainter(
        text: TextSpan(
          text: xLabels[0],
          style: xLabelsStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      spPainter.layout();
      size = Size(size.width, size.height - spPainter.height);
    }

    final double height = size.height - lineWidth;
    final double heightNormalizer = (!enableThreshold)
        ? height / ((_max - _min) == 0 ? 1 : (_max - _min))
        : (height - (height * thresholdSize)) /
            ((_max - _min) == 0 ? 1 : (_max - _min));

    final List<Offset> points = <Offset>[];
    final List<Offset> normalized = <Offset>[];
    //max,min,first,last
    final Map spDataPoints = {
      'max': {'val': _max, 'offset': Offset(-1, -1)},
      'min': {'val': _min, 'offset': Offset(-1, -1)},
      'first': {'val': dataPoints.first, 'offset': Offset(-1, -1)},
      'last': {'val': dataPoints.last, 'offset': Offset(-1, -1)},
      'all': {'val': 0, 'offset': Offset(-1, -1)},
    };
    if (gridLineTextPainters.isEmpty) {
      update();
    }

    if (backgroundColor != null) {
      var paintBgcolor = Paint()
        ..style = PaintingStyle.fill
        ..color = backgroundColor!;
      canvas.drawRect(Offset.zero & size, paintBgcolor);
    }

    if (gridLinesEnable) {
      width = size.width - gridLineTextPainters[0].size.width;
      Paint gridPaint = Paint()
        ..color = gridLineColor
        ..strokeWidth = gridLineWidth;

      double gridLineDist = height / (gridLineAmount - 1);
      double gridLineY;

      // Draw grid lines
      for (int i = 0; i < gridLineAmount; i++) {
        gridLineY = (gridLineDist * i).round().toDouble();
        canvas.drawLine(
            Offset(0.0, gridLineY), Offset(width, gridLineY), gridPaint);

        // Label grid lines
        gridLineTextPainters[i]
            .paint(canvas, Offset(width + 2.0, gridLineY - 6.0));
      }
    }

    final double widthNormalizer = width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      double x = i * widthNormalizer + lineWidth / 2;
      double y = (!heightNormalizer.isInfinite)
          ? height - (dataPoints[i] - _min) * heightNormalizer + lineWidth / 2
          : height + lineWidth / 2;

      if (enableThreshold) {
        y = (y - (height * thresholdSize));
      }

      normalized.add(Offset(x, y));

      if (dataPoints[i] == spDataPoints['max']['val']) {
        if ((i != 0 && i != (dataPoints.length - 1))) {
          spDataPoints['max']['offset'] = normalized[i];
        }
      }
      if (dataPoints[i] == spDataPoints['min']['val']) {
        if (i != 0 && i != (dataPoints.length - 1)) {
          spDataPoints['min']['offset'] = normalized[i];
        }
      }

      if (pointsMode == PointsMode.all ||
          (pointsMode == PointsMode.last && i == dataPoints.length - 1) ||
          (pointsMode == PointsMode.atIndex && i == pointIndex)) {
        points.add(normalized[i]);
      }
    }

    spDataPoints['first']['offset'] = normalized.first;
    spDataPoints['last']['offset'] = normalized.last;

    Offset startPoint = normalized[0];
    final Path path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    ///xLabel
    if (xLabels.isNotEmpty) {
      for (int i = 0; i < xLabels.length; i++) {
        var spPainter = TextPainter(
            text: TextSpan(
              text: '${xLabels[i]}',
              style: xLabelsStyle,
            ),
            textDirection: TextDirection.ltr);
        spPainter.layout();
        var offsetY = height;
        var offsetX = 0.0;
        if (i == 0) {
          offsetX = normalized[i].dx;
        } else if (i == xLabels.length - 1) {
          offsetX = normalized[i].dx - spPainter.width;
        } else {
          offsetX = normalized[i].dx - spPainter.width / 2;
        }

        spPainter.paint(canvas, Offset(offsetX, offsetY + 2));
      }
    }

    if (useCubicSmoothing) {
      Offset a = normalized[0];
      Offset b = normalized[0];
      Offset c = normalized[1];
      for (int i = 1; i < normalized.length; i++) {
        double x1 = (c.dx - a.dx) * cubicSmoothingFactor + b.dx;
        double y1 = (c.dy - a.dy) * cubicSmoothingFactor + b.dy;
        a = b;
        b = c;
        c = normalized[math.min(normalized.length - 1, i + 1)];
        double x2 = (a.dx - c.dx) * cubicSmoothingFactor + b.dx;
        double y2 = (a.dy - c.dy) * cubicSmoothingFactor + b.dy;
        path.cubicTo(x1, y1, x2, y2, b.dx, b.dy);
      }
    } else {
      for (int i = 1; i < normalized.length; i++) {
        path.lineTo(normalized[i].dx, normalized[i].dy);
      }
    }

    Paint paint = Paint()
      ..strokeWidth = lineWidth
      ..color = lineColor
      ..strokeCap = pointsShape
      ..strokeJoin = sharpCorners ? StrokeJoin.miter : StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (lineGradient != null) {
      final Rect lineRect = Rect.fromLTWH(0.0, 0.0, width, height);
      paint.shader = lineGradient!.createShader(lineRect);
    }

    if (fillMode != FillMode.none) {
      Path fillPath = Path()..addPath(path, Offset.zero);
      if (fillMode == FillMode.below) {
        fillPath.relativeLineTo(lineWidth / 2, 0.0);
        // fillPath.lineTo(size.width, size.height);
        fillPath.lineTo(width + lineWidth / 2, size.height);
        fillPath.lineTo(0.0, size.height);
        fillPath.lineTo(startPoint.dx - lineWidth / 2, startPoint.dy);
      } else if (fillMode == FillMode.above) {
        fillPath.relativeLineTo(lineWidth / 2, 0.0);
        // fillPath.lineTo(size.width, 0.0);
        fillPath.lineTo(width + lineWidth / 2, 0.0);
        fillPath.lineTo(0.0, 0.0);
        fillPath.lineTo(startPoint.dx - lineWidth / 2, startPoint.dy);
      }
      fillPath.close();

      Paint fillPaint = Paint()
        ..strokeWidth = 0.0
        ..color = fillColor
        ..style = PaintingStyle.fill;
      if (fillGradient != null) {
        final Rect fillRect = Rect.fromLTWH(0.0, 0.0, width, height);
        fillPaint.shader = fillGradient!.createShader(fillRect);
      }
      canvas.drawPath(fillPath, fillPaint);
    }

    //average line
    if (averageLine) {
      //
      var paint1 = Paint()
        ..style = PaintingStyle.stroke
        ..color = averageLineColor
        ..strokeWidth = 2.0;

      for (int i = 0; i <= (width / 6.0); ++i) {
        double dx = 6.0 * i;
        canvas.drawLine(
            Offset(dx, height / 2), Offset(dx, height / 2 + 1), paint1);
      }
      if (averageLabel) {
        var averageVal = dataPoints.reduce((a, b) => a + b) / dataPoints.length;
        String averageValText = gridLineLabelFixed
            ? averageVal.toStringAsFixed(gridLineLabelPrecision)
            : averageVal.toStringAsPrecision(gridLineLabelPrecision);
        var avgPaint = TextPainter(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: gridLinelabelPrefix + averageValText + gridLinelabelSuffix,
              style: TextStyle(
                textBaseline: TextBaseline.alphabetic,
                // height: 1.1,
                color: Colors.white,
                fontSize: 10.0,
              ),
            ),
            textDirection: TextDirection.ltr);
        avgPaint.layout();
        RRect rect = RRect.fromLTRBR(
            size.width -
                (gridLinesEnable ? avgPaint.width * 2 : avgPaint.width) -
                10.0,
            height / 2 - avgPaint.height / 2,
            width,
            height / 2 + avgPaint.height / 2,
            Radius.circular(1.0));
        var paint = Paint()
          ..style = PaintingStyle.fill
          ..color = gridLineColor;
        canvas.drawRRect(rect, paint);
        //
        avgPaint.paint(
            canvas, Offset(width - avgPaint.width - 5.0, height / 2 - 5.0));
      }
    }

    //max line

    // the line will be positioned on the point of the biggest value
    // so we will not take the
    final maxVal = dataPoints.reduce(math.max);
    final maxDy = height - (maxVal - _min) * heightNormalizer + lineWidth / 2;

    if (maxLine) {
      //
      var paint1 = Paint()
        ..style = PaintingStyle.stroke
        ..color = gridLineColor
        ..strokeWidth = 2.0;

      for (int i = 0; i <= (width / 6.0); ++i) {
        double dx = 6.0 * i;
        canvas.drawLine(
          Offset(dx, maxDy),
          Offset(dx, maxDy + 1),
          paint1,
        );
      }
    }

    if (maxLabel) {
      String maxValText = gridLineLabelFixed
          ? maxVal.toStringAsFixed(gridLineLabelPrecision)
          : maxVal.toStringAsPrecision(gridLineLabelPrecision);
      var maxPaint = TextPainter(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: gridLinelabelPrefix + maxValText + gridLinelabelSuffix,
            style: gridLineLabelStyle,
          ),
          textDirection: TextDirection.ltr);
      maxPaint.layout();
      final hgh = maxDy;
      RRect rect = RRect.fromLTRBR(
          size.width - maxPaint.width - 10.0,
          hgh - maxPaint.height / 2,
          width,
          hgh + maxPaint.height / 2,
          Radius.circular(1.0));
      var paint = Paint()
        ..style = PaintingStyle.fill
        ..color = gridLineColor;
      canvas.drawRRect(rect, paint);
      //
      maxPaint.paint(canvas, Offset(width - maxPaint.width - 5.0, maxDy - 5.0));
    }

    if (kLine != null && kLine!.isNotEmpty) {
      for (var item in kLine!) {
        var val = spDataPoints[item]['val'];
        var spPainter = TextPainter(
            text: TextSpan(
                text: val.toString(),
                style: TextStyle(
                    color: gridLineColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr);
        spPainter.layout();
        var spOffset = spDataPoints[item]['offset'];

        switch (item) {
          case 'last':
            spOffset = Offset(width - spPainter.width - 6,
                spOffset.dy - spPainter.height / 2);

            spPainter.paint(canvas, spOffset);
            break;
          case 'first':
            spOffset = Offset(6.0, spOffset.dy - spPainter.height / 2);
            spPainter.paint(canvas, spOffset);
            break;
          case 'max':
            if ((spOffset != Offset(-1, -1))) {
              spOffset =
                  Offset(spOffset.dx - spPainter.width / 2, spOffset.dy + 6);
              spPainter.paint(canvas, spOffset);
            } else {
              if (!kLine!.contains('first')) {
                if (spDataPoints['max']['val'] ==
                    spDataPoints['first']['val']) {
                  spOffset = spDataPoints['first']['offset'];
                  spOffset = Offset(6.0, spOffset.dy - spPainter.height / 2);
                  spPainter.paint(canvas, spOffset);
                }
              }
              if (!kLine!.contains('last')) {
                if (spDataPoints['max']['val'] == spDataPoints['last']['val']) {
                  spOffset = spDataPoints['last']['offset'];
                  spOffset = Offset(width - spPainter.width - 6,
                      spOffset.dy - spPainter.height / 2);
                  spPainter.paint(canvas, spOffset);
                }
              }
            }
            break;
          case 'min':
            if ((spOffset != Offset(-1, -1))) {
              spOffset =
                  Offset(spOffset.dx - spPainter.width / 2, spOffset.dy - 18);
              spPainter.paint(canvas, spOffset);
            } else {
              if (!kLine!.contains('first')) {
                if (spDataPoints['min']['val'] ==
                    spDataPoints['first']['val']) {
                  spOffset = spDataPoints['first']['offset'];
                  spOffset = Offset(6.0, spOffset.dy - spPainter.height / 2);
                  spPainter.paint(canvas, spOffset);
                }
              }
              if (!kLine!.contains('last')) {
                if (spDataPoints['min']['val'] == spDataPoints['last']['val']) {
                  spOffset = spDataPoints['last']['offset'];
                  spOffset = Offset(width - spPainter.width - 6,
                      spOffset.dy - spPainter.height / 2);
                  spPainter.paint(canvas, spOffset);
                }
              }
            }
            break;
          default:
        }
      }
    }
    if (xValueShow) {
      for (int i = 0; i < dataPoints.length; i++) {
        var spPainter = TextPainter(
            text: TextSpan(
              text: '${dataPoints[i]}',
              style: xValueStyle,
            ),
            textDirection: TextDirection.ltr);
        spPainter.layout();
        var normalizedOffset = normalized[i];

        var offsetY = 0.0;
        // if (normalizedOffset.dy - spPainter.height <= 0) {
        //   offsetY = normalizedOffset.dy + 2;
        // }
        // if (normalizedOffset.dy >= height) {
        //   offsetY = height - spPainter.height - 2;
        // }

        var offsetX = 0.0;
        if (i == 0) {
          offsetX = normalizedOffset.dx;
        } else if (i == dataPoints.length - 1) {
          offsetX = normalizedOffset.dx - spPainter.width;
        } else {
          offsetX = normalizedOffset.dx - spPainter.width / 2;
        }

        var pointOffset = Offset(offsetX, offsetY);
        spPainter.paint(canvas, pointOffset);
      }
    }

    if (animationController != null) {
      PathMetrics pathMetrics = path.computeMetrics();
      PathMetric pathMetric = pathMetrics.elementAt(0);
      Path extracted = pathMetric.extractPath(
          0.0, pathMetric.length * animationController!.value);
      canvas.drawPath(extracted, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    if (points.isNotEmpty) {
      Paint pointsPaint = Paint()
        ..strokeCap = pointsShape
        ..strokeWidth = pointSize
        ..color = pointColor;
      canvas.drawPoints(ui.PointMode.points, points, pointsPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) {
    return old != this;
  }
}

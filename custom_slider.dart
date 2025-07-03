import 'package:bitsafe/utils/hexToColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomSmartSlider extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;
  final List<double> presetPoints;
  final int? nodeCount; // 新增：节点数量（可选）
  final void Function(int index, double value)? onNodeChanged; // 新增：节点回调
  final double? height; // 新增：自定义高度
  final double? width; // 新增：自定义宽度
  final bool? showNode; // 是否显示节点值
  final String? unit; //单位
  const CustomSmartSlider(
      {super.key,
      required this.min,
      required this.max,
      required this.value,
      required this.onChanged,
      required this.presetPoints,
      this.nodeCount,
      this.onNodeChanged,
      this.height,
      this.width,
      this.showNode = false,
      this.unit = ''});
  @override
  State<CustomSmartSlider> createState() => _CustomSmartSliderState();
}

class _CustomSmartSliderState extends State<CustomSmartSlider> {
  late double _value;
  int? _lastNodeIndex; // 新增：记录上一次经过的节点

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(CustomSmartSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _value = widget.value;
    }
  }

  void _onChanged(double newValue) {
    setState(() {
      _value = newValue;
    });
    if (widget.presetPoints.contains(newValue)) {
      HapticFeedback.lightImpact();
    }
    widget.onChanged(_value);
  }

  // 新增：判断当前值经过哪个节点并震动
  void _checkNodeHaptic(List<double> nodePoints, double value) {
    if (nodePoints.isEmpty) return;
    int? currentIdx;
    for (int i = 0; i < nodePoints.length; i++) {
      if ((value - nodePoints[i]).abs() < 0.01) {
        currentIdx = i;
        break;
      }
    }
    if (currentIdx != null && currentIdx != _lastNodeIndex) {
      HapticFeedback.heavyImpact();
      _lastNodeIndex = currentIdx;
    }
    if (currentIdx == null) {
      _lastNodeIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const trackHeight = 7.0;
      const thumbRadius = 10.0;
      const trackPadding = thumbRadius;

      final sliderHeight = widget.height ?? 40.0;
      final sliderWidth = widget.width ?? constraints.maxWidth;
      final trackStart = trackPadding;
      final trackEnd = sliderWidth - trackPadding;

      double ratio = (_value - widget.min) / (widget.max - widget.min);
      double thumbX = trackStart + ratio * (trackEnd - trackStart);
      double centerY = sliderHeight / 2;

      // 新增：根据 nodeCount 生成节点
      List<double> nodePoints = widget.nodeCount != null
          ? List.generate(
              widget.nodeCount!,
              (i) =>
                  widget.min +
                  (widget.max - widget.min) * (i / (widget.nodeCount! - 1)),
            )
          : [];

      return SizedBox(
        height: sliderHeight + (widget.showNode! ? 15 : 0),
        width: sliderWidth,
        child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              double dx = details.localPosition.dx.clamp(trackStart, trackEnd);
              double newRatio = (dx - trackStart) / (trackEnd - trackStart);
              double newValue =
                  widget.min + newRatio * (widget.max - widget.min);
              _checkNodeHaptic(nodePoints, newValue); // 新增：滑动经过节点时震动
              _onChanged(newValue);
            },
            child: Stack(children: [
              Positioned.fill(
                  child: CustomPaint(
                      painter: _TrackPainter(
                          min: widget.min,
                          max: widget.max,
                          value: _value,
                          presetPoints: widget.presetPoints,
                          nodePoints: nodePoints, // 新增
                          activeColor: HexColor.fromHex("#15E0A0"),
                          inactiveColor: HexColor.fromHex("#D8F9F0"),
                          trackHeight: trackHeight,
                          trackPadding: trackPadding,
                          centerY: centerY // 新增
                          ))),

              // 预设点击区域
              ...widget.presetPoints.map((point) {
                double ratio = (point - widget.min) / (widget.max - widget.min);
                double pointX = trackStart + ratio * (trackEnd - trackStart);
                return Positioned(
                    left: pointX - 12,
                    top: centerY - 20,
                    width: 24,
                    height: 40,
                    child: GestureDetector(
                        onTap: () => _onChanged(point),
                        behavior: HitTestBehavior.translucent,
                        child: const SizedBox.expand()));
              }),

              // 新增：节点点击区域
              ...nodePoints.asMap().entries.map((entry) {
                int idx = entry.key;
                double point = entry.value;
                double ratio = (point - widget.min) / (widget.max - widget.min);
                double pointX = trackStart + ratio * (trackEnd - trackStart);
                return Positioned(
                    left: pointX - 12,
                    top: centerY - 20,
                    width: 24,
                    height: 40,
                    child: GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact(); // 新增：点击节点震动
                          _onChanged(point);
                          if (widget.onNodeChanged != null) {
                            widget.onNodeChanged!(idx, point);
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                        child: const SizedBox.expand()));
              }),
              // 新增可选节点值显示
              if (widget.showNode!)
                ...widget.presetPoints.asMap().entries.map((entry) {
                  int idx = entry.key;
                  double point = entry.value;
                  double ratio =
                      (point - widget.min) / (widget.max - widget.min);
                  double pointX = trackStart + ratio * (trackEnd - trackStart);

                  Alignment align;
                  double left;
                  double width = 50;
                  if (idx == 0) {
                    // 第一个左对齐
                    align = Alignment.centerLeft;
                    left = pointX - 10;
                  } else if (idx == widget.presetPoints.length - 1) {
                    // 最后一个右对齐
                    align = Alignment.centerRight;
                    left = pointX - width + 10;
                  } else {
                    // 其它居中
                    align = Alignment.center;
                    left = pointX - width / 2;
                  }

                  // 新增：判断当前滑块是否超过或处于该节点
                  bool isActive = _value >= point;

                  return Positioned(
                    left: left,
                    top: centerY + 10,
                    width: width,
                    height: 24,
                    child: Align(
                      alignment: align,
                      child: Text(
                        "${point.toStringAsFixed(0)}${widget.unit}",
                        style: TextStyle(
                            color: isActive
                                ? HexColor.fromHex("#15E0A0")
                                : Colors.black54
                            // fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                      ),
                    ),
                  );
                }),
              // 滑块
              Positioned(
                  left: thumbX - thumbRadius,
                  top: centerY - thumbRadius,
                  child: Container(
                      width: thumbRadius * 2,
                      height: thumbRadius * 2,
                      decoration: BoxDecoration(
                          color: HexColor.fromHex("#15E0A0"),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: HexColor.fromHex("#28F46C"), width: 2))))
            ])),
      );
    });
  }
}

class _TrackPainter extends CustomPainter {
  final double min;
  final double max;
  final double value;
  final List<double> presetPoints;
  final List<double> nodePoints; // 新增
  final Color activeColor;
  final Color inactiveColor;
  final double trackHeight;
  final double trackPadding;
  final double centerY; // 新增

  _TrackPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.presetPoints,
    this.nodePoints = const [], // 新增
    required this.activeColor,
    required this.inactiveColor,
    required this.trackHeight,
    required this.trackPadding,
    required this.centerY, // 新增
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = centerY;
    final startX = trackPadding;
    final endX = size.width - trackPadding;

    final valueRatio = (value - min) / (max - min);
    final valueX = startX + valueRatio * (endX - startX);

    final basePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = trackHeight;

    // 背景轨道
    basePaint.color = inactiveColor;
    canvas.drawLine(Offset(startX, y), Offset(endX, y), basePaint);

    // 有效进度轨道
    basePaint.color = activeColor;
    canvas.drawLine(Offset(startX, y), Offset(valueX, y), basePaint);

    // 绘制预设点
    for (double point in presetPoints) {
      double ratio = (point - min) / (max - min);
      double pointX = startX + ratio * (endX - startX);
      bool isActive = point <= value;

      // 外边框
      final borderPaint = Paint()
        ..color = isActive ? HexColor.fromHex("#28F46C") : Colors.black
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // 内部背景
      final fillPaint = Paint()
        ..color = isActive ? HexColor.fromHex("#15E0A0") : Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(pointX, y), 5, fillPaint);
      canvas.drawCircle(Offset(pointX, y), 5, borderPaint);
    }

    // 新增：绘制节点
    for (double point in nodePoints) {
      double ratio = (point - min) / (max - min);
      double pointX = startX + ratio * (endX - startX);
      bool isActive = point <= value;

      final borderPaint = Paint()
        ..color = isActive ? HexColor.fromHex("#28F46C") : Colors.grey
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final fillPaint = Paint()
        ..color = isActive ? HexColor.fromHex("#15E0A0") : Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(pointX, y), 6, fillPaint);
      canvas.drawCircle(Offset(pointX, y), 6, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.presetPoints != presetPoints ||
        oldDelegate.nodePoints != nodePoints;
  }
}

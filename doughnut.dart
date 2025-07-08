import 'dart:math';
import 'package:flutter/material.dart';

import 'doughnut_painter.dart';

class Doughnut extends StatefulWidget {
  final double size;
  final String? selectedKey;
  final List<Sector> data;
  final double borderRadius;
  final double gap; // 扇区间隙，单位弧度
  final double expandedThickness; // 扩展厚度
  final double innerRadius; // 内圈半径
  final void Function(String id)? onSectorTap; // 点击回调
  final Widget? child; // 中心自定义组件
  final bool? isSmart;
  const Doughnut({
    super.key,
    this.size = 300,
    required this.data,
    this.selectedKey,
    this.borderRadius = 8,
    this.gap = 0,
    this.expandedThickness = 10,
    this.innerRadius = 0,
    this.onSectorTap,
    this.isSmart = true,
    this.child,
  });

  @override
  State<Doughnut> createState() => _DoughnutState();
}

class _DoughnutState extends State<Doughnut>
    with SingleTickerProviderStateMixin {
  String? _selectedKey;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.selectedKey;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant Doughnut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedKey != oldWidget.selectedKey) {
      _selectedKey = widget.selectedKey;
      _animationController.forward(from: 0);
    }
  }

  PieChartPainter? _painter;

  void _handleTapDown(TapDownDetails details, Size size) {
    final tapPosition = details.localPosition;

    if (_painter != null) {
      final hitSectorId = _painter!.hitTestSector(tapPosition);
      if (hitSectorId != null) {
        setState(() {
          _selectedKey = hitSectorId;
        });
        _animationController.forward(from: 0);
        if (widget.onSectorTap != null) {
          widget.onSectorTap!(hitSectorId);
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onTapDown: (details) =>
            _handleTapDown(details, Size(widget.size, widget.size)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _painter = PieChartPainter(
                      sectors: widget.data,
                      borderRadius: widget.borderRadius,
                      gap: widget.gap,
                      expandedThickness:
                          widget.expandedThickness * _animation.value,
                      innerRadius: widget.innerRadius,
                      selectedKey: _selectedKey,
                      isSmart: widget.isSmart),
                );
              },
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<Sector> sectors;
  final double borderRadius;
  final double gap;
  final double expandedThickness;
  final double innerRadius;
  final String? selectedKey;
  final bool? isSmart;
  // 新增字段，存储扇区路径
  final Map<String, Path> sectorPaths = {};

  PieChartPainter(
      {required this.borderRadius,
      required this.sectors,
      this.gap = 0,
      this.expandedThickness = 10,
      this.innerRadius = 0,
      this.selectedKey,
      this.isSmart = true});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius =
        (size.width > size.height ? size.height : size.width) / 2;
    final center = Point(size.width / 2, size.height / 2);

    final int sectorCount = sectors.length;
    final double totalGapRadian = gap * sectorCount;
    final double availableRadian = 2 * pi - totalGapRadian;

    double startRadian = -pi / 2;

    sectorPaths.clear();
    double currentAngle = startRadian;

    for (int index = 0; index < sectors.length; index++) {
      final innerPath = Path();
      double sectorPercent = sectors[index].value / 100;

      // ✅ 不再剥削扇区的角度
      double sectorRadian = sectorPercent * availableRadian;

      double sectorRadius = radius;
      double sectorWidth = radius - innerRadius;

      if (selectedKey != null && sectors[index].id == selectedKey) {
        sectorRadius += expandedThickness;
        sectorWidth += expandedThickness;
      }

      final doughnutPainter = DoughnutPainter(
        center: center,
        radius: sectorRadius,
        width: sectorWidth,
        borderRadius: isSmart!
            ? (sectorRadian * 10 > 8 ? 8 : sectorRadian * 10)
            : borderRadius,
      );

      // ✅ 直接用 currentAngle 作为 start
      doughnutPainter.drawRoundedArc(
        innerPath,
        settings: SectorSettings(
          sweepRadian: sectorRadian,
          startRadian: currentAngle,
        ),
      );

      // 保存路径
      sectorPaths[sectors[index].id] = Path.from(innerPath);

      final paint = Paint()..color = sectors[index].color;
      innerPath.close();
      final updatedPath = doughnutPainter.combineWithCenterCircle(innerPath)
        ..close();
      canvas.drawPath(updatedPath, paint);

      // ✅ 每次推进：真实角度 + gapRadian
      currentAngle += sectorRadian + gap;
    }
  }

  // 新增方法，判断点击点是否在某个扇区路径内，避免覆盖CustomPainter的hitTest方法
  String? hitTestSector(Offset point) {
    for (var entry in sectorPaths.entries) {
      if (entry.value.contains(point)) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Sector {
  final String id;
  final double value;
  final Color color;

  Sector({required this.id, required this.value, required this.color});
}

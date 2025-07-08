import 'dart:math';
import 'package:flutter/material.dart';

class DoughnutPainter {
  final Point<double> center;
  final double radius;
  final double width;
  final double borderRadius;

  DoughnutPainter({
    required this.center,
    required this.radius,
    required this.width,
    required this.borderRadius,
  });

  Offset get centerOffset => Offset(center.x, center.y);

  drawRoundedArc(Path path, {required SectorSettings settings}) {
    final double verticalBorderRadiusValue = borderRadius;
    final double horizontalBorderRadiusValue = borderRadius / 100;

    final cornerA = Corner(
      center: center,
      radius: radius,
      radian: settings.startRadian,
    );
    final cornerB = Corner(
      center: center,
      radius: radius,
      radian: settings.startRadian + settings.sweepRadian,
    );
    final cornerC = Corner(
      center: center,
      radius: radius - width,
      radian: settings.startRadian + settings.sweepRadian,
    );
    final cornerD = Corner(
      center: center,
      radius: radius - width,
      radian: settings.startRadian,
    );

    final cornerAPoint = cornerA.point;
    final cornerAPoint1 =
        cornerA.move(radius: -verticalBorderRadiusValue).point;
    final cornerAPoint2 =
        cornerA.move(radian: horizontalBorderRadiusValue).point;

    path.moveTo(cornerAPoint2.x.toDouble(), cornerAPoint2.y.toDouble());

    path.arcTo(
      Rect.fromCircle(center: centerOffset, radius: radius),
      settings.startRadian + horizontalBorderRadiusValue,
      settings.sweepRadian - (horizontalBorderRadiusValue * 2),
      false,
    );

    final cornerBPoint = cornerB.point;
    final cornerBPoint2 =
        cornerB.move(radius: -verticalBorderRadiusValue).point;

    path.quadraticBezierTo(
      cornerBPoint.x.toDouble(),
      cornerBPoint.y.toDouble(),
      cornerBPoint2.x.toDouble(),
      cornerBPoint2.y.toDouble(),
    );

    final cornerCPoint = cornerC.point;
    final cornerCPoint1 = cornerC.move(radius: verticalBorderRadiusValue).point;
    final cornerCPoint2 =
        cornerC.move(radian: -horizontalBorderRadiusValue).point;

    path.lineTo(cornerCPoint1.x.toDouble(), cornerCPoint1.y.toDouble());

    path.quadraticBezierTo(
      cornerCPoint.x.toDouble(),
      cornerCPoint.y.toDouble(),
      cornerCPoint2.x.toDouble(),
      cornerCPoint2.y.toDouble(),
    );

    final cornerDPoint = cornerD.point;
    final cornerDPoint1 =
        cornerD.move(radian: horizontalBorderRadiusValue).point;
    final cornerDPoint2 = cornerD.move(radius: verticalBorderRadiusValue).point;

    path.lineTo(cornerDPoint1.x.toDouble(), cornerDPoint1.y.toDouble());

    path.quadraticBezierTo(
      cornerDPoint.x.toDouble(),
      cornerDPoint.y.toDouble(),
      cornerDPoint2.x.toDouble(),
      cornerDPoint2.y.toDouble(),
    );

    path.lineTo(cornerAPoint1.x.toDouble(), cornerAPoint1.y.toDouble());

    path.quadraticBezierTo(
      cornerAPoint.x.toDouble(),
      cornerAPoint.y.toDouble(),
      cornerAPoint2.x.toDouble(),
      cornerAPoint2.y.toDouble(),
    );
  }

  Path combineWithCenterCircle(Path path) {
    final centerCirclePath = Path();
    centerCirclePath.addOval(
      Rect.fromCircle(
        center: Offset(center.x.toDouble(), center.y.toDouble()),
        radius: radius - width,
      ),
    );
    centerCirclePath.close();
    return Path.combine(
      PathOperation.difference,
      path,
      centerCirclePath,
    );
  }
}

class SectorSettings {
  final double startRadian;
  final double sweepRadian;

  SectorSettings({
    required this.startRadian,
    required this.sweepRadian,
  });
}

class Corner {
  final Point<double> center;
  final double radian;
  final double radius;

  Corner({required this.center, required this.radian, required this.radius});

  Point get point =>
      Point(center.x + radius * cos(radian), center.y + radius * sin(radian));

  Corner move({Point<double>? center, double? radian, double? radius}) {
    return Corner(
      center: center ?? this.center,
      radius: radius != null ? (this.radius + radius) : this.radius,
      radian: radian != null ? (this.radian + radian) : this.radian,
    );
  }
}
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../img_edit/core/extended_cover_image.dart';

class ImageCoverUtils {

  //获取image的位置
  static Rect getImageRect(Rect layoutRect, ui.Image image) {
    Size outputSize = Size(layoutRect.width, layoutRect.height);
    Size imageSize = new Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes fittedSizes =
    applyBoxFit(BoxFit.contain, imageSize, outputSize);
    final Size sourceSize = fittedSizes.source;
    Size destinationSize = fittedSizes.destination;
    return Rect.fromLTWH(
        (outputSize.width - destinationSize.width) / 2,
        (outputSize.height - destinationSize.height) / 2,
        destinationSize.width,
        destinationSize.height);
  }


  static void paint(Canvas canvas, Size outputSize,ui.Image image,List<Point> points,Paint imagePaint,Paint linePaint) {
    Rect rcImage = ImageCoverUtils.getImageRect(
        Rect.fromLTWH(0, 0, outputSize.width, outputSize.height), image);

    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rcImage,
        imagePaint);
    //根据数组绘制多条线
    for (int i = 0; i < points.length; i++) {
      linePaint.color = points[i].color;
      linePaint.strokeWidth = points[i].strokeWidth;
      //绘制框
      Rect rect = points[i].rect;
      if (rect != null) {
        canvas.drawRect(Rect.fromLTWH(
            rcImage.left + rect.left * rcImage.width / image.width.toDouble(),
            rcImage.top + rect.top * rcImage.width / image.width.toDouble(),
            rect.width * rcImage.width / image.width.toDouble(),
            rect.height * rcImage.width / image.width.toDouble()),
            linePaint);
        continue;
      }

      List<Offset> curPoints = points[i].points;
      if (curPoints == null || curPoints.length == 0) {
        continue;
      }

      for (int i = 0; i < curPoints.length - 1; i++) {
        //这些point都是相对image的位置
        if (curPoints[i] != null && curPoints[i + 1] != null) {
          Offset p = rcImage.topLeft + curPoints[i] * rcImage.width / image.width.toDouble();
          Offset p1 = rcImage.topLeft + curPoints[i + 1] * rcImage.width / image.width.toDouble();
          //canvas.drawLine(curPoints[i], curPoints[i + 1], _linePaint);
          canvas.drawLine(p,p1, linePaint);
        }
      }
    }
  }

}
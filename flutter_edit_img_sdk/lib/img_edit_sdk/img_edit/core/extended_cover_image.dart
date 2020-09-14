import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/image_cover/extended_image_cover_utils.dart';


class Point {
  Color color;
  double strokeWidth = 5.0;
  ///点序列，线
  List<Offset> points;
  ///点序列，方形
  Rect rect;

  Point(this.color, this.strokeWidth, this.points);
}

class ExtendedCoverImage extends StatefulWidget {
  final double strokeWidth;
  final Color strokeColor;
  final bool isClear;
  final List<Point> points;
  ui.Image image;

  ExtendedCoverImage({
    @required Key key,
    @required this.image,
    @required this.points,
    @required this.strokeColor,
    @required this.strokeWidth,
    this.isClear = true,
  }) : super(key: key);

  @override
  ExtendedCoverImageState createState() => ExtendedCoverImageState();
}

class ExtendedCoverImageState extends State<ExtendedCoverImage> {
  GlobalKey _paintKey = GlobalKey();

  List<Point> get points => widget.points;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, state) {
      return CustomPaint(
        key: _paintKey,
        painter: ScrawlPainter(
          image: widget.image,
          points: widget.points,
          strokeColor: widget.strokeColor,
          strokeWidth: widget.strokeWidth,
          isClear: widget.isClear,
        ),
      );
    });
  }

  //获取image渲染的top-left
  Offset getImageRenderOffset(int rotation,double scale) {
    RenderBox box = _paintKey.currentContext.findRenderObject();
    Offset topLeft = box.localToGlobal(Offset.zero);
    Rect rcImage = ImageCoverUtils.getImageRect(
        Rect.fromLTWH(0,0, box.size.width * scale, box.size.height * scale), widget.image);

    switch(rotation){
      case 90:
        return new Offset(topLeft.dx - rcImage.top,topLeft.dy + rcImage.left);
      case 180:
        return new Offset(topLeft.dx - rcImage.left,topLeft.dy - rcImage.top);
      case 270:
        return new Offset(topLeft.dx + rcImage.top,topLeft.dy - rcImage.left);
    }
    return topLeft + rcImage.topLeft;
  }

  //获取image未缩放前的size
  Size getImageInitSize() {
    RenderBox box = _paintKey.currentContext.findRenderObject();
    Rect rect = ImageCoverUtils.getImageRect(
        Rect.fromLTWH(0, 0, box.size.width, box.size.height), widget.image);
    return Size(rect.width, rect.height);
  }


}

class ScrawlPainter extends CustomPainter {
  final double strokeWidth;
  final Color strokeColor;
  final bool isClear;
  final List<Point> points;

  ui.Image image;
  Paint _imagePaint;
  Paint _linePaint;

  ScrawlPainter({
    @required key,
    @required this.image,
    @required this.points,
    @required this.strokeColor,
    @required this.strokeWidth,
    this.isClear = true,
  }) {
    _imagePaint = Paint();
    _linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
  }

  void paint(Canvas canvas, Size size) {
    if(image == null){
      debugPrint("image is null");
    }else{
      debugPrint("image is not null");
    }
    if (isClear || image == null) {
      return;
    }

    int time = DateTime.now().millisecondsSinceEpoch;
    ImageCoverUtils.paint(canvas, size, image, points, _imagePaint, _linePaint);
    print("draw time:" + (DateTime.now().millisecondsSinceEpoch - time).toString());
  }

  bool shouldRepaint(ScrawlPainter other) => true;
}

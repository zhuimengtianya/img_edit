import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/image_cover/extended_image_cover_utils.dart';
import 'core/extended_cover_image.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCover extends StatefulWidget {
  ///构建绘制UI
  ui.Image _paintImage;
  ImageCover(Key key,this._paintImage):super(key:key);

  @override
  State<StatefulWidget> createState() {
    return ImageCoverState();
  }
}

class ImageCoverState extends State<ImageCover>{
  ///设置遮盖初始化操作.
  static final List<double> lineWidths = [5.0, 8.0, 10.0];
  static final List<Color> colors = [
    Colors.black,
  ];
  final GlobalKey<ExtendedCoverImageState> _paintKey =
  GlobalKey<ExtendedCoverImageState>();


  ///更新按钮图片
  bool _backBtn = false;
  bool _frontBtn = false;
  int curFrame = 0;
  int selectedLine = 0;
  bool isClear = false;
  List<Point> pointsFront = [];
  Color selectedColor = colors[0];
  double get strokeWidth => lineWidths[selectedLine];
  List<Point> points = [Point(colors[0], lineWidths[0], [])];

  ///点击前进操作
  Future<void>  front() {
      ///移除最后一条
    if (pointsFront.isNotEmpty) {
      Point point = pointsFront.removeLast();
      ///将移除的条目添加到backlist
      points[curFrame].points = point.points;
      points[curFrame].color = selectedColor;
      points[curFrame].strokeWidth = strokeWidth;
      points.add(Point(selectedColor, strokeWidth, []));
      curFrame++;
    }
    setState(() {
      _frontBtn = pointsFront.isNotEmpty;
      _backBtn = points.isNotEmpty;
    });
  }

  ///点击后退操作
  void back() {
    ///删除掉最后一个空Point
    points.removeLast();
    if (points.isEmpty) {
      points.add(Point(selectedColor, strokeWidth, []));
      setState(() {
        _backBtn = points.isNotEmpty;
        _frontBtn = pointsFront.isNotEmpty;
      });
      return;
    }
    ///删除掉倒数第二个有效的Point
    Point point = points.removeLast();
    ///将有效的Point序列添加到Front前进队列
    pointsFront.add(point);
    curFrame--;
    setState(() {
      _backBtn = points.isNotEmpty;
      _frontBtn = pointsFront.isNotEmpty;
      ///添加一条空Point
      points.add(Point(selectedColor, strokeWidth, []));
    });
    print('back curFrame = $curFrame');
  }

  ///重置参数
  void reset() {
    isClear = true;
    curFrame = 0;
    points.clear();
    points.add(Point(selectedColor, strokeWidth, []));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ExtendedCoverImage(
      key: _paintKey,
      image: widget._paintImage,
      points: this.points,
      strokeColor: selectedColor,
      strokeWidth: strokeWidth,
      isClear: isClear,
    );
  }

  void addPoint(ui.Offset localPosition) {
    points[curFrame].points.add(localPosition);
  }
  void addPath(){
    if (points.last.points.length != 0) {
      points.add(Point(selectedColor, strokeWidth, []));
      curFrame++;
    }

    pointsFront.clear();
  }
  ///点击的点转化成相对图片上的点
  Offset pointInImage(int rotation, Offset offset, double containScale) {
    RenderBox renderBox = _paintKey.currentContext.findRenderObject();
    debugPrint(
        "renderbox start:" + renderBox.localToGlobal(Offset.zero).toString());

    ///先将屏幕上的点转成相对容器的点
    double scale = widget._paintImage.width /
        (_paintKey.currentState.getImageInitSize().width * containScale);
    Offset topLeft =
    _paintKey.currentState.getImageRenderOffset(rotation, containScale);
    Offset renderOffset = renderBox.localToGlobal(Offset.zero);

    print("render image start：" + topLeft.toString());
    switch (rotation) {
      case 90:
        offset =
            new Offset(offset.dy - topLeft.dy, topLeft.dx - offset.dx) * scale;
        break;
      case 180:
        offset =
            new Offset(topLeft.dx - offset.dx, topLeft.dy - offset.dy) * scale;
        break;
      case 270:
        offset =
            new Offset(topLeft.dy - offset.dy, offset.dx - topLeft.dx) * scale;
        break;
      default:
        offset =
            new Offset(offset.dx - topLeft.dx, offset.dy - topLeft.dy) * scale;
        break;
    }
    return offset;
  }
  ///保存最终遮盖的图片
  Future<void> saveEndPic(String path) async {
    Paint linePaint = Paint()
      ..color = selectedColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    ImageCoverUtils.paint(
        canvas,
        Size(widget._paintImage.width.toDouble(), widget._paintImage.height.toDouble()),
        widget._paintImage,
        points,
        new Paint(),
        linePaint);

    ui.Image image = await recorder
        .endRecording()
        .toImage(widget._paintImage.width, widget._paintImage.height);

    var pngImageBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File file = File(path);
    bool isExist = await file.exists();
    if (isExist) await file.delete();
    await file.writeAsBytes(pngImageBytes.buffer.asUint8List());
    debugPrint("the last covered img path : ${path}");
  }

  ///异步保存图片
  Future _asyncSavaFile(Map<String, dynamic> data) async {
    return await compute(_saveCropFile, data);
  }
  ///保存图片，被compute调用。
  static Future _saveCropFile(Map<String, dynamic> data) async {
    Uint8List fileData = data["fileData"];
    String path = data["path"];
    final image = img.decodeImage(fileData);
    final imageFile = File(path);
    return await imageFile.writeAsBytes(img.encodePng(image));
  }
}

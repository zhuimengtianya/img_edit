import 'package:flutter/material.dart';
import '../onpan_callback.dart';
import './custom_gesture_detector.dart' as gd;

class ScaleChangedModel {
  double scale;
  Offset offset;

  ScaleChangedModel({this.scale, this.offset});

  @override
  String toString() {
    return 'ScaleChangedModel(scale: $scale, offset:$offset)';
  }
}

class TouchableContainer extends StatefulWidget {
  final Widget child;
  final bool doubleTapStillScale;

  ///用来约束图和坐标轴的
  ///因为坐标轴和图是堆叠起来的，图在坐标轴的内部，需要制定margin，否则放大后图会超出坐标轴
  final EdgeInsets margin;
  ValueChanged<ScaleChangedModel> scaleChanged;
  final OnPanCallback panCallback;
  bool isCover;
  bool _scaleDefault = false;
  int rotation = 0;

  TouchableContainer(
      {Key key,
      this.child,
      this.rotation,
      bool isCover,
      bool scaleDefault = true,
      EdgeInsets margin,
      this.scaleChanged,
      this.doubleTapStillScale,
      OnPanCallback panCallback})
      : this.margin = margin ?? EdgeInsets.all(0),
        this.panCallback = panCallback,
        this.isCover = isCover,
        this._scaleDefault = scaleDefault,
        super(key: key);

  TouchableContainerState createState() => TouchableContainerState();
}

class TouchableContainerState extends State<TouchableContainer>
    with SingleTickerProviderStateMixin {
  GlobalKey _widget_key = GlobalKey();
  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset;
  double _previousScale;
  Offset doubleDownPositon;
  bool isSingleFinger;
  int scaleEndTime = 0;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The maximum offset value is 0,0. If the size of this renderer's box is w,h
  // then the minimum offset value is w - _scale * w, h - _scale * h.
  //也就是最小值是原点0，0，点从最大值到0的区间，也就是这个图可以从最大值移动到原点
  Offset _clampOffset(Offset offset) {
    final Size size = context.size; //容器的大小
    final Offset minOffset =
        new Offset(size.width, size.height) * (1.0 - _scale);
    return new Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  //获取旋转之后的坐标
  Offset pointAfterRotation(Offset offset){
    RenderBox renderBox = _widget_key.currentContext.findRenderObject();
    Offset topLeft = renderBox.localToGlobal(Offset.zero);

    switch (widget.rotation) {
      case 90:
        offset =
            new Offset(offset.dy - topLeft.dy, topLeft.dx - offset.dx) ;
        break;
      case 180:
        offset =
            new Offset(topLeft.dx - offset.dx, topLeft.dy - offset.dy);
        break;
      case 270:
        offset =
            new Offset(topLeft.dy - offset.dy, offset.dx - topLeft.dx);
        break;
    }
    return offset;
  }

  void _handleFlingAnimation() {
    setState(() {
      _offset = _flingAnimation.value;
    });
  }

  void _handleOnScaleStart(gd.ScaleStartDetails details) {
    print("details.focalPoint:" + details.focalPoint.toString());
    widget.panCallback.onPanStart(_scale);
    setState(() {
      _previousScale = _scale;
      Offset focalPoint = pointAfterRotation(details.focalPoint);
      _normalizedOffset = (focalPoint - _offset) / _scale;
      // The fling animation stops if an input gesture starts.
      _controller.stop();
    });
    //两次touch事件时间间隔正常情况下应该大于100毫秒。
    isSingleFinger = DateTime.now().millisecondsSinceEpoch - scaleEndTime > 100;
  }

  void _handleOnScaleUpdate(gd.ScaleUpdateDetails details) {
    //单手指绘制遮挡时，输入手指的位置信息。
    if (details.pointCount < 2 && isSingleFinger && widget.isCover) {
      //widget.panCallback.onPanUpdate(_scale, (pointAfterRotation(details.focalPoint) - _offset) / _scale);
      widget.panCallback.onPanUpdate(_scale, details.focalPoint);
      return;
    } else {
      isSingleFinger = false;
    }
    //缩放、双指拖拽
    widget.panCallback.onScaleUpdate(_scale);
    setState(() {
      if (details.pointCount > 1) {
        _scale = (_previousScale * details.scale).clamp(1.0, double.infinity);
      }
      // Ensure that image location under the focal point stays in the same place despite scaling.
      _offset = _clampOffset(pointAfterRotation(details.focalPoint) - _normalizedOffset * _scale);
    });
    ScaleChangedModel model =
        new ScaleChangedModel(scale: _scale, offset: _offset);
    if (widget.scaleChanged != null) widget.scaleChanged(model);
  }

  void _handleOnScaleEnd(gd.ScaleEndDetails details) {
    if (isSingleFinger) {
      widget.panCallback.onPanEnd();
    }
    scaleEndTime = DateTime.now().millisecondsSinceEpoch;
  }

  void reSetNormal() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Offset getRenderOffset(){
    return _offset;
  }

  double getRenderScale(){
    return _scale;
  }

  @override
  Widget build(BuildContext context) {
    if (widget._scaleDefault) {
      reSetNormal();
    }
    return new gd.GestureDetector(
      onScaleStart: _handleOnScaleStart,
      onScaleUpdate: _handleOnScaleUpdate,
      onScaleEnd: _handleOnScaleEnd,
      child: Container(
        margin: widget.margin,
        constraints: const BoxConstraints(
          minWidth: double.maxFinite,
          minHeight: double.infinity,
        ),
        child: RotatedBox(
          quarterTurns:  widget.rotation ~/ 90,
          child: new Transform(
              key: _widget_key,
              transform: new Matrix4.identity()
                ..translate(_offset.dx, _offset.dy)
                ..scale(_scale, _scale, 1.0),
              child: widget.child),
        ),
      ),
    );
  }
}

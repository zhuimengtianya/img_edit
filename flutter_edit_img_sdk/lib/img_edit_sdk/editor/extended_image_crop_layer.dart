import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/extended_image_utils.dart';

import 'extended_image_editor_utils.dart';
import 'extended_image_editor_utils.dart';

///
///  create by zhoumaotuo on 2019/8/22
///

enum _moveType {
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
  top,
  right,
  bottom,
  left
}

class ExtendedImageCropLayer extends StatefulWidget {
  const ExtendedImageCropLayer(
      {this.editActionDetails,
      this.layoutRect,
      this.editorConfig,
      Key key,
      this.fit})
      : super(key: key);

  final EditActionDetails editActionDetails;
  final EditorConfig editorConfig;
  final Rect layoutRect;
  final BoxFit fit;
  @override
  ExtendedImageCropLayerState createState() => ExtendedImageCropLayerState();
}

class ExtendedImageCropLayerState extends State<ExtendedImageCropLayer>
    with SingleTickerProviderStateMixin {
  Rect get layoutRect => widget.layoutRect;

  Rect get cropRect => widget.editActionDetails.cropRect;
  EdgeInsets get cropRectPadding => widget.editActionDetails.cropRectPadding;

  //set cropRect(Rect value) => widget.editActionDetails.cropRect = value;
  List<Offset> get cropPoints => widget.editActionDetails.cropPoints;

  bool get isAnimating => _rectTweenController?.isAnimating ?? false;
  bool get isMoving => _currentMoveType != null;

  Timer _timer;
  bool _pointerDown = false;
  Tween<Rect> _rectTween;
  Animation<Rect> _rectAnimation;
  AnimationController _rectTweenController;
  _moveType _currentMoveType;
  @override
  void initState() {
    _pointerDown = false;
    _rectTweenController = AnimationController(
        vsync: this, duration: widget.editorConfig.animationDuration)
      ..addListener(_doCropAutoCenterAnimation);
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rectTweenController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExtendedImageCropLayer oldWidget) {
    if (widget.editorConfig.animationDuration !=
        oldWidget.editorConfig.animationDuration) {
      _rectTweenController?.stop();
      _rectTweenController?.dispose();
      _rectTweenController = AnimationController(
          vsync: this, duration: widget.editorConfig.animationDuration)
        ..addListener(_doCropAutoCenterAnimation);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (cropRect == null) {
      return Container();
    }
    final EditorConfig editConfig = widget.editorConfig;
    final Color cornerColor =
        widget.editorConfig.cornerColor ?? Theme.of(context).primaryColor;
    final Color maskColor = widget.editorConfig.editorMaskColorHandler
            ?.call(context, _pointerDown) ??
        defaultEditorMaskColorHandler(context, _pointerDown);
    final double gWidth = widget.editorConfig.hitTestSize;

    final Widget result = CustomPaint(
      painter: ExtendedImageCropLayerPainter(
          cropPoints: cropPoints,
          cornerColor: cornerColor,
          cornerSize: editConfig.cornerSize,
          lineColor: editConfig.lineColor ??
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
          lineHeight: editConfig.lineHeight,
          maskColor: maskColor,
          pointerDown: _pointerDown),
      child: Stack(
        children: <Widget>[
          //top left
          Positioned(
            top: cropPoints[EditActionDetails.TOP_LEFT].dy - gWidth,
            left: cropPoints[EditActionDetails.TOP_LEFT].dx - gWidth,
            child: Container(
              height: gWidth * 2,
              width: gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.topLeft, details.delta);
                },
                onPanEnd: (_) {
                  _moveEnd(_moveType.topLeft);
                },
              ),
            ),
          ),
          //top right
          Positioned(
            top: cropPoints[EditActionDetails.TOP_RIGHT].dy - gWidth,
            left: cropPoints[EditActionDetails.TOP_RIGHT].dx - gWidth,
            child: Container(
              height: gWidth * 2,
              width: gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.topRight, details.delta);
                },
                onPanEnd: (_) {
                  _moveEnd(_moveType.topRight);
                },
              ),
            ),
          ),
          //bottom left
          Positioned(
            top: cropPoints[EditActionDetails.BOTTOM_LEFT].dy - gWidth,
            left: cropPoints[EditActionDetails.BOTTOM_LEFT].dx - gWidth,
            child: Container(
              height: gWidth * 2,
              width: gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.bottomLeft, details.delta);
                },
                onPanEnd: (_) {
                  _moveEnd(_moveType.bottomLeft);
                },
              ),
            ),
          ),
          // bottom right
          Positioned(
            top: cropPoints[EditActionDetails.BOTTOM_RIGHT].dy - gWidth,
            left: cropPoints[EditActionDetails.BOTTOM_RIGHT].dx - gWidth,
            child: Container(
              height: gWidth * 2,
              width: gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.bottomRight, details.delta);
                },
                onPanEnd: (_) {
                  _moveEnd(_moveType.bottomRight);
                },
              ),
            ),
          ),
          // top
          Positioned(
            top: (cropPoints[EditActionDetails.TOP_LEFT].dy +
                cropPoints[EditActionDetails.TOP_RIGHT].dy) / 2 - gWidth,
            left: (cropPoints[EditActionDetails.TOP_LEFT].dx +
                cropPoints[EditActionDetails.TOP_RIGHT].dx) / 2 - gWidth,
            child: Container(
              height: gWidth * 2,
              width: gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.top, details.delta);
                },
                onVerticalDragEnd: (_) {
                  _moveEnd(_moveType.top);
                },
              ),
            ),
          ),
          //left
          Positioned(
            top: (cropPoints[EditActionDetails.TOP_LEFT].dy +
                cropPoints[EditActionDetails.BOTTOM_LEFT].dy) / 2 - gWidth,
            left: (cropPoints[EditActionDetails.TOP_LEFT].dx +
                cropPoints[EditActionDetails.BOTTOM_LEFT].dx) / 2 - gWidth,
            child: Container(
              height: gWidth * 2,
              width:  gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.left, details.delta);
                },
                onHorizontalDragEnd: (_) {
                  _moveEnd(_moveType.left);
                },
              ),
            ),
          ),
          //bottom
          Positioned(
            top: (cropPoints[EditActionDetails.BOTTOM_LEFT].dy +
                cropPoints[EditActionDetails.BOTTOM_RIGHT].dy) / 2 - gWidth,
            left: (cropPoints[EditActionDetails.BOTTOM_LEFT].dx +
                cropPoints[EditActionDetails.BOTTOM_RIGHT].dx) / 2 - gWidth,
            child: Container(
              height: gWidth * 2,
              width: gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.bottom, details.delta);
                },
                onVerticalDragEnd: (_) {
                  _moveEnd(_moveType.bottom);
                },
              ),
            ),
          ),
          //right
          Positioned(
            top: (cropPoints[EditActionDetails.TOP_RIGHT].dy +
                cropPoints[EditActionDetails.BOTTOM_RIGHT].dy) / 2 - gWidth,
            left: (cropPoints[EditActionDetails.TOP_RIGHT].dx +
                cropPoints[EditActionDetails.BOTTOM_RIGHT].dx) / 2 - gWidth,
            child: Container(
              height: gWidth * 2,
              width: gWidth * 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  moveUpdate(_moveType.right, details.delta);
                },
                onHorizontalDragEnd: (_) {
                  _moveEnd(_moveType.right);
                },
              ),
            ),
          ),
        ],
      ),
    );
    return result;
  }

  void pointerDown(bool down) {
    if (mounted && _pointerDown != down) {
      setState(() {
        _pointerDown = down;
      });
    }
  }

  void moveUpdate(_moveType moveType, Offset delta) {
    if (isAnimating) {
      return;
    }
    ///only move by one type at the same time
    if (_currentMoveType != null && moveType != _currentMoveType) {
      return;
    }
    _currentMoveType = moveType;
    print(moveType);

    bool bUpdate = false;
    final Rect layerDestinationRect =
        widget.editActionDetails.layerDestinationRect;
    final List<Offset> cropPoints = widget.editActionDetails.cropPoints;

    switch (moveType) {
      case _moveType.topLeft:
        Offset topLeft = movePoint(cropPoints[EditActionDetails.TOP_LEFT],moveType,delta);
        if (canMoveTopLeft(topLeft)) {
          cropPoints[EditActionDetails.TOP_LEFT] = topLeft;
          bUpdate = true;
        }
        break;
      case _moveType.topRight:
        Offset topRight = movePoint(cropPoints[EditActionDetails.TOP_RIGHT],moveType,delta);
        if (canMoveTopRight(topRight)) {
          cropPoints[EditActionDetails.TOP_RIGHT] = topRight;
          bUpdate = true;
        }
        break;
      case _moveType.bottomRight:
        Offset bottomRight = movePoint(cropPoints[EditActionDetails.BOTTOM_RIGHT],moveType,delta);
        if (canMoveBottomRight(bottomRight)) {
          cropPoints[EditActionDetails.BOTTOM_RIGHT] = bottomRight;
          bUpdate = true;
        }
        break;
      case _moveType.bottomLeft:
        Offset bottomLeft = movePoint(cropPoints[EditActionDetails.BOTTOM_LEFT],moveType,delta);
        if (canMoveBottomLeft(bottomLeft)) {
          cropPoints[EditActionDetails.BOTTOM_LEFT] = bottomLeft;
          bUpdate = true;
        }
        break;
      case _moveType.top:
        delta = new Offset(0, delta.dy);
        Offset topLeft = movePoint(cropPoints[EditActionDetails.TOP_LEFT],_moveType.topLeft,delta);
        Offset topRight =  movePoint(cropPoints[EditActionDetails.TOP_RIGHT],_moveType.topRight,delta);
        if (canMoveTopLeft(topLeft) && canMoveTopRight(topRight)) {
          cropPoints[EditActionDetails.TOP_LEFT] = topLeft;
          cropPoints[EditActionDetails.TOP_RIGHT] = topRight;
          bUpdate = true;
        }
        break;
      case _moveType.bottom:
        delta = new Offset(0, delta.dy);
        Offset bottomLeft = movePoint(cropPoints[EditActionDetails.BOTTOM_LEFT],_moveType.bottomLeft,delta);
        Offset bottomRight =  movePoint(cropPoints[EditActionDetails.BOTTOM_RIGHT],_moveType.bottomRight,delta);
        if (canMoveBottomLeft(bottomLeft) && canMoveBottomRight(bottomRight)) {
          cropPoints[EditActionDetails.BOTTOM_LEFT] = bottomLeft;
          cropPoints[EditActionDetails.BOTTOM_RIGHT] = bottomRight;
          bUpdate = true;
        }
        break;
      case _moveType.left:
        delta = new Offset(delta.dx , 0);
        Offset topLeft = movePoint(cropPoints[EditActionDetails.TOP_LEFT],_moveType.topLeft,delta);
        Offset bottomLeft =  movePoint(cropPoints[EditActionDetails.BOTTOM_LEFT],_moveType.bottomLeft,delta);
        if (canMoveTopLeft(topLeft) && canMoveBottomLeft(bottomLeft)) {
          cropPoints[EditActionDetails.TOP_LEFT] = topLeft;
          cropPoints[EditActionDetails.BOTTOM_LEFT] = bottomLeft;
          bUpdate = true;
        }
        break;
      case _moveType.right:
        delta = new Offset(delta.dx , 0);
        Offset topRight = movePoint(cropPoints[EditActionDetails.TOP_RIGHT],_moveType.topRight,delta);
        Offset bottomRight =  movePoint(cropPoints[EditActionDetails.BOTTOM_RIGHT],_moveType.bottomRight,delta);
        if (canMoveTopRight(topRight) && canMoveBottomRight(bottomRight)) {
          cropPoints[EditActionDetails.TOP_RIGHT] = topRight;
          cropPoints[EditActionDetails.BOTTOM_RIGHT] = bottomRight;
          bUpdate = true;
        }
        break;
      default:
    }

    if (bUpdate && mounted) {
      setState(() {
        widget.editActionDetails.cropPoints = cropPoints;
      });
    }
  }

  /**
   * 移动多边形四个点保证点在图片内。
   */
  Offset movePoint(Offset point, _moveType type, Offset delta) {
    final Rect layerDestinationRect =
        widget.editActionDetails.layerDestinationRect;
    final Rect layoutRect = widget.layoutRect;
    final Rect validRect = Rect.fromLTRB(max(layoutRect.left,layerDestinationRect.left), max(layoutRect.top,layerDestinationRect.top)
        , min(layoutRect.right,layerDestinationRect.right), min(layoutRect.bottom,layerDestinationRect.bottom));
    point = point + delta;
    switch (type) {
      case _moveType.topLeft:
        point = Offset(max(point.dx, validRect.left),
            max(point.dy, validRect.top));
        break;
      case _moveType.topRight:
        point = Offset(min(point.dx, validRect.right),
            max(point.dy, validRect.top));
        break;
      case _moveType.bottomLeft:
        point = Offset(max(point.dx, validRect.left),
            min(point.dy, validRect.bottom));
        break;
      case _moveType.bottomRight:
        point = Offset(min(point.dx, validRect.right),
            min(point.dy, validRect.bottom));
        break;
    }
    return point;
  }

  /**
   * 判断point在p1和p2连线的哪一侧
   */
  double pointSideLine(Offset p1, Offset p2, Offset point) {
    return (point.dx - p1.dx) * (p2.dy - p1.dy) -
        (point.dy - p1.dy) * (p2.dx - p1.dx);
  }

  bool canMoveTopLeft(Offset point) {
    if (pointSideLine(cropPoints[EditActionDetails.TOP_RIGHT],
        cropPoints[EditActionDetails.BOTTOM_LEFT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_LEFT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT]) >
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.TOP_RIGHT],
        cropPoints[EditActionDetails.BOTTOM_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_LEFT]) <
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.BOTTOM_LEFT],
        cropPoints[EditActionDetails.BOTTOM_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.BOTTOM_LEFT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT],
            cropPoints[EditActionDetails.TOP_RIGHT]) <
        0) {
      return false;
    }
    //判断是否超过了图片的区域
    return true;
  }

  bool canMoveTopRight(Offset point) {
    if (pointSideLine(cropPoints[EditActionDetails.TOP_LEFT],
        cropPoints[EditActionDetails.BOTTOM_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_LEFT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_LEFT]) >
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.TOP_LEFT],
        cropPoints[EditActionDetails.BOTTOM_LEFT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_LEFT],
            cropPoints[EditActionDetails.BOTTOM_LEFT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT]) <
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.BOTTOM_LEFT],
        cropPoints[EditActionDetails.BOTTOM_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.BOTTOM_LEFT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT],
            cropPoints[EditActionDetails.TOP_LEFT]) <
        0) {
      return false;
    }
    return true;
  }

  bool canMoveBottomRight(Offset point) {
    if (pointSideLine(cropPoints[EditActionDetails.TOP_RIGHT],
        cropPoints[EditActionDetails.BOTTOM_LEFT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_LEFT],
            cropPoints[EditActionDetails.TOP_LEFT]) >
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.TOP_LEFT],
        cropPoints[EditActionDetails.TOP_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_LEFT],
            cropPoints[EditActionDetails.TOP_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_LEFT]) <
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.TOP_LEFT],
        cropPoints[EditActionDetails.BOTTOM_LEFT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_LEFT],
            cropPoints[EditActionDetails.BOTTOM_LEFT],
            cropPoints[EditActionDetails.TOP_RIGHT]) <
        0) {
      return false;
    }
    return true;
  }

  bool canMoveBottomLeft(Offset point) {
    if (pointSideLine(cropPoints[EditActionDetails.TOP_LEFT],
        cropPoints[EditActionDetails.BOTTOM_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_LEFT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT],
            cropPoints[EditActionDetails.TOP_RIGHT]) >
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.TOP_LEFT],
        cropPoints[EditActionDetails.TOP_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_LEFT],
            cropPoints[EditActionDetails.TOP_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT]) <
        0) {
      return false;
    }
    if (pointSideLine(cropPoints[EditActionDetails.TOP_RIGHT],
        cropPoints[EditActionDetails.BOTTOM_RIGHT], point) *
        pointSideLine(
            cropPoints[EditActionDetails.TOP_RIGHT],
            cropPoints[EditActionDetails.BOTTOM_RIGHT],
            cropPoints[EditActionDetails.TOP_LEFT]) <
        0) {
      return false;
    }
    return true;
  }

  /// handle crop rect with aspectRatio
  Rect _handleAspectRatio(double gWidth, _moveType moveType, Rect result,
      Rect layerDestinationRect, Offset delta) {
    final double aspectRatio = widget.editActionDetails.cropAspectRatio;
    // do with aspect ratio
    if (aspectRatio != null) {
      final double minD = gWidth * 2;
      switch (moveType) {
        case _moveType.top:
        case _moveType.bottom:
          final bool isTop = moveType == _moveType.top;
          result = _doAspectRatioV(
              minD, result, aspectRatio, layerDestinationRect,
              isTop: isTop);
          break;
        case _moveType.left:
        case _moveType.right:
          final bool isLeft = moveType == _moveType.left;
          result = _doAspectRatioH(
              minD, result, aspectRatio, layerDestinationRect,
              isLeft: isLeft);
          break;
        case _moveType.topLeft:
        case _moveType.topRight:
        case _moveType.bottomRight:
        case _moveType.bottomLeft:
          final double dx = delta.dx.abs();
          final double dy = delta.dy.abs();
          double width = result.width;
          double height = result.height;
          if (doubleCompare(dx, dy) >= 0) {
            height = max(minD,
                min(result.width / aspectRatio, layerDestinationRect.height));
            width = height * aspectRatio;
          } else {
            width = max(minD,
                min(result.height * aspectRatio, layerDestinationRect.width));
            height = width / aspectRatio;
          }
          double top = result.top;
          double left = result.left;
          switch (moveType) {
            case _moveType.topLeft:
              top = result.bottom - height;
              left = result.right - width;
              break;
            case _moveType.topRight:
              top = result.bottom - height;
              left = result.left;
              break;
            case _moveType.bottomRight:
              top = result.top;
              left = result.left;
              break;
            case _moveType.bottomLeft:
              top = result.top;
              left = result.right - width;
              break;
            default:
          }
          result = Rect.fromLTWH(left, top, width, height);
          break;
        default:
      }
    }
    return result;
  }

  ///horizontal
  Rect _doAspectRatioH(
      double minD, Rect result, double aspectRatio, Rect layerDestinationRect,
      {bool isLeft}) {
    final double height =
        max(minD, min(result.width / aspectRatio, layerDestinationRect.height));
    final double width = height * aspectRatio;
    final double left = isLeft ? result.right - width : result.left;
    final double top = result.centerRight.dy - height / 2.0;
    result = Rect.fromLTWH(left, top, width, height);
    return result;
  }

  ///vertical
  Rect _doAspectRatioV(
      double minD, Rect result, double aspectRatio, Rect layerDestinationRect,
      {bool isTop}) {
    final double width =
        max(minD, min(result.height * aspectRatio, layerDestinationRect.width));
    final double height = width / aspectRatio;
    final double top = isTop ? result.bottom - height : result.top;
    final double left = result.topCenter.dx - width / 2.0;
    result = Rect.fromLTWH(left, top, width, height);
    return result;
  }

  Rect _doWithMaxScale(Rect rect) {
    final Rect centerCropRect = getDestinationRect(
        rect: layoutRect, inputSize: rect.size, fit: widget.fit);
    final Rect newScreenCropRect =
        centerCropRect.shift(widget.editActionDetails.layoutTopLeft);

    final Rect oldScreenCropRect = widget.editActionDetails.screenCropRect;

    final double scale = newScreenCropRect.width / oldScreenCropRect.width;

    final double totalScale = widget.editActionDetails.totalScale * scale;
    if (doubleCompare(totalScale, widget.editorConfig.maxScale) > 0) {
      if (doubleCompare(rect.width, cropRect.width) > 0 ||
          doubleCompare(rect.height, cropRect.height) > 0) {
        return rect;
      }
      return null;
    }

    return rect;
  }

  void _moveEnd(_moveType moveType) {
    if (_currentMoveType != null && moveType == _currentMoveType) {
      _currentMoveType = null;
      //if (widget.editorConfig.autoCenter)
//      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (isAnimating) {
      return;
    }
    _timer = Timer.periodic(widget.editorConfig.tickerDuration, (Timer timer) {
      _timer?.cancel();

      //move to center
      final Rect oldScreenCropRect = widget.editActionDetails.screenCropRect;

      final Rect centerCropRect = getDestinationRect(
          rect: layoutRect, inputSize: cropRect.size, fit: widget.fit);
      final Rect newScreenCropRect =
          centerCropRect.shift(widget.editActionDetails.layoutTopLeft);

      _rectTween = RectTween(begin: oldScreenCropRect, end: newScreenCropRect);
      _rectAnimation = _rectTweenController?.drive(_rectTween);
      _rectTweenController?.reset();
      _rectTweenController?.forward();
    });
  }

  void _doCropAutoCenterAnimation({Rect newScreenCropRect}) {
    if (mounted) {
      setState(() {
        final Rect oldScreenCropRect = widget.editActionDetails.screenCropRect;
        final Rect oldScreenDestinationRect =
            widget.editActionDetails.screenDestinationRect;

        newScreenCropRect ??= _rectAnimation.value;

        final double scale = newScreenCropRect.width / oldScreenCropRect.width;

        final Offset offset =
            newScreenCropRect.center - oldScreenCropRect.center;

        /// scale then move
        /// so we do scale first, get the new center
        /// then move to new offset
        final Offset newImageCenter = oldScreenCropRect.center +
            (oldScreenDestinationRect.center - oldScreenCropRect.center) *
                scale;
        final Rect newScreenDestinationRect = Rect.fromCenter(
          center: newImageCenter + offset,
          width: oldScreenDestinationRect.width * scale,
          height: oldScreenDestinationRect.height * scale,
        );

        // var totalScale = newScreenDestinationRect.width /
        //     (widget.editActionDetails.rawDestinationRect.width *
        //     widget.editorConfig.initialScale);
        final double totalScale = widget.editActionDetails.totalScale * scale;

        //todo cropRect = newScreenCropRect.shift(-widget.editActionDetails.layoutTopLeft);

        widget.editActionDetails
            .setScreenDestinationRect(newScreenDestinationRect);
        widget.editActionDetails.totalScale = totalScale;
        widget.editActionDetails.preTotalScale = totalScale;
      });
    }
  }
}

class ExtendedImageCropLayerPainter extends CustomPainter {
  ExtendedImageCropLayerPainter(
      {@required this.cropPoints,
      this.lineColor,
      this.cornerColor,
      this.cornerSize,
      this.lineHeight,
      this.maskColor,
      this.pointerDown});

  List<Offset> cropPoints = [];

  //size of corner shape
  final Size cornerSize;

  //color of corner shape
  //default theme primaryColor
  final Color cornerColor;

  // color of crop line
  final Color lineColor;

  //height of crop line
  final double lineHeight;

  //color of mask
  final Color maskColor;

  //whether pointer is down
  final bool pointerDown;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect cropRect = Rect.fromLTRB(
        min(cropPoints[EditActionDetails.TOP_LEFT].dx, cropPoints[EditActionDetails.BOTTOM_LEFT].dx),
        min(cropPoints[EditActionDetails.TOP_LEFT].dy, cropPoints[EditActionDetails.TOP_RIGHT].dy),
        max(cropPoints[EditActionDetails.TOP_RIGHT].dx, cropPoints[EditActionDetails.BOTTOM_RIGHT].dx),
        max(cropPoints[EditActionDetails.BOTTOM_LEFT].dy, cropPoints[EditActionDetails.BOTTOM_RIGHT].dy));
    final Paint linePainter = Paint()
      ..color = lineColor
      ..strokeWidth = lineHeight
      ..style = PaintingStyle.stroke;

    // canvas.saveLayer(rect, Paint());
    // canvas.drawRect(
    //     rect,
    //     Paint()
    //       ..style = PaintingStyle.fill
    //       ..color = maskColor);
    //   canvas.drawRect(cropRect, Paint()..blendMode = BlendMode.clear);
    // canvas.restore();

    // draw mask rect instead use BlendMode.clear, web doesn't support now.
    //left
    canvas.drawRect(
        Offset.zero & Size(cropRect.left, rect.height),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.transparent);
    //top
    canvas.drawRect(
        Offset(cropRect.left, 0.0) & Size(cropRect.width, cropRect.top),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.transparent);
    //right
    canvas.drawRect(
        Offset(cropRect.right, 0.0) &
            Size(rect.width - cropRect.right, rect.height),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.transparent);
    //bottom
    canvas.drawRect(
        Offset(cropRect.left, cropRect.bottom) &
            Size(cropRect.width, rect.height - cropRect.bottom),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.transparent);

    /*canvas.drawRect(cropRect, linePainter);

    if (pointerDown) {
      canvas.drawLine(
          Offset((cropRect.right - cropRect.left) / 3.0 + cropRect.left,
              cropRect.top),
          Offset((cropRect.right - cropRect.left) / 3.0 + cropRect.left,
              cropRect.bottom),
          linePainter);

      canvas.drawLine(
          Offset((cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left,
              cropRect.top),
          Offset((cropRect.right - cropRect.left) / 3.0 * 2.0 + cropRect.left,
              cropRect.bottom),
          linePainter);

      canvas.drawLine(
          Offset(
            cropRect.left,
            (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top,
          ),
          Offset(
            cropRect.right,
            (cropRect.bottom - cropRect.top) / 3.0 + cropRect.top,
          ),
          linePainter);

      canvas.drawLine(
          Offset(cropRect.left,
              (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top),
          Offset(
            cropRect.right,
            (cropRect.bottom - cropRect.top) / 3.0 * 2.0 + cropRect.top,
          ),
          linePainter);
    }*/

    final Paint cornerPainter = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.fill;

    double cornerWidth = cornerSize.width;
    double cornerHeight = cornerSize.height;

    //连线
    canvas.drawLine(cropPoints[EditActionDetails.TOP_LEFT],
        cropPoints[EditActionDetails.TOP_RIGHT], linePainter);
    canvas.drawLine(cropPoints[EditActionDetails.TOP_RIGHT],
        cropPoints[EditActionDetails.BOTTOM_RIGHT], linePainter);
    canvas.drawLine(cropPoints[EditActionDetails.BOTTOM_RIGHT],
        cropPoints[EditActionDetails.BOTTOM_LEFT], linePainter);
    canvas.drawLine(cropPoints[EditActionDetails.BOTTOM_LEFT],
        cropPoints[EditActionDetails.TOP_LEFT], linePainter);

    //绘制四个角
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.TOP_LEFT].dx,
            cropPoints[EditActionDetails.TOP_LEFT].dy,
            cornerWidth,
            cornerHeight),
        cornerPainter);
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.TOP_LEFT].dx,
            cropPoints[EditActionDetails.TOP_LEFT].dy,
            cornerHeight,
            cornerWidth),
        cornerPainter);

    //top-right
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.TOP_RIGHT].dx - cornerWidth,
            cropPoints[EditActionDetails.TOP_RIGHT].dy,
            cornerWidth,
            cornerHeight),
        cornerPainter);
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.TOP_RIGHT].dx - cornerHeight,
            cropPoints[EditActionDetails.TOP_RIGHT].dy,
            cornerHeight,
            cornerWidth),
        cornerPainter);

    //bottom-left
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.BOTTOM_LEFT].dx,
            cropPoints[EditActionDetails.BOTTOM_LEFT].dy - cornerHeight,
            cornerWidth,
            cornerHeight),
        cornerPainter);
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.BOTTOM_LEFT].dx,
            cropPoints[EditActionDetails.BOTTOM_LEFT].dy - cornerWidth,
            cornerHeight,
            cornerWidth),
        cornerPainter);


    //bottom-right
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.BOTTOM_RIGHT].dx - cornerWidth,
            cropPoints[EditActionDetails.BOTTOM_RIGHT].dy - cornerHeight,
            cornerWidth,
            cornerHeight),
        cornerPainter);
    canvas.drawRect(
        Rect.fromLTWH(
            cropPoints[EditActionDetails.BOTTOM_RIGHT].dx - cornerHeight,
            cropPoints[EditActionDetails.BOTTOM_RIGHT].dy - cornerWidth,
            cornerHeight,
            cornerWidth),
        cornerPainter);

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate.runtimeType != runtimeType) {
      return true;
    }
    final ExtendedImageCropLayerPainter delegate =
        oldDelegate as ExtendedImageCropLayerPainter;
    return cropPoints != delegate.cropPoints ||
        cornerSize != delegate.cornerSize ||
        lineColor != delegate.lineColor ||
        lineHeight != delegate.lineHeight ||
        maskColor != delegate.maskColor ||
        cornerColor != delegate.cornerColor ||
        pointerDown != delegate.pointerDown;
  }
}

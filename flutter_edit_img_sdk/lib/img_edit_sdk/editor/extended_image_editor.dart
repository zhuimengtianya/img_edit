import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:extended_image_library/extended_image_library.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/image/extended_raw_image.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/extended_image_utils.dart';

import '../extended_image.dart';
import '../global_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'extended_image_crop_layer.dart';
import 'extended_image_editor_utils.dart';
//import 'package:flutter_img_sdk/img_edit_sdk/utils/extended_image_utils.dart';
//import 'package:extended_image_library/extended_image_library.dart';
//import 'package:flutter_img_sdk/img_edit_sdk/image/extended_raw_image.dart';

///
///  create by zmtzawqlp on 2019/8/22
///

class ExtendedImageEditor extends StatefulWidget {
  ExtendedImageEditor({this.extendedImageState, Key key})
      : assert(extendedImageState.imageWidget.fit == BoxFit.contain,
            'Make sure the image is all painted to crop,the fit of image must be BoxFit.contain'),
        assert(extendedImageState.imageWidget.image is ExtendedImageProvider,
            'Make sure the image provider is ExtendedImageProvider, we will get raw image data from it'),
        super(key: key);
  final ExtendedImageState extendedImageState;

  @override
  ExtendedImageEditorState createState() => ExtendedImageEditorState();
}

class ExtendedImageEditorState extends State<ExtendedImageEditor> {
  EditActionDetails _editActionDetails;
  EditorConfig _editorConfig;
  double _startingScale;
  Offset _startingOffset;
  final GlobalKey<ExtendedImageCropLayerState> _layerKey =
      GlobalKey<ExtendedImageCropLayerState>();

  @override
  void initState() {
    _initGestureConfig();

    super.initState();
  }

  void _initGestureConfig() {
    final double initialScale = _editorConfig?.initialScale;
    final double cropAspectRatio = _editorConfig?.cropAspectRatio;
    _editorConfig = widget
            ?.extendedImageState?.imageWidget?.initEditorConfigHandler
            ?.call(widget.extendedImageState) ??
        EditorConfig();
    if (cropAspectRatio != _editorConfig.cropAspectRatio) {
      _editActionDetails = null;
    }

    if (_editActionDetails == null ||
        initialScale != _editorConfig.initialScale) {
      _editActionDetails = EditActionDetails()
        ..delta = Offset.zero
        ..totalScale = _editorConfig.initialScale
        ..preTotalScale = _editorConfig.initialScale
        ..cropRectPadding = _editorConfig.cropRectPadding;
    }

    if (widget.extendedImageState?.extendedImageInfo?.image != null) {
      _editActionDetails.originalAspectRatio =
          widget.extendedImageState.extendedImageInfo.image.width /
              widget.extendedImageState.extendedImageInfo.image.height;
    }
    _editActionDetails.cropAspectRatio = _editorConfig.cropAspectRatio;
    if (_editorConfig.cropAspectRatio != null &&
        _editorConfig.cropAspectRatio <= 0) {
      _editActionDetails.cropAspectRatio =
          _editActionDetails.originalAspectRatio;
    }
  }

  @override
  void didUpdateWidget(ExtendedImageEditor oldWidget) {
    _initGestureConfig();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final ExtendedImage extendedImage = widget.extendedImageState.imageWidget;
    final Widget image = ExtendedRawImage(
      image: widget.extendedImageState.extendedImageInfo?.image,
      width: extendedImage.width,
      height: extendedImage.height,
      scale: widget.extendedImageState.extendedImageInfo?.scale ?? 1.0,
      color: extendedImage.color,
      colorBlendMode: extendedImage.colorBlendMode,
      fit: extendedImage.fit,
      alignment: extendedImage.alignment,
      repeat: extendedImage.repeat,
      centerSlice: extendedImage.centerSlice,
      //matchTextDirection: extendedImage.matchTextDirection,
      //don't support TextDirection for editor
      matchTextDirection: false,
      invertColors: widget.extendedImageState.invertColors,
      filterQuality: extendedImage.filterQuality,
      editActionDetails: _editActionDetails,
    );

    Widget result = Stack(
          overflow: Overflow.clip,
          children: <Widget>[
            Positioned(
              child: image,
              top: 0.0,
              left: 0.0,
              bottom: 0.0,
              right: 0.0,
            ),
            Positioned(
              child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                Rect layoutRect = Offset.zero &
                    Size(constraints.maxWidth, constraints.maxHeight);
                final EdgeInsets padding = _editorConfig.cropRectPadding;
                if (padding != null) {
                  layoutRect = padding.deflateRect(layoutRect);
                }
                if (_editActionDetails.cropPoints.length == 0) {
                  //当前剪裁区域未初始化
                  initCropRect(layoutRect);
                }

                return ExtendedImageCropLayer(
                  key: _layerKey,
                  layoutRect: layoutRect,
                  editActionDetails: _editActionDetails,
                  editorConfig: _editorConfig,
                  fit: widget.extendedImageState.imageWidget.fit,
                );
              }),
              top: 0.0,
              left: 0.0,
              bottom: 0.0,
              right: 0.0,
            ),
          ],
        );
    /*result = Listener(
      child: result,
      onPointerDown: (_) {
        _layerKey.currentState.pointerDown(true);
      },
      onPointerUp: (_) {
        _layerKey.currentState.pointerDown(false);
      },
      // onPointerCancel: (_) {
      //   pointerDown(false);
      // },
    );*/
    return result;
  }

  void initCropRect(Rect layoutRect) {
    final Rect destinationRect = getDestinationRect(
        rect: layoutRect,
        inputSize: Size(
            widget.extendedImageState.extendedImageInfo.image.width
                .toDouble(),
            widget.extendedImageState.extendedImageInfo.image.height
                .toDouble()),
        flipHorizontally: false,
        fit: widget.extendedImageState.imageWidget.fit,
        centerSlice: widget.extendedImageState.imageWidget.centerSlice,
        alignment: widget.extendedImageState.imageWidget.alignment,
        scale: widget.extendedImageState.extendedImageInfo.scale);

    if(GlobalVariables.smartCropPoints != null && GlobalVariables.smartCropPoints.length == 4){
      initSmartCrop(destinationRect);
    }else {
      Rect cropRect = initCropRatio(destinationRect);
      if (_editorConfig.initCropRectType == InitCropRectType.layoutRect &&
          _editorConfig.cropAspectRatio != null &&
          _editorConfig.cropAspectRatio > 0) {
        final Rect rect = initCropRatio(layoutRect);
        _editActionDetails.totalScale = _editActionDetails.preTotalScale =
        doubleCompare(destinationRect.width, destinationRect.height) > 0
            ? rect.height / cropRect.height
            : rect.width / cropRect.width;
        cropRect = rect;
      }
      //_editActionDetails.cropRect = cropRect;
      _editActionDetails.cropPoints
          .add(new Offset(cropRect.topLeft.dx, cropRect.topLeft.dy));
      _editActionDetails.cropPoints
          .add(new Offset(cropRect.topRight.dx, cropRect.topRight.dy));
      _editActionDetails.cropPoints
          .add(new Offset(cropRect.bottomLeft.dx, cropRect.bottomLeft.dy));
      _editActionDetails.cropPoints
          .add(new Offset(cropRect.bottomRight.dx, cropRect.bottomRight.dy));
    }
    print(" _editActionDetails.cropPoints:" +  _editActionDetails.cropPoints.toString());
  }

  void initSmartCrop(Rect destinationRect){
    if(GlobalVariables.smartCropPoints == null){
      return;
    }
    int imageWidth = widget.extendedImageState.extendedImageInfo.image.width;
    int imageHeight = widget.extendedImageState.extendedImageInfo.image.height;

    double ratio_x =  destinationRect.width / imageWidth;
    double ratio_y = destinationRect.height / imageHeight;

    print("destinationRect:" + destinationRect.toString());
    _editActionDetails.cropPoints.add(destinationRect.topLeft + new Offset(GlobalVariables.smartCropPoints[EditActionDetails.TOP_LEFT].dx * ratio_x ,
        GlobalVariables.smartCropPoints[EditActionDetails.TOP_LEFT].dy * ratio_y));
    _editActionDetails.cropPoints.add(destinationRect.topLeft + new Offset(GlobalVariables.smartCropPoints[EditActionDetails.TOP_RIGHT].dx * ratio_x ,
        GlobalVariables.smartCropPoints[EditActionDetails.TOP_RIGHT].dy * ratio_y));
    _editActionDetails.cropPoints.add(destinationRect.topLeft + new Offset(GlobalVariables.smartCropPoints[EditActionDetails.BOTTOM_LEFT].dx * ratio_x ,
        GlobalVariables.smartCropPoints[EditActionDetails.BOTTOM_RIGHT].dy * ratio_y));
    _editActionDetails.cropPoints.add(destinationRect.topLeft + new Offset(GlobalVariables.smartCropPoints[EditActionDetails.BOTTOM_RIGHT].dx * ratio_x ,
        GlobalVariables.smartCropPoints[EditActionDetails.BOTTOM_RIGHT].dy * ratio_y));
  }

  Rect initCropRatio(Rect rect) {
    Rect cropRect = _editActionDetails.getRectWithScale(rect);

    if (_editActionDetails.cropAspectRatio != null) {
      final double aspectRatio = _editActionDetails.cropAspectRatio;
      double width = cropRect.width / aspectRatio;
      final double height = min(cropRect.height, width);
      width = height * aspectRatio;
      cropRect = Rect.fromCenter(
          center: cropRect.center, width: width, height: height);
    }
    return cropRect;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    print("_handleScaleStart");
    _layerKey.currentState.pointerDown(true);
    _startingOffset = details.focalPoint;
    _editActionDetails.screenFocalPoint = details.focalPoint;
    _startingScale = _editActionDetails.totalScale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    print("_handleScaleUpdate");
    _layerKey.currentState.pointerDown(true);
    if (_layerKey.currentState.isAnimating || _layerKey.currentState.isMoving) {
      return;
    }
    double totalScale = _startingScale * details.scale;
    // min(_startingScale * details.scale, _editorConfig.maxScale);
    // totalScale=(_startingScale * details.scale).clamp(_editorConfig.minScale, _editorConfig.maxScale);
    final Offset delta = details.focalPoint - _startingOffset;
    final double scaleDelta = totalScale / _editActionDetails.preTotalScale;
    _startingOffset = details.focalPoint;

    //no more zoom
    if (details.scale != 1.0 &&
        (
            // (_editActionDetails.totalScale == _editorConfig.minScale &&
            //       totalScale <= _editActionDetails.totalScale) ||
            doubleEqual(
                    _editActionDetails.totalScale, _editorConfig.maxScale) &&
                doubleCompare(totalScale, _editActionDetails.totalScale) >=
                    0)) {
      return;
    }

    totalScale = min(totalScale, _editorConfig.maxScale);
    //  totalScale.clamp(_editorConfig.minScale, _editorConfig.maxScale);

    if (mounted && (scaleDelta != 1.0 || delta != Offset.zero)) {
      setState(() {
        _editActionDetails.totalScale = totalScale;

        ///if we have shift offset, we should clear delta.
        ///we should += delta in case miss delta
        _editActionDetails.delta += delta;
      });
    }
  }

  List<int> getNativeCropPoints() {
    if (widget.extendedImageState?.extendedImageInfo?.image == null) {
      return null;
    }

    Rect cropScreen = _editActionDetails.screenCropRect;
    Rect imageScreenRect = _editActionDetails.screenDestinationRect;
    imageScreenRect = _editActionDetails.paintRect(imageScreenRect);
    cropScreen = _editActionDetails.paintRect(cropScreen);

    final ui.Image image = widget.extendedImageState.extendedImageInfo.image;
    final Rect imageRect =
    Offset.zero & Size(image.width.toDouble(), image.height.toDouble());

    final double ratioX = imageRect.width / imageScreenRect.width;
    final double ratioY = imageRect.height / imageScreenRect.height;

    List<Offset> points = List();
    for(int index = 0;index <_editActionDetails.cropPoints.length;++index){
      points.add(new Offset(_editActionDetails.cropPoints[index].dx,_editActionDetails.cropPoints[index].dy));
    }
    for(int index = 0;index <points.length;++index) {
      //点转为相对屏幕
      points[index] = points[index] + _editActionDetails.layoutTopLeft;
      //点转为相对图片上的坐标
      points[index] = points[index] - imageScreenRect.topLeft;
      points[index]  = new Offset(points[index].dx * ratioX,points[index].dy * ratioY);
    }

    List<int> cropPoint = new List(8);
    cropPoint[0] = points[EditActionDetails.TOP_LEFT].dx.toInt(); //leftTop x
    cropPoint[1] = points[EditActionDetails.TOP_LEFT].dy.toInt(); //leftTop y
    cropPoint[2] =
        points[EditActionDetails.TOP_RIGHT].dx.toInt(); //rightTop x
    cropPoint[3] =
        points[EditActionDetails.TOP_RIGHT].dy.toInt(); //rightTop y
    cropPoint[4] =
        points[EditActionDetails.BOTTOM_RIGHT].dx.toInt(); //rightBottom x
    cropPoint[5] =
        points[EditActionDetails.BOTTOM_RIGHT].dy.toInt(); //rightBottom y
    cropPoint[6] =
        points[EditActionDetails.BOTTOM_LEFT].dx.toInt(); //leftBottom x
    cropPoint[7] =
        points[EditActionDetails.BOTTOM_LEFT].dy.toInt(); //leftBottom y
    return cropPoint;
  }

  Rect getCropRect() {
    if (widget.extendedImageState?.extendedImageInfo?.image == null) {
      return null;
    }

    List<Offset> points = List();
    for(int index = 0;index <_editActionDetails.cropPoints.length;++index){
      points.add(new Offset(_editActionDetails.cropPoints[index].dx,_editActionDetails.cropPoints[index].dy));
    }
    //点转为相对屏幕
    for(int index = 0;index <points.length;++index) {
      points[index] = points[index] + _editActionDetails.layoutTopLeft;
    }
    Rect cropScreen = _editActionDetails.screenCropRect;
    Rect imageScreenRect = _editActionDetails.screenDestinationRect;
    imageScreenRect = _editActionDetails.paintRect(imageScreenRect);
    cropScreen = _editActionDetails.paintRect(cropScreen);

    //move to zero
    cropScreen = cropScreen.shift(-imageScreenRect.topLeft);

    imageScreenRect = imageScreenRect.shift(-imageScreenRect.topLeft);

    final ui.Image image = widget.extendedImageState.extendedImageInfo.image;
    // var size = _editActionDetails.isHalfPi
    //     ? Size(image.height.toDouble(), image.width.toDouble())
    //     : Size(image.width.toDouble(), image.height.toDouble());
    final Rect imageRect =
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble());

    final double ratioX = imageRect.width / imageScreenRect.width;
    final double ratioY = imageRect.height / imageScreenRect.height;

    final Rect cropImageRect = Rect.fromLTWH(
        cropScreen.left * ratioX,
        cropScreen.top * ratioY,
        cropScreen.width * ratioX,
        cropScreen.height * ratioY);
    debugPrint('imageRect : $cropImageRect');
    debugPrint(
        'imageRect : ${imageRect.width.toDouble()}, ${imageRect.height.toDouble()}');
    GlobalVariables.rect = ui.Rect.fromLTWH(cropScreen.left, cropScreen.top,
        cropImageRect.width, cropImageRect.height);
    return cropImageRect;
  }

  ui.Image get image => widget.extendedImageState.extendedImageInfo?.image;

  Uint8List get rawImageData =>
      (widget.extendedImageState?.imageWidget?.image as ExtendedImageProvider)
          .rawImageData;

  Uint8List get rawByteData => widget.extendedImageState?.extendedImageByteData;


  EditActionDetails get editAction => _editActionDetails;

  void rotate({bool right = true}) {
    setState(() {
      _editActionDetails.rotate(
          right ? pi / 2.0 : -pi / 2.0,
          _layerKey.currentState.layoutRect,
          widget.extendedImageState.imageWidget.fit);
    });
  }

  void flip() {
    setState(() {
      _editActionDetails.flip();
    });
  }

  void reset() {
    setState(() {
      _editorConfig = null;
      _editActionDetails = null;
      _initGestureConfig();
    });
  }
}

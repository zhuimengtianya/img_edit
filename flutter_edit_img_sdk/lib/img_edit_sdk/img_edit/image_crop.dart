import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_edit_img_sdk/img_edit_sdk/editor/extended_image_editor.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/editor/extended_image_editor_utils.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/opencv/native_with_opencv.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/color_utils.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/common_utils.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/extended_image_utils.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/file_utils.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/image/crop_editor_helper.dart';
import '../extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as gimage;

class ImageCrop extends StatefulWidget {
  String path;

  ImageCrop({Key key, this.path})
      : assert(path != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImageCropState();
  }
}

class ImageCropState extends State<ImageCrop> {
  GlobalKey<ExtendedImageEditorState> _imgEditKey =
      GlobalKey<ExtendedImageEditorState>();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ExtendedImage.file(
          File(widget.path),
          colorBlendMode: BlendMode.colorBurn,
          clearMemoryCacheWhenDispose: true,
          fit: BoxFit.contain,
          mode: ExtendedImageMode.editor,
          enableLoadState: true,
          extendedImageEditorKey: _imgEditKey,
          initEditorConfigHandler: (ExtendedImageState state) {
            return EditorConfig(
                maxScale: 8.0,
                cropRectPadding: const EdgeInsets.all(0.0),
                hitTestSize: 32.0,
                initCropRectType: InitCropRectType.imageRect,
                cropAspectRatio: null,
                cornerSize: Size(20, 4),
                cornerColor: MyColors.crop_corner,
                lineColor: MyColors.crop_line,
                lineHeight: 2);
          },
        ),
      ),
    );
  }

  Future<void> cropImage(bool useNative,
      { Function success(ui.Image image),Function failure()}) async {
    ///剪裁图片
    List<int> cropPoint = _imgEditKey.currentState.getNativeCropPoints();
    double newWidth = (getPointsDistance(
                cropPoint[0], cropPoint[1], cropPoint[2], cropPoint[3]) +
            getPointsDistance(
                cropPoint[4], cropPoint[5], cropPoint[6], cropPoint[7])) /
        2;
    double newHeight = (getPointsDistance(
                cropPoint[0], cropPoint[1], cropPoint[6], cropPoint[7]) +
            getPointsDistance(
                cropPoint[2], cropPoint[3], cropPoint[4], cropPoint[5])) /
        2;
    int _newHeight = newHeight.toInt();
    int _newWidth = newWidth.toInt();
    Uint8List _sourceBitmap = _imgEditKey.currentState.rawByteData;
    Uint8List _outBitmap = Uint8List(_newHeight * _newWidth * 4);
    imgEditCrop(
        _sourceBitmap,
        _imgEditKey.currentState.image.width,
        _imgEditKey.currentState.image.height,
        cropPoint,
        _outBitmap,
        _newWidth,
        _newHeight);
    gimage.Image im = gimage.Image.fromBytes(_newWidth, _newHeight, _outBitmap);
    _outBitmap = gimage.encodeJpg(im);
    await saveImage(_outBitmap, widget.path, success: () {
      CommonUtils.loadImageByProvider(MemoryImage(_outBitmap, scale: 1))
          .then((value) {
        success(value);
      });
    }, fail: () {
      failure();
    });
  }
}

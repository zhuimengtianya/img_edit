import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';


final String scrawlImagePath = '/screen_shot_scraw.png';

Future<File> getScreenShotFile() async {
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = '${tempDir.path}$scrawlImagePath';
  File image = File(tempPath);
  bool isExist = await image.exists();
  return isExist ? image : null;
}

Future saveScreenShot2SDCard(RenderRepaintBoundary boundary, String path,
    {double pixelRatio, Function success, Function fail}) async {
  // check storage permission.
  capturePng2List(boundary, pixelRatio: pixelRatio).then((uint8List) async {
    if (uint8List == null || uint8List.length == 0) {
      if (fail != null) fail();
      return;
    }

    saveImage(uint8List, path,
        success: success, fail: fail);
  });
}

//void saveScreenShot(RenderRepaintBoundary boundary,
//    {Function success, Function fail}) {
//  capturePng2List(boundary).then((uint8List) async {
//    if (uint8List == null || uint8List.length == 0) {
//      if (fail != null) fail();
//      return;
//    }
//    Directory tempDir = await getTemporaryDirectory();
//    _saveImage(uint8List, tempDir, scrawlImagePath,
//        success: success, fail: fail);
//  });
//}

void saveImage(Uint8List uint8List, String path,
    {Function success, Function fail}) async {
  String tempPath = path;
  File image = File(tempPath);
  bool isExist = await image.exists();
  if (isExist) await image.delete();
  File(tempPath).writeAsBytes(uint8List).then((_) {
    if (success != null) success();
  });
}

Future<Uint8List> capturePng2List(RenderRepaintBoundary boundary,{double pixelRatio = 1.0}) async {
  ui.Image image =
      await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
  ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  Uint8List pngBytes = byteData.buffer.asUint8List();
  return pngBytes;
}

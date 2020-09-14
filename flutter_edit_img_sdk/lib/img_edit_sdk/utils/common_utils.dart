import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class CommonUtils {
  static double int2double(int value) {
    return value.toDouble();
  }

  static int double2int(double value) {
    return value.toInt();
  }

  static Future<ui.Image> loadImageByProvider(
    ImageProvider provider, {
    ImageConfiguration config = ImageConfiguration.empty,
  }) async {
    Completer<ui.Image> completer = Completer<ui.Image>();
    ImageStreamListener listener;
    ImageStream stream = provider.resolve(config);
    listener = ImageStreamListener((ImageInfo frame, bool sync) {
      final ui.Image image = frame.image;
      completer.complete(image);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    return completer.future;
  }
}

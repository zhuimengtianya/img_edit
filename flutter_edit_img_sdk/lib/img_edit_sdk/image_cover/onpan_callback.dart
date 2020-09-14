import 'package:flutter/gestures.dart';

abstract class OnPanCallback{

  void onPanStart(double scale);
  void onPanUpdate(double scale, Offset details);
  void onPanEnd();

  void onScaleUpdate(double scale);

}
import 'package:flutter/material.dart';

class MyColors{

  ///主题色
  static const MaterialColor theme_color = const MaterialColor(
    0xFFFFFFFF,
    const <int, Color>{
      50: const Color(0xFFFFFFFF),
      100: const Color(0xFFFFFFFF),
      200: const Color(0xFFFFFFFF),
      300: const Color(0xFFFFFFFF),
      400: const Color(0xFFFFFFFF),
      500: const Color(0xFFFFFFFF),
      600: const Color(0xFFFFFFFF),
      700: const Color(0xFFFFFFFF),
      800: const Color(0xFFFFFFFF),
      900: const Color(0xFFFFFFFF),
    },
  );

  ///字体颜色
  static const Color text_black_color = const Color(0xFF08233C);
  static const Color text_gray_color = const Color(0xFF6C8698);
  static const Color text_mid_gray_color = const Color(0xFF5D6777);

  ///控件颜色
  //主题绿
  static const Color view_first_color = Color(0xFF27B7BB);

  //灰色控件
  static const Color view_gray1_color = Color(0xFFF1F4F6);
  //分割线颜色
  static const Color divider_color = Color(0xFFD2DAE0);
  //红色图标
  static const Color circle_bg_color = Color(0xFFF36354);
  //灰色背景
  static const Color view_gray_bg_color = Color(0xFFEBEEF0);

  //拍摄时按钮颜色 黑色70%
  static const Color view_dark_bg_color = Color(0xB3000000);
  //遮盖时：白色50%
  static const Color view_white_bg_color = Color(0x80ffffff);

  //crop
  static const Color crop_corner = Color(0xFFD2DAE0);
  static const Color crop_line = Color(0x4C000000);


}
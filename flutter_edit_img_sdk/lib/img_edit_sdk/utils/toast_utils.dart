import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
class MyToast {

  static FlutterToast flutterToast;

  //指定gravity
  static void showGravityToast(BuildContext context,String content,ToastGravity gravity) {
    showLocationToast(context,content,gravity,0.0);
  }

  //居中显示
  static void showToast(BuildContext context,String content) {
    showGravityToast(context,content,ToastGravity.CENTER);
  }

  //制定Gravity 并设置偏移量.
  static void showLocationToast(BuildContext context,String content,ToastGravity gravity,double offsety) {
    if(flutterToast != null){
      flutterToast.removeCustomToast();
      flutterToast.removeQueuedCustomToasts();
    }
    flutterToast = FlutterToast(context);
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      margin: EdgeInsets.only(
        //调整偏移位置
        top: MediaQuery.of(context).size.height * offsety,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: Colors.black54,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(content,
            style: TextStyle(color: Colors.white,
            ),
          ),
        ],
      ),
    );

    flutterToast.showToast(
      child: toast,
      gravity: gravity,
      toastDuration: Duration(seconds: 2),
    );
  }
}

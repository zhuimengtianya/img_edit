import 'package:flutter/material.dart';
import 'package:flutter_screenutil/screenutil.dart';

import 'color_utils.dart';

///自定义加载Loading
class CustomLoading extends Dialog {

  static bool _showing;

  static void show(context){
    _showing = true;
    showGeneralDialog(
        context: context,
        pageBuilder: (context, anim1, anim2) {},
        barrierColor: Colors.black.withOpacity(.5),
        barrierDismissible: true,
        barrierLabel: "",
        transitionDuration: Duration(milliseconds: 50),
        transitionBuilder: (context, anim1, anim2, child) {
          return Transform.scale(
              scale: anim1.value,
              child: Opacity(
                  opacity: anim1.value,
                  child: CustomLoading()
              ));
        });
  }

  static void dismiss(context){
    if(_showing){
      Navigator.pop(context);
    }
    _showing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shadowColor: Colors.transparent,
      child: Center(
        child: Container(
          width: ScreenUtil().setWidth(ScreenUtil().setWidth(450)),
          height: ScreenUtil().setHeight(ScreenUtil().setHeight(550)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(top: ScreenUtil().setHeight(30)),),
              CircularProgressIndicator(backgroundColor: MyColors.view_first_color,),
              Padding(padding: EdgeInsets.only(top: ScreenUtil().setHeight(20)),),
              Text("   加载中...", style: TextStyle(color: MyColors.text_gray_color),),
            ],
          ),
        ),
      ),
    );
  }
}

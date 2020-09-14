import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/screenutil.dart';
import 'package:flutter_edit_img_sdk_example/view/common_widget.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/global_variables.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/img_edit/image_crop.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/img_edit/img_cover.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/color_utils.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/toast_utils.dart';
import 'package:flutter_edit_img_sdk_example/view/black_title_bar.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/image_cover/onpan_callback.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/img_edit/core/drag_scale_widget.dart';


class ImgEdit extends StatefulWidget {
  final String path;

  ImgEdit({Key key, this.path}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ImgEditState(path: path);
}

class ImgEditState extends State<ImgEdit> implements OnPanCallback {
  final GlobalKey<ImageCropState> _imgEditKey = GlobalKey<ImageCropState>();
  final GlobalKey _repaintKey = GlobalKey();
  final GlobalKey<ImageCoverState> _coverKey = GlobalKey<ImageCoverState>();
  final GlobalKey<DragScaleContainerState> _scaleKey =
      GlobalKey<DragScaleContainerState>();

  String path;
  int _paintRotation = 0;
  ui.Image _paintImage;

  ///图片涂鸦
  static final List<Color> colors = [
    Colors.black,
  ];
  Map keyValue = Map<String, String>();
  File imageFile;
  bool isPaintPage = false;
  ///更新按钮图片
  bool _backBtn = false;
  bool _frontBtn = false;

  ///控制遮盖按钮是否选择
  bool _coverSelected = false;
  bool isScale = false;

  ///遮盖的图片缩放至原始大小，方便保存图片
  bool _scaleDefault = false;
  ImgEditState({Key key, this.path});

  @override
  void initState() {
    super.initState();
    imageCache.clear();
    path = GlobalVariables.filePath;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('img edit path : $path');
    return Scaffold(
      appBar: BlackAppbar(
        title: '信息遮盖',
        leftBtnCallback: () {
          Navigator.popAndPushNamed(context, "/MyCameraPreview");
        },
      ),
      backgroundColor: Colors.black,
      extendBody: true,
      body: selectBody(),
    );
  }

  ///编辑图片
  Widget _buildBottomNavigationBar() {
    return Container(
      color: Colors.black,
      height: ScreenUtil().setSp(160),
      child: ButtonTheme(
        minWidth: 0.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox.fromSize(
              size: Size(ScreenUtil().setSp(300), ScreenUtil().setSp(80)),
              child: OutlineButton(
                child: Text("取消",
                    style: TextStyle(color: MyColors.view_white_bg_color)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0)),
                onPressed: () {
                  Navigator.popAndPushNamed(context, "/MyCameraPreview");
                },
                borderSide: BorderSide(
                  color: MyColors.view_first_color,
                  style: BorderStyle.solid,
                  width: 0.8,
                ),
              ),
            ),
            SizedBox.fromSize(
              size: Size(ScreenUtil().setSp(300), ScreenUtil().setSp(80)),
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0)),
                color: MyColors.view_first_color,
                onPressed: () {
                ///调用裁剪方法.回调image
                  _onCropPress();
                },
                child: Text('确认', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCropPress() {
    _imgEditKey.currentState.cropImage(true, success: (croppedImage) {
      if (croppedImage != null) {
        setState(() {
          _paintImage = croppedImage;
          isPaintPage = true;
        });
      }
    }, failure: () {
      MyToast.showToast(context, '图片保存失败!');
    });
  }

  ///return body
  Widget selectBody() {
    return isPaintPage ? changeToPaint() : changeToCrop();
  }

  ///切换到裁剪页面
  Widget changeToCrop() {
    return Column(
      children: <Widget>[
        ImageCrop(key: _imgEditKey, path: path),
        Container(
            margin: EdgeInsets.only(top: ScreenUtil().setSp(54)),
            width: ScreenUtil().setSp(488),
            height: ScreenUtil().setSp(112),
            alignment: Alignment.center,
            decoration: new BoxDecoration(
                color: MyColors.view_white_bg_color,
                borderRadius: BorderRadius.all(Radius.circular(56))),
            child: Text('请确保裁剪内容本身以外的\n背景区域',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: ScreenUtil().setSp(28), color: Colors.white))),
        _buildBottomNavigationBar(),
      ],
    );
  }

  ///切换到遮挡页面
  Widget changeToPaint() {
    return Container(
      color: Colors.black,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.black,
              child: RepaintBoundary(
                key: _repaintKey,
                ///自定义缩放widget
                child: DragScaleContainer(
                  key: _scaleKey,
                  rotation: _paintRotation,
                  isCover: _coverSelected,
                  scaleDefault: _scaleDefault,
                  doubleTapStillScale: true,
                  panCallback: this,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned(
                        child: ImageCover(_coverKey,_paintImage),
                        top: 0.0,
                        bottom: 0.0,
                        left: 0.0,
                        right: 0.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottom(),
        ],
      ),
    );
  }

  ///构建底部UI
  Widget _buildBottom() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(
            width: ScreenUtil().setWidth(70),
            child: IconButton(
              icon: _backBtn
                  ? Image.asset("images/icon_back_on.png")
                  : Image.asset("images/icon_back_off.png"),
              onPressed: () {
                setState(() {
                  _coverKey.currentState.back();
                });
              },
            ),
          ),
          SizedBox(
            width: ScreenUtil().setWidth(70),
            child: IconButton(
              iconSize: ScreenUtil().setWidth(40),
              icon: _frontBtn
                  ? Image.asset("images/icon_front_on.png")
                  : Image.asset("images/icon_front_off.png"),
              onPressed: () {
                setState(() {
                _coverKey.currentState.front();
                });
              },
            ),
          ),
          SizedBox(
            width: ScreenUtil().setWidth(5),
          ),
          SizedBox(
            width: ScreenUtil().setWidth(100),
            child: FlatButtonWithIcon(
              icon: ImageIcon(AssetImage('images/icon_roeate_left.png')),
              label: const Text(
                ' 旋 转',
                style: TextStyle(fontSize: 8.0),
              ),
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  print("_paintRotation:$_paintRotation");
                  _scaleKey.currentState.reSetNormal();
                  _paintRotation = (_paintRotation + 90) % 360;
                });
              },
            ),
          ),
          SizedBox(
            width: ScreenUtil().setWidth(100),
            child: FlatButtonWithIcon(
              icon: ImageIcon(AssetImage(_coverSelected
                  ? 'images/icon_cover_selected.png'
                  : 'images/icon_cover.png')),
              label: const Text(
                ' 遮 盖 ',
                style: TextStyle(fontSize: 8.0),
              ),
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _coverSelected = !_coverSelected;
                });
              },
            ),
          ),
          SizedBox(
            width: ScreenUtil().setWidth(40),
          ),
          RaisedButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.0)),
            color: MyColors.view_first_color,
            onPressed: () =>saveScreenPic(),
            child: Text('提交', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void onPanEnd() {
    // TODO: implement onPanEnd
    _coverKey.currentState.addPath();
    setState(() {
      _frontBtn = false;
      _backBtn = true;
    });
  }

  @override
  void onPanStart(double scale) {
    /// TODO: implement onPanStart
  }

  @override
  void onPanUpdate(double scale, Offset offset) {
    /// TODO: implement onPanUpdate
    MediaQueryData queryData = MediaQuery.of(context);
    double ratio = queryData.devicePixelRatio;
    debugPrint("onPanUpdate ratio = ${ratio}");
    ///转化为相对图片上的点
    setState(() {
      Offset localPosition = _coverKey.currentState.pointInImage(_paintRotation, offset, scale);
      _coverKey.currentState.addPoint(localPosition);
    });
  }

  @override
  void onScaleUpdate(double scale) {
    /// TODO: implement onScaleUpdate
     isScale = (scale - 1) > 0;
  }
   /// 保存最终遮盖后的图片.
  void saveScreenPic() async {
    _coverKey.currentState.saveEndPic(path);
  }
}

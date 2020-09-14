import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/screenutil.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/global_variables.dart';

import 'page/img_edit.dart';

void main() {
  runApp(MyCameraPreview());
}
class MyCameraPreview extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
      initialRoute: "/",
      routes: {
        '/ImgEdit': (context) => ImgEdit(),
        '/MyCameraPreview':(context) => MyCameraPreview(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    makeDir();
    _initCamera();
  }
  Future<void> makeDir() async {
    final Directory extDir = await getExternalStorageDirectory();
    appPath = '${extDir.path}';
  }
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1624);
    if (_controller != null) {
      if (!_controller.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }
    debugPrint('2 isInitialized : ${_controller.value.isInitialized}');
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: <Widget>[
        Container(
          alignment: Alignment.centerRight,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '',
                ),
              ),
              GestureDetector(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        new Flexible(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[_buildCameraPreview()],
          ),
        ),
      ]),
      bottomNavigationBar:
      _buildBottomNavigationBar(),
    );
  }
  CameraController _controller;
  String appPath;
  final GlobalKey _focusKey = GlobalKey();

  //手动对焦框的位置
  Offset _focusPoint;
  //是否显示手动对焦框
  bool _isShowFocusRect = false;
  Future<void> _initCamera() async {
    List<CameraDescription> _cameras;
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.veryHigh);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  ///构建底部控件-按钮
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80.0,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 50.0,
        child: IconButton(
          iconSize: 80,
          icon: ImageIcon(AssetImage('images/ic_take_picture.png')),
          onPressed: () {
            _checkFileState();
          },
        ),
      ),
    );
  }
  ///添加拍照预览view.
  Widget _buildCameraPreview() {
    return ClipRect(
      child: Container(
        child: Center(
          child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CameraPreview(_controller),
                  GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                          key: _focusKey,
                          margin: EdgeInsets.only(
                              left: 15, top: 15, right: 15, bottom: 155),
                          decoration: new BoxDecoration(
                              border: new Border.all(
                                  color: Color(0xFFFF0000), width: 2),
                              color: Color(0x00000000))),
                      onTapUp: (TapUpDetails details) {
                        if (Platform.isAndroid) {
                          _controller.triggerFocusArea(details.localPosition.dx,
                              details.localPosition.dy);
                        } else {
                          final RenderBox box = context.findRenderObject();
                          final Offset loaclOffset =
                          box.globalToLocal(details.globalPosition);
                          final Offset scaledPoint = loaclOffset.scale(
                              1 / box.size.width, 1 / box.size.height);
                          _controller.setPointOfInterest(scaledPoint);
                        }
                        focusBox(details);
                      }),
                  _showFocusRect(_focusPoint),
                ],
              )),
        ),
      ),
    );
  }
  void _checkFileState() async {
    if (_controller.value.isInitialized) {
      SystemSound.play(SystemSoundType.click);
      final String filePath = '$appPath/demo.png';
      final myDir = new File(filePath);
      myDir.exists().then((isThere) {
        isThere ? debugPrint('exists') : debugPrint('non-existent');
        if (isThere) {
          Future future = myDir
              .delete(recursive: false)
              .then((FileSystemEntity fileSystemEntity) {
            debugPrint('删除path' + fileSystemEntity.path);
          });
          future.whenComplete(() => _captureImage(filePath));
        } else {
          _captureImage(filePath);
        }
      });
    }
  }
  ///拍摄照片
  void _captureImage(String filePath) async {
    debugPrint('拍照 path: $filePath');
    GlobalVariables.filePath = filePath;
    await _controller
        .takePicture(filePath)
        .whenComplete(() => gotoEditImgPage(filePath));
  }
  void gotoEditImgPage(String filePath){
    Navigator.pushReplacementNamed(context,"/ImgEdit");
  }

  ///点击控制显示手动对焦框
  void focusBox(TapUpDetails details) {
    final RenderBox focusBox = _focusKey.currentContext.findRenderObject();
    _focusPoint = focusBox.globalToLocal(details.globalPosition);
    print('focus $_focusPoint');
    //show Rect
    setState(() {
      _isShowFocusRect = true;
      Future.delayed(Duration(seconds: 1)).then((_) {
        setState(() {
          _isShowFocusRect = false;
        });
      });
    });
  }

  ///显示对焦框
  Widget _showFocusRect(Offset focus) {
    return _isShowFocusRect
        ? Positioned(
      child: Container(
          width: 20,
          height: 20,
          decoration: new BoxDecoration(
              border: new Border.all(color: Color(0xFFFF0000), width: 1),
              color: Color(0x00000000))),
      left: _focusPoint.dx - 10,
      top: _focusPoint.dy - 10,
    )
        : Text('');
  }
}

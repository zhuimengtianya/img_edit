# flutter_edit_img_sdk

A new Flutter plugin.

#  Flutter 图片编辑SDK 
## 版本:
1.0
## 描述:
Flutter图片编辑:包括裁剪,缩放,遮挡等功能,
## 更新日志文档
2020/09/09初步封装,自动裁剪,缩放,遮挡等功能.
## 接入流程
1. 导入flutter_edit_img_sdk
2. 在pubspec.yaml文件中配置
<pre> 
  flutter_edit_img_sdk:
     path: flutter_edit_img_sdk
</pre>
## 调用方法和参数说明
#### 1.调用自动裁剪方法 主要接口在image_crop.dart文件.
定义一个GlobalKey跨Widget访问状态.
<pre>final GlobalKey<ImageCropState> _imgEditKey = GlobalKey<ImageCropState>();</pre>
实例化ImageCrop对象
<pre>ImageCrop(key: _imgEditKey, path: imgPath)</pre>
裁剪时调用方法:
<pre>
_imgEditKey.currentState.cropImage(bool useNative, success: (ui.Image image) {
    ///TODO 
}, failure: (){
    ///TODO
})
</pre>
#### 2.缩放功能需引入自定义widget文件 drag_scale_widget.dart 配置相关属性.
scaleDefault属性 遮盖的图片缩放至原始大小 true为原始大小,false可以自由缩放.
<pre>
child: DragScaleContainer(		
  key: _scaleKey,
  rotation: _paintRotation,
  isCover: _coverSelected,
  scaleDefault: _scaleDefault,
  doubleTapStillScale: true,
  panCallback: this,
  child: Stack(
      ),
),
</pre>

#### 3.遮盖功能 主要接口 img_cover.dart文件.
<pre>final GlobalKey<ImageCoverState> _coverKey = GlobalKey<ImageCoverState>();</pre>
遮盖时添加遮盖轨迹的方法:
<pre>
Offset localPosition = _coverKey.currentState.pointInImage(int rotation, Offset offset, double containScale);
_coverKey.currentState.addPoint(localPosition);
</pre>
绘制完成时添加路径的方法：
<pre>
_coverKey.currentState.addPath();
</pre>
1)实例化ImageCover对象.
<pre>child: ImageCover(Key _coverKey, ui.Image _paintImage)</pre>
2)图片编辑-撤销.
 <pre>_coverKey.currentState.back();</pre>
3)图片编辑-恢复.
 <pre>_coverKey.currentState.front();</pre>
4)保存最后的图片 path就是保存图片的路径.
 <pre>_coverKey.currentState.saveEndPic(String ImagePath);</pre>

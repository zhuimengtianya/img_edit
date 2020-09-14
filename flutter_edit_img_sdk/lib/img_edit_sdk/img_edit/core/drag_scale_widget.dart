import 'package:flutter/material.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/image_cover/core/touchable_container.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/image_cover/onpan_callback.dart';


@immutable
class DragScaleContainer extends StatefulWidget {
  Widget child;
  Key key;
  /// 双击内容是否一致放大，默认是true，也就是一致放大
  /// 如果为false，第一次双击放大两倍，再次双击恢复原本大小
  bool doubleTapStillScale;
  OnPanCallback panCallback;
  ///遮盖功能是否开启
  bool isCover;
  ///缩放指原始大小
  bool _scaleDefault;
  int rotation;
  DragScaleContainer({Key key, Widget child, int rotation = 0, bool isCover = false, bool scaleDefault = false, bool doubleTapStillScale = true, OnPanCallback panCallback})
      : this.key = key,
        this.child = child,
        this.rotation = rotation,
        this.isCover = isCover,
        this._scaleDefault = scaleDefault,
        this.doubleTapStillScale = doubleTapStillScale,
        this.panCallback = panCallback,
        super(key: key);
  @override
  State<StatefulWidget> createState() {
    return DragScaleContainerState(key: key, isCover: isCover);
  }
}

class DragScaleContainerState extends State<DragScaleContainer> {
  GlobalKey<TouchableContainerState> _touchableKey =  GlobalKey<TouchableContainerState>();
  Key key;
  bool isCover;
  DragScaleContainerState({Key key, bool isCover}):
        this.key = key,
        this.isCover = isCover;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: TouchableContainer(
          key: _touchableKey,
          child: widget.child, rotation: this.widget.rotation,isCover: widget.isCover, scaleDefault: widget._scaleDefault, doubleTapStillScale: widget.doubleTapStillScale, panCallback: widget.panCallback),
    );
  }

  void reSetNormal(){
     _touchableKey.currentState.reSetNormal();
  }

  Offset getRenderOffset(){
    return _touchableKey.currentState.getRenderOffset();
  }

  double getRenderScale(){
    return _touchableKey.currentState.getRenderScale();
  }


}

import 'package:flutter/material.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/color_utils.dart';
import 'package:flutter_edit_img_sdk/img_edit_sdk/utils/dimen_utils.dart';
class BlackAppbar extends StatefulWidget implements PreferredSizeWidget {
  final double contentHeight;
  String title;
  VoidCallback leftBtnCallback;
  BlackAppbar({
    Key key,
    @required this.title,
    this.contentHeight = MyDimens.app_bar_height,
    this.leftBtnCallback,
  }) : super(key : key);

  @override
  State<StatefulWidget> createState() {
    return new _BlackAppbarState();
  }

  @override
  Size get preferredSize => new Size.fromHeight(contentHeight);
}

class _BlackAppbarState extends State<BlackAppbar> {

  @override
  void initState() {
    super.initState();
  }

  void _clickBack(){
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.black,
      child: new SafeArea(
        top: true,
        child: new Container(
            decoration: new UnderlineTabIndicator(
              borderSide: BorderSide(width: 0.5, color: MyColors.text_black_color),
            ),
            height: widget.contentHeight,
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: widget.leftBtnCallback != null ? widget.leftBtnCallback : _clickBack,
                  child: Container(
                    padding: const EdgeInsets.only(left: MyDimens.info_page_margin_h, right: 10.0, top: 10.0, bottom: 10.0),
                    child: Image(
                      image: new AssetImage("images/icon_back_white.png"),
                      width: 18.0,
                      height: 18.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(widget.title,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    style: new TextStyle(
                        fontSize: MyDimens.fontSize_32, color: Colors.white)
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
  //to do
}

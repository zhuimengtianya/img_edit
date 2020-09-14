import 'dart:ffi'; // For FFI
import 'dart:io'; // For Platform.isX
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeAddLib =
    Platform.isAndroid ? DynamicLibrary.open("libflutter_opencv.so") : DynamicLibrary.process();

final int Function(int x, int y) nativeAdd =
    nativeAddLib.lookup<NativeFunction<Int32 Function(Int32, Int32)>>("native_add").asFunction();

final int Function(int x, int y, int z) nativeAdd3 =
nativeAddLib.lookup<NativeFunction<Int32 Function(Int32, Int32, Int32)>>("native_add3").asFunction();


///typedef native_scan
typedef native_scan = Void Function(Pointer<Int8> srcBitmap, Int32 width, Int32 height,  Int32 format, Pointer<Int32> outPoint, Int8 canny);

///typedef native_crop
typedef native_crop = Void Function(Pointer<Int8> srcBitmap,  Int32 width, Int32 height,  Int32 format, Pointer<Int32> points, Int32 arrayLength, Pointer<Int8> outBitmap, Int32 newWidth, Int32 newHeight);

///native_scan本地方法声明
final void Function(Pointer<Int8> srcBitmap, int width, int height, int format, Pointer<Int32> outPoint, int canny) flutterScan
= nativeAddLib.lookup<NativeFunction<native_scan>>("native_scan").asFunction();

///native_crop本地方法声明
final void Function(Pointer<Int8> srcBitmap, int width, int height,  int format, Pointer<Int32> points, int arrayLength, Pointer<Int8> outBitmap, int newWidth, int newHeight) flutterCrop
= nativeAddLib.lookup<NativeFunction<native_crop>>("native_crop").asFunction();

///图片自动裁剪区域获取，
///
/// outPoint 输出的裁剪区域。
/// 返回顶点数组，以 左上，右上，右下，左下排序
void imgEditSacn(Uint8List sourceData, int width, int height, List<int> outPoint, bool canny){
    Pointer<Int8> soureData = allocate<Int8>(count:sourceData.length);
    final pointerList = soureData.asTypedList(sourceData.length);
    pointerList.setAll(0, sourceData);

    Pointer<Int32> outPPoint = allocate<Int32>(count:outPoint.length);
    flutterScan(soureData, width, height, 1, outPPoint, 1);
    final outPPointList = outPPoint.asTypedList(outPoint.length);
    for(int i = 0; i < outPoint.length; ++i){
        outPoint[i] = outPPointList[i];
    }
    print('length = ${outPoint.length}');

    //释放资源，主要是指针
}

///图片裁剪功能
///
/// cropPoint 顶点数组，以 左上，右上，右下，左下排序
/// outBitmap 为裁剪后输出的图片byte资源
void imgEditCrop(Uint8List sourceData, int width, int height, List<int> cropPoint, Uint8List outBitmap, int newWidth, int newHeight){
    Pointer<Int8> soureData = allocate<Int8>(count:sourceData.length);
    final pointerList = soureData.asTypedList(sourceData.length);
    pointerList.setAll(0, sourceData);

    Pointer<Int8> outData = allocate<Int8>(count:outBitmap.length);
    final outList = outData.asTypedList(outBitmap.length);
    outList.setAll(0, outBitmap);

    Pointer<Int32> cropPPoint = allocate<Int32>(count:cropPoint.length);
    final outPointList = cropPPoint.asTypedList(cropPoint.length);
    outPointList.setAll(0, cropPoint);

    flutterCrop(soureData, width, height, 1, cropPPoint, cropPoint.length, outData, newWidth, newHeight);

    final outBitmapList = outData.asTypedList(outBitmap.length);
    outBitmap.setAll(0, outBitmapList);
    print(outBitmapList);
    //释放资源，只要是指针
}



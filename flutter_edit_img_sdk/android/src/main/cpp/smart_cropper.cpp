//
// Created by xujianliang on 7/7/20.
//
#include <string>
#include <Scanner.h>
#include "android_utils.h"

#include<android/log.h>

#define TAG "croper-jni" // 这个是自定义的LOG的标识
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG,TAG ,__VA_ARGS__) // 定义LOGD类型

using namespace std;

//extern "C" {
vector<cv::Point> pointsToNative(int *points_, int arrayLength) {
    vector<cv::Point> result;
    for(int i = 0; i < arrayLength; i+=2) {
        int pX = *(points_ + i);
        int pY = *(points_ + i + 1);
//        LOGD("navive_cropPoint %d, pX =%d, %d, pY =%d", i,  pX, i+1, pY);
        result.push_back(cv::Point(pX, pY));
    }
    return result;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void native_scan(u_int8_t *srcBitmap, int width, int height, int format, int *outPoint_, bool canny) {
    cv::Mat srcBitmapMat;
    bitmap_to_mat(srcBitmap, width, height, format, srcBitmapMat);
    cv::Mat bgrData(srcBitmapMat.rows, srcBitmapMat.cols, CV_8UC3);
    cvtColor(srcBitmapMat, bgrData, COLOR_RGBA2BGR);
    scanner::Scanner docScanner(bgrData, canny);
    std::vector<cv::Point> scanPoints = docScanner.scanPoint();
    if (scanPoints.size() == 4) {
        for (int i = 0; i < 4; ++i) {
            *(outPoint_ + i * 2) = scanPoints[i].x;
            *(outPoint_ + i * 2 + 1) = scanPoints[i].y;
        }
    }
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void native_crop(u_int8_t *srcBitmap, int width, int height, int format, int *points_, int arrayLength, u_int8_t *outBitmap, int newWidth, int newHeight) {
    std::vector<cv::Point> points = pointsToNative(points_, arrayLength);
    if (points.size() != 4) {
        return;
    }
    cv::Point leftTop = points[0];
    cv::Point rightTop = points[1];
    cv::Point rightBottom = points[2];
    cv::Point leftBottom = points[3];

    cv::Mat srcBitmapMat;
    bitmap_to_mat(srcBitmap,  width, height, format, srcBitmapMat);

    cv::Mat dstBitmapMat;
    dstBitmapMat = Mat::zeros(newHeight, newWidth, srcBitmapMat.type());

    std::vector<Point2f> srcTriangle;
    std::vector<Point2f> dstTriangle;

    srcTriangle.push_back(Point2f(leftTop.x, leftTop.y));
    srcTriangle.push_back(Point2f(rightTop.x, rightTop.y));
    srcTriangle.push_back(Point2f(leftBottom.x, leftBottom.y));
    srcTriangle.push_back(Point2f(rightBottom.x, rightBottom.y));

    dstTriangle.push_back(Point2f(0, 0));
    dstTriangle.push_back(Point2f(newWidth, 0));
    dstTriangle.push_back(Point2f(0, newHeight));
    dstTriangle.push_back(Point2f(newWidth, newHeight));

    cv::Mat transform = getPerspectiveTransform(srcTriangle, dstTriangle);
    warpPerspective(srcBitmapMat, dstBitmapMat, transform, dstBitmapMat.size());

    mat_to_bitmap( dstBitmapMat, format, outBitmap, newWidth, newHeight);
    LOGD("navive_crop newWidth %d, newHeight %d", newWidth, newHeight);
}
//}





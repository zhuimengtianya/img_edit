//
// Created by qiulinmin on 17-5-15.
//

#ifndef IMG_ANDROID_UTILS_H
#define IMG_ANDROID_UTILS_H

//#include <android/bitmap.h>
#include <opencv2/opencv.hpp>

using namespace cv;

void bitmap_to_mat(u_int8_t *srcBitmap, uint32_t srcWidth, uint32_t srcHeight, int format, cv::Mat &srcMat);

void mat_to_bitmap(cv::Mat &srcMat, int format, u_int8_t *destBitmap, uint32_t dstWidth, uint32_t dstHeight);

#endif //IMG_ANDROID_UTILS_H

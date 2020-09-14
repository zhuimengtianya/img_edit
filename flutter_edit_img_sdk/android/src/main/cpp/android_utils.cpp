//
// Created by qiulinmin on 17-5-15.
//
#include "android_utils.h"


void bitmap_to_mat(u_int8_t *srcBitmap, uint32_t srcWidth, uint32_t srcHeight, int format, cv::Mat &srcMat) {
    srcMat.create(srcHeight, srcWidth, CV_8UC4);
    if(format == 1){///RGB888
        cv::Mat tmp(srcHeight, srcWidth, CV_8UC4, srcBitmap);
        tmp.copyTo(srcMat);
    } else {//RGB565
         cv::Mat tmp = Mat(srcHeight, srcWidth, CV_8UC2, srcBitmap);
         cvtColor(tmp, srcMat, cv::COLOR_BGR5652RGBA);
    }
}

void mat_to_bitmap(cv::Mat &srcMat, int format, u_int8_t *destBitmap, uint32_t dstWidth, uint32_t dstHeight) {
    if (format == 1) {///RGB888
        cv::Mat tmp(dstHeight, dstWidth, CV_8UC4, destBitmap);
        if(srcMat.type() == CV_8UC1) {
            cvtColor(srcMat, tmp, COLOR_GRAY2RGBA);
        } else if (srcMat.type() == CV_8UC3) {
            cvtColor(srcMat, tmp, COLOR_RGB2RGBA);
        } else if (srcMat.type() == CV_8UC4) {
            srcMat.copyTo(tmp);
        }
    } else {//RGB565
        cv::Mat tmp = Mat(dstHeight, dstWidth, CV_8UC2, destBitmap);
        if(srcMat.type() == CV_8UC1) {
            cvtColor(srcMat, tmp, COLOR_GRAY2BGR565);
        } else if (srcMat.type() == CV_8UC3) {
            cvtColor(srcMat, tmp, COLOR_RGB2BGR565);
        } else if (srcMat.type() == CV_8UC4) {
            cvtColor(srcMat, tmp, COLOR_RGBA2BGR565);
        }
    }
}






#include <stdint.h>
#include <opencv2/core.hpp>
#include <opencv2/opencv.hpp>
using namespace std;
using namespace cv;

int resizeThreshold = 500;
cv::Mat srcBitmap;
float resizeScale = 1.0f;
bool canny = true;
bool isHisEqual = false;

cv::Mat resizeImage();
cv::Mat preprocessedImage(cv::Mat &image, int cannyValue, int blurValue);
cv::Point choosePoint(cv::Point center, std::vector<cv::Point> &points, int type);
std::vector<cv::Point> selectPoints(std::vector<cv::Point> points);
std::vector<cv::Point> sortPointClockwise(std::vector<cv::Point> vector);
long long pointSideLine(cv::Point& lineP1, cv::Point& lineP2, cv::Point& point);



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

//Scanner  start

static bool sortByArea(const vector<Point> &v1, const vector<Point> &v2) {
    double v1Area = fabs(contourArea(Mat(v1)));
    double v2Area = fabs(contourArea(Mat(v2)));
    return v1Area > v2Area;
}

vector<Point> scanPoint() {
    vector<Point> result;
    int cannyValue[] = {100, 150, 300};
    int blurValue[] = {3, 7, 11, 15};
    //缩小图片尺寸
    Mat image = resizeImage();
    for (int i = 0; i < 3; i++){
        for (int j = 0; j < 4; j++){
            //预处理图片
            Mat scanImage = preprocessedImage(image, cannyValue[i], blurValue[j]);
            vector<vector<Point>> contours;
            //提取边框
            findContours(scanImage, contours, RETR_EXTERNAL, CHAIN_APPROX_NONE);
            //按面积排序
            std::sort(contours.begin(), contours.end(), sortByArea);
            if (contours.size() > 0) {
                vector<Point> contour = contours[0];
                double arc = arcLength(contour, true);
                vector<Point> outDP;
                //多变形逼近
                approxPolyDP(Mat(contour), outDP, 0.01 * arc, true);
                //筛选去除相近的点
                vector<Point> selectedPoints = selectPoints(outDP);
                if (selectedPoints.size() != 4) {
                    //如果筛选出来之后不是四边形
                    continue;
                } else {
                    int widthMin = selectedPoints[0].x;
                    int widthMax = selectedPoints[0].x;
                    int heightMin = selectedPoints[0].y;
                    int heightMax = selectedPoints[0].y;
                    for (int k = 0; k < 4; k++) {
                        if (selectedPoints[k].x < widthMin) {
                            widthMin = selectedPoints[k].x;
                        }
                        if (selectedPoints[k].x > widthMax) {
                            widthMax = selectedPoints[k].x;
                        }
                        if (selectedPoints[k].y < heightMin) {
                            heightMin = selectedPoints[k].y;
                        }
                        if (selectedPoints[k].y > heightMax) {
                            heightMax = selectedPoints[k].y;
                        }
                    }
                    //选择区域外围矩形面积
                    int selectArea = (widthMax - widthMin) * (heightMax - heightMin);
                    int imageArea = scanImage.cols * scanImage.rows;
                    if (selectArea < (imageArea / 20)) {
                        result.clear();
                        //筛选出来的区域太小
                        continue;
                    } else {
                        result = selectedPoints;
                        if (result.size() != 4) {
                            Point2f p[4];
                            p[0] = Point2f(0, 0);
                            p[1] = Point2f(image.cols, 0);
                            p[2] = Point2f(image.cols, image.rows);
                            p[3] = Point2f(0, image.rows);
                            result.push_back(p[0]);
                            result.push_back(p[1]);
                            result.push_back(p[2]);
                            result.push_back(p[3]);
                        }
                        for (Point &p : result) {
                            p.x *= resizeScale;
                            p.y *= resizeScale;
                        }
                        // 按左上，右上，右下，左下排序
                        return sortPointClockwise(result);
                    }
                }
            }
        }
    }
    //当没选出所需要区域时，如果还没做过直方图均衡化则尝试使用均衡化，但该操作只执行一次，若还无效，则判定为图片不能裁出有效区域，返回整张图
    if (!isHisEqual){
        isHisEqual = true;
        return scanPoint();
    }
    if (result.size() != 4) {
        Point2f p[4];
        p[0] = Point2f(0, 0);
        p[1] = Point2f(image.cols, 0);
        p[2] = Point2f(image.cols, image.rows);
        p[3] = Point2f(0, image.rows);
        result.push_back(p[0]);
        result.push_back(p[1]);
        result.push_back(p[2]);
        result.push_back(p[3]);
    }
    for (Point &p : result) {
        p.x *= resizeScale;
        p.y *= resizeScale;
    }
    // 按左上，右上，右下，左下排序
    return sortPointClockwise(result);
}

Mat resizeImage() {
    int width = srcBitmap.cols;
    int height = srcBitmap.rows;
    int maxSize = width > height? width : height;
    if (maxSize > resizeThreshold) {
        resizeScale = 1.0f * maxSize / resizeThreshold;
        width = static_cast<int>(width / resizeScale);
        height = static_cast<int>(height / resizeScale);
        Size size(width, height);
        Mat resizedBitmap(size, CV_8UC3);
        resize(srcBitmap, resizedBitmap, size);
        return resizedBitmap;
    }
    return srcBitmap;
}

Mat preprocessedImage(Mat &image, int cannyValue, int blurValue) {
    Mat grayMat;
    cvtColor(image, grayMat, COLOR_BGR2GRAY);
    if (!canny) {
        return grayMat;
    }
    if (isHisEqual){
        equalizeHist(grayMat, grayMat);
    }
    Mat blurMat;
    GaussianBlur(grayMat, blurMat, Size(blurValue, blurValue), 0);
    Mat cannyMat;
    Canny(blurMat, cannyMat, 50, cannyValue, 3);
    Mat thresholdMat;
    threshold(cannyMat, thresholdMat, 0, 255, THRESH_OTSU);
    return thresholdMat;
}

vector<Point> selectPoints(vector<Point> points) {
    if (points.size() > 4) {
        Point &p = points[0];
        int minX = p.x;
        int maxX = p.x;
        int minY = p.y;
        int maxY = p.y;
        //得到一个矩形去包住所有点
        for (int i = 1; i < points.size(); i++) {
            if (points[i].x < minX) {
                minX = points[i].x;
            }
            if (points[i].x > maxX) {
                maxX = points[i].x;
            }
            if (points[i].y < minY) {
                minY = points[i].y;
            }
            if (points[i].y > maxY) {
                maxY = points[i].y;
            }
        }
        //矩形中心点
        Point center = Point((minX + maxX) / 2, (minY + maxY) / 2);
        //分别得出左上，左下，右上，右下四堆中的结果点
        Point p0 = choosePoint(center, points, 0);
        Point p1 = choosePoint(center, points, 1);
        Point p2 = choosePoint(center, points, 2);
        Point p3 = choosePoint(center, points, 3);
        points.clear();
        //如果得到的点不是０，即是得到的结果点
        if (!(p0.x == 0 && p0.y == 0)){
            points.push_back(p0);
        }
        if (!(p1.x == 0 && p1.y == 0)){
            points.push_back(p1);
        }
        if (!(p2.x == 0 && p2.y == 0)){
            points.push_back(p2);
        }
        if (!(p3.x == 0 && p3.y == 0)){
            points.push_back(p3);
        }
    }
    return points;
}

//type代表左上，左下，右上，右下等方位
Point choosePoint(Point center, std::vector<cv::Point> &points, int type) {
    int index = -1;
    int minDis = 0;
    //四个堆都是选择距离中心点较远的点
    if (type == 0) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x < center.x && points[i].y < center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }
    } else if (type == 1) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x < center.x && points[i].y > center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }
    } else if (type == 2) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x > center.x && points[i].y < center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }

    } else if (type == 3) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x > center.x && points[i].y > center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }
    }

    if (index != -1){
        return Point(points[index].x, points[index].y);
    }
    return Point(0, 0);
}

vector<Point> sortPointClockwise(vector<Point> points) {
    if (points.size() != 4) {
        return points;
    }

    Point unFoundPoint;
    vector<Point> result = {unFoundPoint, unFoundPoint, unFoundPoint, unFoundPoint};

    long minDistance = -1;
    for(Point &point : points) {
        long distance = point.x * point.x + point.y * point.y;
        if(minDistance == -1 || distance < minDistance) {
            result[0] = point;
            minDistance = distance;
        }
    }
    if (result[0] != unFoundPoint) {
        Point &leftTop = result[0];
        points.erase(std::remove(points.begin(), points.end(), leftTop));
        if ((pointSideLine(leftTop, points[0], points[1]) * pointSideLine(leftTop, points[0], points[2])) < 0) {
            result[2] = points[0];
        } else if ((pointSideLine(leftTop, points[1], points[0]) * pointSideLine(leftTop, points[1], points[2])) < 0) {
            result[2] = points[1];
        } else if ((pointSideLine(leftTop, points[2], points[0]) * pointSideLine(leftTop, points[2], points[1])) < 0) {
            result[2] = points[2];
        }
    }
    if (result[0] != unFoundPoint && result[2] != unFoundPoint) {
        Point &leftTop = result[0];
        Point &rightBottom = result[2];
        points.erase(std::remove(points.begin(), points.end(), rightBottom));
        if (pointSideLine(leftTop, rightBottom, points[0]) > 0) {
            result[1] = points[0];
            result[3] = points[1];
        } else {
            result[1] = points[1];
            result[3] = points[0];
        }
    }

    if (result[0] != unFoundPoint && result[1] != unFoundPoint && result[2] != unFoundPoint && result[3] != unFoundPoint) {
        return result;
    }

    return points;
}

long long pointSideLine(Point &lineP1, Point &lineP2, Point &point) {
    long x1 = lineP1.x;
    long y1 = lineP1.y;
    long x2 = lineP2.x;
    long y2 = lineP2.y;
    long x = point.x;
    long y = point.y;
    return (x - x1)*(y2 - y1) - (y - y1)*(x2 - x1);
}

//Scanner  end

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int32_t native_add(int32_t x, int32_t y) {
    cv::Mat m = cv::Mat::zeros(x, y, CV_8UC3);
    return m.rows + m.cols;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int32_t native_add3(int32_t x, int32_t y, int32_t z) {
    cv::Mat m = cv::Mat::zeros(x, y, CV_8UC3);
    return m.rows + m.cols + z;
}


extern "C" __attribute__((visibility("default"))) __attribute__((used))
void native_scan(u_int8_t *srcBitmapUint, int width, int height, int format, int *outPoint_, bool cannyScan) {
    cv::Mat srcBitmapMat;
    bitmap_to_mat(srcBitmapUint, width, height, format, srcBitmapMat);
    cv::Mat bgrData(srcBitmapMat.rows, srcBitmapMat.cols, CV_8UC3);
    cvtColor(srcBitmapMat, bgrData, COLOR_RGBA2BGR);
    //scanner::Scanner docScanner(bgrData, cannyScan);
    //std::vector<cv::Point> scanPoints = docScanner.scanPoint();
    srcBitmap = bgrData;
    canny = cannyScan;
    std::vector<cv::Point> scanPoints = scanPoint();
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
    //LOGD("navive_crop newWidth %d, newHeight %d", newWidth, newHeight);
}


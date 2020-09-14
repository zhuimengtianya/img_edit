import 'dart:math';

class CropUtils {

  static double get2PointsDistance(Point<int> p1, Point<int> p2) {
    return getPointsDistance(p1.x, p1.y, p2.x, p2.y);
  }

  static double getPointsDistance(int x1, int y1, int x2, int y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
  }

}
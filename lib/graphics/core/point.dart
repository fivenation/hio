import 'dart:math';

class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);

  Point3D add(Point3D other) => Point3D(x + other.x, y + other.y, z + other.z);

  Point3D subtract(Point3D other) => Point3D(x - other.x, y - other.y, z - other.z);

  double distanceTo(Point3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  String toString() => 'Point3D($x, $y, $z)';
}

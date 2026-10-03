/// A place on the campus. Positions are on a SIMULATED schematic grid in
/// metres (x: 0..1000, y: 0..700). They are NOT real LBRCE coordinates.
class CampusLocation {
  CampusLocation({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.risk,
    this.verifiedName = false,
    this.w = 90,
    this.h = 60,
  });

  final String id;
  String name;
  double x;
  double y;

  /// 0..10 location risk used by the severity engine.
  int risk;

  /// True when the facility name appears in public LBRCE material.
  /// Position is always simulated.
  final bool verifiedName;
  final double w;
  final double h;
}

class GeoReading {
  const GeoReading({required this.latitude, required this.longitude, required this.accuracy, required this.isReal});
  final double latitude;
  final double longitude;
  final double accuracy;

  /// false => demo placeholder, never shown as a real coordinate.
  final bool isReal;
}

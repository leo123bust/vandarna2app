import 'dart:math';
import 'package:latlong2/latlong.dart';

const kVarnaCenter = LatLng(43.2141, 27.9147);

const kNeighborhoods = <String>[
  'Приморски',
  'Одесос',
  'Владислав Варненчик',
  'Аспарухово',
  'Галата',
  'Младост',
  'Чайка',
  'Левски',
  'Бриз',
  'Изгрев',
];

const kBuildingTypes = <String>['Промишлена', 'Жилищна', 'Обществена', 'Военна', 'Здравна', 'Друга'];

/// Great-circle distance in metres.
double distanceM(LatLng a, LatLng b) {
  const r = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h = pow(sin(dLat / 2), 2) + cos(rad(a.latitude)) * cos(rad(b.latitude)) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(sqrt(h));
}

String formatKm(double meters) => '${(meters / 1000).toStringAsFixed(1)} км';

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// ~1 km grid. Used for sensitive / dangerous locations so exact coordinates are never stored.
double approxCoord(double v) => (v * 100).round() / 100;

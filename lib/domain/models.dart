import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum Safety { easy, medium, hard, dangerous }

extension SafetyX on Safety {
  String get label => const ['Лесно', 'Средно', 'Трудно', 'Опасно'][index];
  Color get color =>
      const [Color(0xFF2E9E6B), Color(0xFFE0A100), Color(0xFFE5752B), Color(0xFFD64545)][index];
}

enum VerificationStatus { pending, verified, outdated, reported }

extension VerificationX on VerificationStatus {
  String get label =>
      const ['Очаква проверка', 'Проверена', 'Информацията е остаряла', 'Докладвана'][index];
  Color get color =>
      const [Color(0xFF6B7280), Color(0xFF2E9E6B), Color(0xFFE0A100), Color(0xFFD64545)][index];
}

/// Confirmations from other users needed for the "Проверена" status.
const kVerificationsNeeded = 3;
const kOutdatedReport = 'Информацията е остаряла';
const kReportTypes = <String>[
  'Некоректна информация',
  kOutdatedReport,
  'Дубликат',
  'Неподходящо съдържание',
];

class Report {
  const Report(this.uid, this.type);
  final String uid, type;
  Map<String, dynamic> toMap() => {'uid': uid, 'type': type};
  factory Report.fromMap(Map<String, dynamic> m) => Report(m['uid'] as String, m['type'] as String);
}

class HistoryEntry {
  const HistoryEntry({required this.text, required this.authorId, required this.date});
  final String text, authorId;
  final DateTime date;
  Map<String, dynamic> toMap() =>
      {'text': text, 'authorId': authorId, 'date': date.millisecondsSinceEpoch};
  factory HistoryEntry.fromMap(Map<String, dynamic> m) => HistoryEntry(
        text: m['text'] as String,
        authorId: m['authorId'] as String,
        date: DateTime.fromMillisecondsSinceEpoch((m['date'] as num).toInt()),
      );
}

class Building {
  const Building({
    required this.id,
    required this.name,
    required this.description,
    required this.neighborhood,
    required this.address,
    required this.lat,
    required this.lng,
    required this.safety,
    required this.createdBy,
    required this.createdAt,
    this.type = 'Промишлена',
    this.period = '',
    this.approximate = false,
    this.demolished = false,
    this.photos = const [],
    this.history = const [],
    this.verifiedBy = const [],
    this.reports = const [],
    this.lastVerifiedAt,
  });

  final String id, name, description, neighborhood, address, type, period, createdBy;
  final double lat, lng;
  final bool approximate; // coordinates are rounded - exact position was never stored
  final bool demolished; // kept in the historical archive
  final Safety safety;
  final List<String> photos;
  final List<HistoryEntry> history;
  final List<String> verifiedBy;
  final List<Report> reports;
  final DateTime createdAt;
  final DateTime? lastVerifiedAt;

  LatLng get point => LatLng(lat, lng);

  VerificationStatus get status {
    final outdatedReports = reports.where((r) => r.type == kOutdatedReport).length;
    final otherReports = reports.length - outdatedReports;
    if (otherReports >= 3) return VerificationStatus.reported;
    final stale = lastVerifiedAt != null && DateTime.now().difference(lastVerifiedAt!).inDays > 365;
    if (outdatedReports >= 2 || stale) return VerificationStatus.outdated;
    if (verifiedBy.length >= kVerificationsNeeded) return VerificationStatus.verified;
    return VerificationStatus.pending;
  }

  Building copyWith({
    List<String>? photos,
    List<String>? verifiedBy,
    List<Report>? reports,
    List<HistoryEntry>? history,
    DateTime? lastVerifiedAt,
  }) =>
      Building(
        id: id,
        name: name,
        description: description,
        neighborhood: neighborhood,
        address: address,
        lat: lat,
        lng: lng,
        safety: safety,
        createdBy: createdBy,
        createdAt: createdAt,
        type: type,
        period: period,
        approximate: approximate,
        demolished: demolished,
        photos: photos ?? this.photos,
        history: history ?? this.history,
        verifiedBy: verifiedBy ?? this.verifiedBy,
        reports: reports ?? this.reports,
        lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'neighborhood': neighborhood,
        'address': address,
        'type': type,
        'period': period,
        'lat': lat,
        'lng': lng,
        'approximate': approximate,
        'demolished': demolished,
        'safety': safety.name,
        'photos': photos,
        'history': history.map((e) => e.toMap()).toList(),
        'verifiedBy': verifiedBy,
        'reports': reports.map((e) => e.toMap()).toList(),
        'createdBy': createdBy,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastVerifiedAt': lastVerifiedAt?.millisecondsSinceEpoch,
      };

  factory Building.fromMap(String id, Map<String, dynamic> m) {
    List<Map<String, dynamic>> maps(Object? v) =>
        (v as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final last = m['lastVerifiedAt'] as num?;
    return Building(
      id: id,
      name: (m['name'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      neighborhood: (m['neighborhood'] as String?) ?? '',
      address: (m['address'] as String?) ?? '',
      type: (m['type'] as String?) ?? 'Друга',
      period: (m['period'] as String?) ?? '',
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      approximate: (m['approximate'] as bool?) ?? false,
      demolished: (m['demolished'] as bool?) ?? false,
      safety: Safety.values.firstWhere((s) => s.name == m['safety'], orElse: () => Safety.medium),
      photos: List<String>.from(m['photos'] as List? ?? const []),
      history: maps(m['history']).map(HistoryEntry.fromMap).toList(),
      verifiedBy: List<String>.from(m['verifiedBy'] as List? ?? const []),
      reports: maps(m['reports']).map(Report.fromMap).toList(),
      createdBy: (m['createdBy'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(((m['createdAt'] as num?) ?? 0).toInt()),
      lastVerifiedAt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last.toInt()),
    );
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    required this.createdAt,
    this.email,
    this.photoUrl,
    this.isGuest = false,
  });
  final String uid, username;
  final String? email, photoUrl;
  final DateTime createdAt;
  final bool isGuest; // local demo profile (Firebase not configured)
}

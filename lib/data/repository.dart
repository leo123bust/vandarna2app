import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'sample_data.dart';

abstract class BuildingRepository {
  Stream<List<Building>> watchBuildings();
  Future<void> addBuilding(Building building, List<String> localPhotoPaths);
  Future<void> verify(String buildingId, String uid);
  Future<void> report(String buildingId, String uid, String type);
  Future<void> addHistory(String buildingId, HistoryEntry entry);
  Stream<Set<String>> watchFavorites(String uid);
  Future<void> setFavorite(String uid, String buildingId, bool value);
}

/// Offline demo repository (used when Firebase is not configured). Data stays on this device.
class LocalRepository implements BuildingRepository {
  LocalRepository(this._prefs) {
    final raw = _prefs.getString('local_buildings');
    _items = sampleBuildings();
    if (raw != null) {
      try {
        _items = (jsonDecode(raw) as List)
            .map((e) => Building.fromMap((e as Map)['id'] as String, Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _items = sampleBuildings();
      }
    }
    _favs = (_prefs.getStringList('favorites') ?? <String>[]).toSet();
  }

  final SharedPreferences _prefs;
  late List<Building> _items;
  late Set<String> _favs;
  final _buildingCtrl = StreamController<List<Building>>.broadcast();
  final _favCtrl = StreamController<Set<String>>.broadcast();

  Future<void> _save() async {
    final json = jsonEncode(_items.map((b) => {...b.toMap(), 'id': b.id}).toList());
    await _prefs.setString('local_buildings', json);
    _buildingCtrl.add(List.of(_items));
  }

  Future<void> _update(String id, Building Function(Building) change) async {
    _items = [for (final b in _items) b.id == id ? change(b) : b];
    await _save();
  }

  @override
  Stream<List<Building>> watchBuildings() async* {
    yield List.of(_items);
    yield* _buildingCtrl.stream;
  }

  @override
  Future<void> addBuilding(Building building, List<String> localPhotoPaths) async {
    final dir = await getApplicationDocumentsDirectory();
    final kept = <String>[];
    for (var i = 0; i < localPhotoPaths.length; i++) {
      final target = File('${dir.path}/${building.id}_$i.jpg');
      await File(localPhotoPaths[i]).copy(target.path);
      kept.add(target.path);
    }
    _items = [building.copyWith(photos: kept), ..._items];
    await _save();
  }

  @override
  Future<void> verify(String id, String uid) =>
      _update(id, (b) => b.copyWith(verifiedBy: [...b.verifiedBy, uid], lastVerifiedAt: DateTime.now()));

  @override
  Future<void> report(String id, String uid, String type) =>
      _update(id, (b) => b.copyWith(reports: [...b.reports, Report(uid, type)]));

  @override
  Future<void> addHistory(String id, HistoryEntry entry) =>
      _update(id, (b) => b.copyWith(history: [...b.history, entry]));

  @override
  Stream<Set<String>> watchFavorites(String uid) async* {
    yield Set.of(_favs);
    yield* _favCtrl.stream;
  }

  @override
  Future<void> setFavorite(String uid, String buildingId, bool value) async {
    value ? _favs.add(buildingId) : _favs.remove(buildingId);
    await _prefs.setStringList('favorites', _favs.toList());
    _favCtrl.add(Set.of(_favs));
  }
}

/// Cloud Firestore + Firebase Storage repository.
class FirebaseRepository implements BuildingRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Stream<List<Building>> watchBuildings() => _db
      .collection('buildings')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Building.fromMap(d.id, d.data())).toList());

  @override
  Future<void> addBuilding(Building building, List<String> localPhotoPaths) async {
    final urls = <String>[];
    for (var i = 0; i < localPhotoPaths.length; i++) {
      final ref = FirebaseStorage.instance.ref('buildings/${building.createdBy}/${building.id}/$i.jpg');
      await ref.putFile(File(localPhotoPaths[i]), SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    await _db.collection('buildings').doc(building.id).set(building.copyWith(photos: urls).toMap());
  }

  @override
  Future<void> verify(String id, String uid) => _db.collection('buildings').doc(id).update({
        'verifiedBy': FieldValue.arrayUnion([uid]),
        'lastVerifiedAt': DateTime.now().millisecondsSinceEpoch,
      });

  @override
  Future<void> report(String id, String uid, String type) => _db.collection('buildings').doc(id).update({
        'reports': FieldValue.arrayUnion([Report(uid, type).toMap()]),
      });

  @override
  Future<void> addHistory(String id, HistoryEntry entry) => _db.collection('buildings').doc(id).update({
        'history': FieldValue.arrayUnion([entry.toMap()]),
      });

  @override
  Stream<Set<String>> watchFavorites(String uid) => _db
      .collection('favorites')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()['buildingId'] as String).toSet());

  @override
  Future<void> setFavorite(String uid, String buildingId, bool value) {
    final doc = _db.collection('favorites').doc('${uid}_$buildingId');
    return value
        ? doc.set({'uid': uid, 'buildingId': buildingId, 'createdAt': DateTime.now().millisecondsSinceEpoch})
        : doc.delete();
  }
}

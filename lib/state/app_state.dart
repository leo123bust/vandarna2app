import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase_config.dart';
import '../core/utils.dart';
import '../data/auth_service.dart';
import '../data/location_service.dart';
import '../data/repository.dart';
import '../domain/gamification.dart';
import '../domain/models.dart';

enum SortMode { nearest, newest, name }

const kNotificationKeys = <String, String>{
  'verification': 'Обновления на проверки',
  'community': 'Отговори от общността',
  'achievements': 'Нови постижения',
  'favorites': 'Промени в любими сгради',
};

class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.firebaseReady);

  static Future<AppState> create() async {
    final prefs = await SharedPreferences.getInstance();
    final ready = await initFirebase();
    final state = AppState._(prefs, ready);
    state._init();
    return state;
  }

  final SharedPreferences _prefs;
  final bool firebaseReady;
  late final BuildingRepository _repo;
  late final AuthService _auth;
  StreamSubscription<Set<String>>? _favSub;

  // ---- state ----
  ThemeMode themeMode = ThemeMode.system;
  bool onboardingDone = false;
  int tab = 0;
  List<Building> buildings = [];
  Set<String> favoriteIds = {};
  AppUser? user;
  LatLng? myLocation;
  List<String> recents = [];
  final Map<String, bool> notifications = {};
  Building? focus; // "show on map" request

  // ---- filters ----
  Safety? safetyFilter;
  String? neighborhoodFilter;
  VerificationStatus? statusFilter;
  bool archive = false;
  SortMode sort = SortMode.nearest;

  void _init() {
    final t = _prefs.getInt('theme') ?? 0;
    themeMode = (t >= 0 && t < 3) ? ThemeMode.values[t] : ThemeMode.system;
    onboardingDone = _prefs.getBool('onboarding') ?? false;
    recents = _prefs.getStringList('recents') ?? [];
    for (final k in kNotificationKeys.keys) {
      notifications[k] = _prefs.getBool('notif_$k') ?? true;
    }

    _repo = firebaseReady ? FirebaseRepository() : LocalRepository(_prefs);
    _auth = firebaseReady ? FirebaseAuthService() : LocalAuthService();

    _repo.watchBuildings().listen((list) {
      buildings = list;
      notifyListeners();
    }, onError: (Object e) => debugPrint('buildings stream error: $e'));

    _auth.userChanges().listen((u) {
      user = u;
      _bindFavorites();
      if (u != null && !u.isGuest && notifications.values.any((v) => v)) registerForPush(u.uid);
      notifyListeners();
    });

    refreshLocation();
  }

  void _bindFavorites() {
    _favSub?.cancel();
    final u = user;
    if (u == null) {
      favoriteIds = {};
      return;
    }
    _favSub = _repo.watchFavorites(u.uid).listen((ids) {
      favoriteIds = ids;
      notifyListeners();
    }, onError: (Object e) => debugPrint('favorites stream error: $e'));
  }

  // ---- navigation / settings ----
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode m) async {
    themeMode = m;
    await _prefs.setInt('theme', m.index);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    await _prefs.setBool('onboarding', true);
    notifyListeners();
  }

  Future<void> setNotification(String key, bool value) async {
    notifications[key] = value;
    await _prefs.setBool('notif_$key', value);
    final u = user;
    if (value && firebaseReady && u != null && !u.isGuest) registerForPush(u.uid);
    notifyListeners();
  }

  void requestFocus(Building b) {
    focus = b;
    tab = 0;
    notifyListeners();
  }

  void clearFocus() {
    focus = null;
    notifyListeners();
  }

  // ---- location ----
  Future<void> refreshLocation() async {
    final p = await LocationService.current();
    if (p != null) {
      myLocation = p;
      notifyListeners();
    }
  }

  LatLng get reference => myLocation ?? kVarnaCenter;
  double distanceTo(Building b) => distanceM(reference, b.point);

  // ---- lists ----
  bool _passes(Building b) =>
      (safetyFilter == null || b.safety == safetyFilter) &&
      (neighborhoodFilter == null || b.neighborhood == neighborhoodFilter) &&
      (statusFilter == null || b.status == statusFilter);

  List<Building> _sorted(Iterable<Building> items) {
    final list = items.toList();
    switch (sort) {
      case SortMode.nearest:
        list.sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
      case SortMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  /// Catalog list (active buildings, or the historical archive).
  List<Building> get visible => _sorted(buildings.where((b) => b.demolished == archive && _passes(b)));

  /// Map markers: only existing buildings, same filters.
  List<Building> get mapBuildings => _sorted(buildings.where((b) => !b.demolished && _passes(b)));

  List<Building> get favorites => _sorted(buildings.where((b) => favoriteIds.contains(b.id)));

  List<Building> search(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return [];
    return _sorted(buildings.where((b) =>
        _passes(b) &&
        [b.name, b.neighborhood, b.address, b.description].any((f) => f.toLowerCase().contains(t))));
  }

  bool get hasFilters => safetyFilter != null || neighborhoodFilter != null || statusFilter != null;

  void setFilters({Safety? safety, String? neighborhood, VerificationStatus? status, bool clear = false}) {
    if (clear) {
      safetyFilter = null;
      neighborhoodFilter = null;
      statusFilter = null;
    } else {
      safetyFilter = safety;
      neighborhoodFilter = neighborhood;
      statusFilter = status;
    }
    notifyListeners();
  }

  void setSort(SortMode m) {
    sort = m;
    notifyListeners();
  }

  void setArchive(bool v) {
    archive = v;
    notifyListeners();
  }

  // ---- recent searches ----
  Future<void> addRecent(String q) async {
    final t = q.trim();
    if (t.length < 2) return;
    recents = [t, ...recents.where((r) => r.toLowerCase() != t.toLowerCase())].take(10).toList();
    await _prefs.setStringList('recents', recents);
    notifyListeners();
  }

  Future<void> clearRecents() async {
    recents = [];
    await _prefs.remove('recents');
    notifyListeners();
  }

  // ---- favorites ----
  bool isFavorite(String id) => favoriteIds.contains(id);

  Future<void> toggleFavorite(Building b) async {
    final u = user;
    if (u == null) return;
    await _repo.setFavorite(u.uid, b.id, !isFavorite(b.id));
  }

  // ---- community verification ----
  String? verifyBlockReason(Building b) {
    final u = user;
    if (u == null) return 'Влез в профила си, за да потвърждаваш.';
    if (b.createdBy == u.uid) return 'Не можеш да потвърждаваш собствени публикации.';
    if (b.verifiedBy.contains(u.uid)) return 'Вече си потвърдил(а) тази информация.';
    return null;
  }

  Future<void> verify(Building b) async {
    final reason = verifyBlockReason(b);
    if (reason != null) throw StateError(reason);
    await _repo.verify(b.id, user!.uid);
  }

  Future<void> report(Building b, String type) async {
    final u = user;
    if (u == null) throw StateError('Влез в профила си, за да докладваш.');
    if (b.reports.any((r) => r.uid == u.uid)) throw StateError('Вече си докладвал(а) този запис.');
    await _repo.report(b.id, u.uid, type);
  }

  Future<void> addHistory(Building b, String text) async {
    final u = user;
    if (u == null) throw StateError('Влез в профила си.');
    await _repo.addHistory(b.id, HistoryEntry(text: text.trim(), authorId: u.uid, date: DateTime.now()));
  }

  // ---- submissions ----
  /// Existing building with the same name or within 50 m (possible duplicate).
  Building? findDuplicate(String name, LatLng p) {
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    final n = norm(name);
    for (final b in buildings) {
      if (norm(b.name) == n || distanceM(b.point, p) < 50) return b;
    }
    return null;
  }

  Future<void> submitBuilding({
    required String name,
    required String description,
    required String neighborhood,
    required String address,
    required double lat,
    required double lng,
    required Safety safety,
    required String type,
    required String period,
    required String history,
    required bool hideExact,
    required bool demolished,
    required List<String> photoPaths,
  }) async {
    final u = user;
    if (u == null) throw StateError('Влез в профила си, за да добавяш сгради.');
    final since = DateTime.now().subtract(const Duration(hours: 24));
    final recent = buildings.where((b) => b.createdBy == u.uid && b.createdAt.isAfter(since)).length;
    if (recent >= 3) throw StateError('Лимит срещу спам: най-много 3 подадени сгради за 24 часа.');

    final approximate = hideExact || safety == Safety.dangerous;
    final now = DateTime.now();
    final building = Building(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description.trim(),
      neighborhood: neighborhood,
      address: address.trim(),
      lat: approximate ? approxCoord(lat) : lat,
      lng: approximate ? approxCoord(lng) : lng,
      approximate: approximate,
      demolished: demolished,
      safety: safety,
      type: type,
      period: period.trim(),
      createdBy: u.uid,
      createdAt: now,
      history: history.trim().isEmpty
          ? const []
          : [HistoryEntry(text: history.trim(), authorId: u.uid, date: now)],
    );
    await _repo.addBuilding(building, photoPaths);
  }

  // ---- profile ----
  UserStats statsFor(String uid) {
    final mine = buildings.where((b) => b.createdBy == uid);
    return UserStats(
      submitted: mine.length,
      verifiedSubmissions: mine.where((b) => b.status == VerificationStatus.verified).length,
      confirmations: buildings.where((b) => b.verifiedBy.contains(uid)).length,
      reports: buildings.where((b) => b.reports.any((r) => r.uid == uid)).length,
      historyEntries: buildings.fold<int>(0, (n, b) => n + b.history.where((h) => h.authorId == uid).length),
      favorites: favoriteIds.length,
    );
  }

  Future<void> signIn(String email, String password) => _auth.signIn(email, password);
  Future<void> register(String username, String email, String password) => _auth.register(username, email, password);
  Future<void> signInWithGoogle() => _auth.signInWithGoogle();
  Future<void> resetPassword(String email) => _auth.resetPassword(email);
  Future<void> updatePhoto(String path) => _auth.updatePhoto(path);

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

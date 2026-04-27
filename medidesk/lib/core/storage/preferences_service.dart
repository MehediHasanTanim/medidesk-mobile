import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _kLastSyncTimestamp = 'last_sync_timestamp';
  static const _kSelectedChamberId = 'selected_chamber_id';
  static const _kMedicineLastSync = 'medicine_last_sync';
  static const _kLookupLastSync = 'lookup_last_sync';
  static const _kChamberIds = 'chamber_ids';

  // --- Sync timestamps ---

  Future<void> setLastSyncTimestamp(int unixMs) =>
      _prefs.setInt(_kLastSyncTimestamp, unixMs);

  int? getLastSyncTimestamp() => _prefs.getInt(_kLastSyncTimestamp);

  Future<void> setMedicineLastSync(int unixMs) =>
      _prefs.setInt(_kMedicineLastSync, unixMs);

  int? getMedicineLastSync() => _prefs.getInt(_kMedicineLastSync);

  Future<void> setLookupLastSync(int unixMs) =>
      _prefs.setInt(_kLookupLastSync, unixMs);

  int? getLookupLastSync() => _prefs.getInt(_kLookupLastSync);

  // --- User chamber membership (set after login) ---

  Future<void> setChamberIds(List<String> ids) =>
      _prefs.setStringList(_kChamberIds, ids);

  List<String> getChamberIds() =>
      _prefs.getStringList(_kChamberIds) ?? const [];

  // --- Chamber selection ---

  Future<void> setSelectedChamberId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kSelectedChamberId);
    } else {
      await _prefs.setString(_kSelectedChamberId, id);
    }
  }

  String? getSelectedChamberId() => _prefs.getString(_kSelectedChamberId);

  // --- Clear all on logout ---

  Future<void> clearAll() => _prefs.clear();
}

import 'package:sembast/sembast.dart';
import '../models/preset.dart';

class PresetRepository {
  static const String storeName = 'presets';
  final _store = intMapStoreFactory.store(storeName);
  final Database _db;

  PresetRepository(this._db);

  Future<int> insert(Preset preset) async {
    return await _store.add(_db, preset.toMap());
  }

  Future<List<Preset>> getAll() async {
    final finder = Finder(sortOrders: [SortOrder('createdAt', false)]);
    final snapshots = await _store.find(_db, finder: finder);
    return snapshots.map((s) => Preset.fromMap(s.value, s.key)).toList();
  }

  Future<void> update(Preset preset) async {
    await _store.record(preset.id!).put(_db, preset.toMap());
  }

  Future<void> delete(int id) async {
    await _store.record(id).delete(_db);
  }
}

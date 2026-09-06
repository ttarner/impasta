import 'package:sembast/sembast.dart';
import '../baking_pan.dart';

class BakingPanRepository {
  static const String storeName = 'baking_pans';
  final _store = intMapStoreFactory.store(storeName);
  final Database _db;

  BakingPanRepository(this._db);

  Future<List<BakingPan>> getAll() async {
    final snapshots = await _store.find(_db);
    return snapshots.map((s) => BakingPan.fromMap(s.value)).toList();
  }

  Future<void> saveAll(List<BakingPan> pans) async {
    await _store.delete(_db);
    for (final pan in pans) {
      await _store.add(_db, pan.toMap());
    }
  }
}

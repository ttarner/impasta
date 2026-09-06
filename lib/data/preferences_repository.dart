import 'package:sembast/sembast.dart';

class PreferencesRepository {
  final Database _db;
  final _store = StoreRef<String, dynamic>.main();

  PreferencesRepository(this._db);

  Future<String?> getLocale() async {
    return await _store.record('locale').get(_db) as String?;
  }

  Future<void> setLocale(String locale) async {
    await _store.record('locale').put(_db, locale);
  }
}

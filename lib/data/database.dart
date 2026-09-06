import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

export 'package:sembast/sembast.dart' show Database;

Future<Database> openAppDatabase() async {
  if (kIsWeb) {
    return databaseFactoryWeb.openDatabase('impasta.db');
  } else {
    final dir = await getApplicationDocumentsDirectory();
    return databaseFactoryIo.openDatabase('${dir.path}/impasta.db');
  }
}

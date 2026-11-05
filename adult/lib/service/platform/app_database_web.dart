import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<Database> openAppDatabase(String name, OpenDatabaseOptions options) =>
    databaseFactoryFfiWebNoWebWorker.openDatabase(name, options: options);

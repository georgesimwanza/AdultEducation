import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart';

Future<Database> openAppDatabase(String name, OpenDatabaseOptions options) =>
    sqflite.databaseFactory.openDatabase(name, options: options);

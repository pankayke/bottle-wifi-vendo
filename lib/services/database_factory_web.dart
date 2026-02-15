import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web implementation — sets the databaseFactory to IndexedDB-backed FFI.
void initWebDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}

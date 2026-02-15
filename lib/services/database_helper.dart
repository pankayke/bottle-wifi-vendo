import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Conditional import: web uses IndexedDB factory, native is a no-op.
import 'database_factory_stub.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';

/// Singleton database helper for local SQLite storage.
/// Replaces the Laravel backend — all data lives on the device.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _dbVersion = 2;
  static const String _dbName = 'bottle_wifi.db';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // On web, sqflite needs an explicit factory backed by IndexedDB.
    if (kIsWeb) {
      initWebDatabaseFactory();
      return openDatabase(
        _dbName,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        credits INTEGER DEFAULT 0,
        phone_number TEXT,
        role TEXT DEFAULT 'user',
        email_verified_at TEXT,
        last_login_at TEXT,
        suspended_at TEXT,
        suspension_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE machines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mac_address TEXT DEFAULT '',
        ip_address TEXT DEFAULT '',
        status TEXT DEFAULT 'active',
        is_online INTEGER DEFAULT 1,
        last_online TEXT,
        location TEXT,
        total_bottles_processed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bottle_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        machine_id INTEGER NOT NULL,
        machine_name TEXT,
        credits_awarded INTEGER DEFAULT 0,
        image_url TEXT,
        status TEXT DEFAULT 'verified',
        timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        minutes INTEGER NOT NULL,
        status TEXT DEFAULT 'active',
        type TEXT DEFAULT 'single_use',
        user_id INTEGER,
        user_name TEXT,
        redeemed_at TEXT,
        expires_at TEXT,
        revoke_reason TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE guest_scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_fingerprint TEXT NOT NULL,
        device_info TEXT,
        machine_id INTEGER,
        credits_earned INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bottle_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        machine_id INTEGER,
        credits_earned INTEGER DEFAULT 0,
        session_type TEXT DEFAULT 'scan',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Seed default admin account
    await _seedDefaultAdmin(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bottle_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          machine_id INTEGER,
          credits_earned INTEGER DEFAULT 0,
          session_type TEXT DEFAULT 'scan',
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');
    }
  }

  /// Seed the default admin account on first launch.
  Future<void> _seedDefaultAdmin(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'name': 'Admin',
      'email': 'admin@bottlewifi.com',
      'password_hash': hashPassword('admin123'),
      'credits': 0,
      'role': 'admin',
      'created_at': now,
      'updated_at': now,
    });
    debugPrint('[DB] Default admin seeded: admin@bottlewifi.com / admin123');
  }

  // --------------- Utility helpers ---------------

  /// Hash a plain-text password with SHA-256.
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Generate a random voucher code like XXXX-XXXX-XXXX.
  static String generateVoucherCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final raw = List.generate(
      12,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return '${raw.substring(0, 4)}-${raw.substring(4, 8)}-${raw.substring(8, 12)}';
  }

  /// Convert a SQLite row map so that `is_online` (int 0/1) becomes a bool,
  /// making it compatible with `Machine.fromJson`.
  static Map<String, dynamic> machineRowToJson(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['is_online'] = (row['is_online'] as int?) == 1;
    return map;
  }

  /// Close the database (for testing / hot-restart).
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

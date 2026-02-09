import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('toko_pojok_vfinal.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2, // ⬅️ NAIKKAN VERSI DATABASE
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // CREATE DATABASE (BARU INSTALL)
  Future _createDB(Database db, int version) async {
    // TABEL USERS
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT,
        has_purchased INTEGER DEFAULT 0
      )
    ''');

    // TABEL PRODUK
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price INTEGER,
        image TEXT
      )
    ''');

    // TABEL PROFIL
    await db.execute('''
      CREATE TABLE profiles (
        username TEXT PRIMARY KEY,
        full_name TEXT,
        address TEXT
      )
    ''');
  }

  // UPGRADE DATABASE (USER LAMA)
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN has_purchased INTEGER DEFAULT 0",
      );
    }
  }

  // AUTH (LOGIN / REGISTER)
  Future<bool> register(String username, String password) async {
    final db = await instance.database;
    try {
      await db.insert('users', {
        'username': username,
        'password': password,
        'role': 'user',
        'has_purchased': 0, // USER BARU BELUM PERNAH BELI
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  // PROMO / PEMBELIAN PERTAMA
  /// CEK: apakah user masih berhak promo?
  Future<bool> isFirstPurchase(String username) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      columns: ['has_purchased'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (res.isEmpty) return false;
    return res.first['has_purchased'] == 0;
  }

  /// KUNCI PROMO: dipanggil SETELAH checkout WA
  Future<void> setPurchased(String username) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'has_purchased': 1},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // PRODUK (CRUD)
  Future<int> addProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> queryAllProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  Future<int> updateProduct(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('products', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // PROFIL USER
  Future<int> saveProfile(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'profiles',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProfile(String username) async {
    final db = await instance.database;
    final res = await db.query(
      'profiles',
      where: 'username = ?',
      whereArgs: [username],
    );
    return res.isNotEmpty ? res.first : null;
  }
}

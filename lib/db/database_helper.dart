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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabel untuk akun login
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT
      )
    ''');

    // Tabel untuk produk katalog
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price INTEGER, 
        image TEXT
      )
    ''');

    // Tabel untuk data profil pengguna
    await db.execute('''
      CREATE TABLE profiles (
        username TEXT PRIMARY KEY,
        full_name TEXT,
        address TEXT
      )
    ''');
  }

  //
  // FUNGSI UNTUK PRODUK (CRUD)
  //

  // Tambah Produk
  Future<int> addProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  // Ambil Semua Produk
  Future<List<Map<String, dynamic>>> queryAllProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // Update Produk (FUNGSI BARU)
  Future<int> updateProduct(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('products', row, where: 'id = ?', whereArgs: [id]);
  }

  // Hapus Produk
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // FUNGSI UNTUK AUTH (LOGIN/REGISTER)

  Future<bool> register(String username, String password) async {
    final db = await instance.database;
    try {
      await db.insert('users', {
        'username': username,
        'password': password,
        'role': 'user', // Default role adalah user
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

  // FUNGSI UNTUK PROFIL

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

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.savingsTable} (
          id           TEXT PRIMARY KEY,
          title        TEXT NOT NULL,
          target       REAL NOT NULL,
          saved        REAL NOT NULL DEFAULT 0,
          emoji        TEXT NOT NULL DEFAULT '🎯',
          color        INTEGER NOT NULL DEFAULT 4294967040,
          created_at   TEXT NOT NULL,
          deadline     TEXT
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.transactionsTable} (
        id           TEXT PRIMARY KEY,
        title        TEXT NOT NULL,
        amount       REAL NOT NULL,
        type         TEXT NOT NULL,
        category_id  TEXT NOT NULL,
        date         TEXT NOT NULL,
        note         TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.budgetsTable} (
        id           TEXT PRIMARY KEY,
        budget_limit REAL NOT NULL,
        spent        REAL NOT NULL DEFAULT 0,
        month        INTEGER NOT NULL,
        year         INTEGER NOT NULL,
        UNIQUE(month, year)
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.savingsTable} (
        id           TEXT PRIMARY KEY,
        title        TEXT NOT NULL,
        target       REAL NOT NULL,
        saved        REAL NOT NULL DEFAULT 0,
        emoji        TEXT NOT NULL DEFAULT '🎯',
        color        INTEGER NOT NULL DEFAULT 4294967040,
        created_at   TEXT NOT NULL,
        deadline     TEXT
      )
    ''');
  }

  // ── Savings ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllSavings() async {
    final db = await database;
    return db.query(AppConstants.savingsTable, orderBy: 'created_at DESC');
  }

  Future<void> insertSaving(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(AppConstants.savingsTable, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSaving(Map<String, dynamic> data) async {
    final db = await database;
    await db.update(AppConstants.savingsTable, data,
        where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> deleteSaving(String id) async {
    final db = await database;
    await db.delete(AppConstants.savingsTable,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addToSaved(String id, double amount) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ${AppConstants.savingsTable} SET saved = saved + ? WHERE id = ?',
      [amount, id],
    );
  }

  // ── Transactions ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTransactionsByMonth(
      int month, int year) async {
    final db = await database;
    return db.query(
      AppConstants.transactionsTable,
      where: "strftime('%m', date) = ? AND strftime('%Y', date) = ?",
      whereArgs: [
        month.toString().padLeft(2, '0'),
        year.toString(),
      ],
      orderBy: 'date DESC',
    );
  }

  Future<void> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(AppConstants.transactionsTable, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTransaction(Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      AppConstants.transactionsTable,
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalByType(
      String type, int month, int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM ${AppConstants.transactionsTable}
      WHERE type = ?
        AND strftime('%m', date) = ?
        AND strftime('%Y', date) = ?
    ''', [
      type,
      month.toString().padLeft(2, '0'),
      year.toString(),
    ]);
    return (result.first['total'] as num).toDouble();
  }

  // ── Carryover ─────────────────────────────────────────────
  // Returns net balance of ALL transactions strictly before the given month/year
  Future<double> getCarryover(int month, int year) async {
    final db = await database;
    // Build a date cutoff: first day of the selected month
    final cutoff =
        '${year.toString()}-${month.toString().padLeft(2, '0')}-01';
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
        AS carryover
      FROM ${AppConstants.transactionsTable}
      WHERE date < ?
    ''', [cutoff]);
    return (result.first['carryover'] as num).toDouble();
  }

  // ── Budgets ───────────────────────────────────────────────
  Future<Map<String, dynamic>?> getBudgetByMonth(
      int month, int year) async {
    final db = await database;
    final result = await db.query(
      AppConstants.budgetsTable,
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> upsertBudget(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(AppConstants.budgetsTable, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBudget(int month, int year) async {
    final db = await database;
    await db.delete(
      AppConstants.budgetsTable,
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
  }

  Future<void> updateBudgetSpent(
      int month, int year, double spent) async {
    final db = await database;
    await db.update(
      AppConstants.budgetsTable,
      {'spent': spent},
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
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
    final path   = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate:  _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings (
          id         TEXT PRIMARY KEY,
          title      TEXT NOT NULL,
          target     REAL NOT NULL,
          saved      REAL NOT NULL DEFAULT 0,
          emoji      TEXT NOT NULL DEFAULT '🎯',
          color      INTEGER NOT NULL DEFAULT 4294967040,
          created_at TEXT NOT NULL,
          deadline   TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_categories (
          id    TEXT PRIMARY KEY,
          name  TEXT NOT NULL,
          emoji TEXT NOT NULL,
          color INTEGER NOT NULL,
          type  TEXT NOT NULL DEFAULT 'both'
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hidden_categories (
          id TEXT PRIMARY KEY
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS category_budgets (
          id           TEXT NOT NULL,
          budget_limit REAL NOT NULL,
          spent        REAL NOT NULL DEFAULT 0,
          month        INTEGER NOT NULL,
          year         INTEGER NOT NULL,
          PRIMARY KEY (id, month, year)
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shopping_lists (
          id         TEXT PRIMARY KEY,
          title      TEXT NOT NULL,
          emoji      TEXT NOT NULL DEFAULT '🛒',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shopping_items (
          id          TEXT PRIMARY KEY,
          list_id     TEXT NOT NULL,
          name        TEXT NOT NULL,
          quantity    TEXT,
          is_checked  INTEGER NOT NULL DEFAULT 0,
          sort_order  INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        amount      REAL NOT NULL,
        type        TEXT NOT NULL,
        category_id TEXT NOT NULL,
        date        TEXT NOT NULL,
        note        TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id           TEXT PRIMARY KEY,
        budget_limit REAL NOT NULL,
        spent        REAL NOT NULL DEFAULT 0,
        month        INTEGER NOT NULL,
        year         INTEGER NOT NULL,
        UNIQUE(month, year)
      )
    ''');
    await db.execute('''
      CREATE TABLE savings (
        id         TEXT PRIMARY KEY,
        title      TEXT NOT NULL,
        target     REAL NOT NULL,
        saved      REAL NOT NULL DEFAULT 0,
        emoji      TEXT NOT NULL DEFAULT '🎯',
        color      INTEGER NOT NULL DEFAULT 4294967040,
        created_at TEXT NOT NULL,
        deadline   TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE shopping_lists (
        id         TEXT PRIMARY KEY,
        title      TEXT NOT NULL,
        emoji      TEXT NOT NULL DEFAULT '🛒',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE shopping_items (
        id          TEXT PRIMARY KEY,
        list_id     TEXT NOT NULL,
        name        TEXT NOT NULL,
        quantity    TEXT,
        is_checked  INTEGER NOT NULL DEFAULT 0,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE category_budgets (
        id           TEXT NOT NULL,
        budget_limit REAL NOT NULL,
        spent        REAL NOT NULL DEFAULT 0,
        month        INTEGER NOT NULL,
        year         INTEGER NOT NULL,
        PRIMARY KEY (id, month, year)
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_categories (
        id    TEXT PRIMARY KEY,
        name  TEXT NOT NULL,
        emoji TEXT NOT NULL,
        color INTEGER NOT NULL,
        type  TEXT NOT NULL DEFAULT 'both'
      )
    ''');
    await db.execute('''
      CREATE TABLE hidden_categories (
        id TEXT PRIMARY KEY
      )
    ''');
  }

  // ── Custom Categories ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCustomCategories() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_categories (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        emoji TEXT NOT NULL, color INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'both'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hidden_categories (id TEXT PRIMARY KEY)
    ''');
    return db.query('custom_categories', orderBy: 'name ASC');
  }

  // ── Hidden default categories ─────────────────────────────
  Future<Set<String>> getHiddenCategoryIds() async {
    final db = await database;
    await db.execute('CREATE TABLE IF NOT EXISTS hidden_categories (id TEXT PRIMARY KEY)');
    final rows = await db.query('hidden_categories');
    return rows.map((r) => r['id'] as String).toSet();
  }

  Future<void> hideCategory(String id) async {
    final db = await database;
    await db.insert('hidden_categories', {'id': id},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unhideAllCategories() async {
    final db = await database;
    await db.delete('hidden_categories');
  }

  Future<void> insertCustomCategory(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('custom_categories', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Upsert — inserts or replaces. Used for default category overrides.
  Future<void> upsertCustomCategory(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('custom_categories', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomCategory(Map<String, dynamic> data) async {
    final db = await database;
    await db.update('custom_categories', data,
        where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> deleteCustomCategory(String id) async {
    final db = await database;
    await db.delete('custom_categories',
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Savings ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllSavings() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings (
        id         TEXT PRIMARY KEY,
        title      TEXT NOT NULL,
        target     REAL NOT NULL,
        saved      REAL NOT NULL DEFAULT 0,
        emoji      TEXT NOT NULL DEFAULT '🎯',
        color      INTEGER NOT NULL DEFAULT 4294967040,
        created_at TEXT NOT NULL,
        deadline   TEXT
      )
    ''');
    return db.query('savings', orderBy: 'created_at DESC');
  }

  Future<void> insertSaving(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('savings', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSaving(Map<String, dynamic> data) async {
    final db = await database;
    await db.update('savings', data,
        where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> deleteSaving(String id) async {
    final db = await database;
    await db.delete('savings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addToSaved(String id, double amount) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE savings SET saved = saved + ? WHERE id = ?',
      [amount, id],
    );
  }

  // ── Transactions ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTransactionsByMonth(
      int month, int year) async {
    final db = await database;
    return db.query(
      'transactions',
      where: "strftime('%m', date) = ? AND strftime('%Y', date) = ?",
      whereArgs: [month.toString().padLeft(2, '0'), year.toString()],
      orderBy: 'date DESC',
    );
  }

  Future<void> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('transactions', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyWidget();
  }

  Future<void> updateTransaction(Map<String, dynamic> data) async {
    final db = await database;
    await db.update('transactions', data,
        where: 'id = ?', whereArgs: [data['id']]);
    notifyWidget();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    notifyWidget();
  }

  Future<double> getTotalByType(String type, int month, int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE type = ?
        AND strftime('%m', date) = ?
        AND strftime('%Y', date) = ?
    ''', [type, month.toString().padLeft(2, '0'), year.toString()]);
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getCarryover(int month, int year) async {
    final db     = await database;
    final cutoff =
        '${year.toString()}-${month.toString().padLeft(2, '0')}-01';
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type='income'  THEN amount ELSE 0 END),0) -
        COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END),0)
        AS carryover
      FROM transactions WHERE date < ?
    ''', [cutoff]);
    return (result.first['carryover'] as num).toDouble();
  }

  // ── Budgets ───────────────────────────────────────────────
  Future<Map<String, dynamic>?> getBudgetByMonth(int month, int year) async {
    final db     = await database;
    final result = await db.query('budgets',
        where: 'month = ? AND year = ?', whereArgs: [month, year]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> upsertBudget(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('budgets', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBudget(int month, int year) async {
    final db = await database;
    await db.delete('budgets',
        where: 'month = ? AND year = ?', whereArgs: [month, year]);
  }

  Future<void> updateBudgetSpent(int month, int year, double spent) async {
    final db = await database;
    await db.update('budgets', {'spent': spent},
        where: 'month = ? AND year = ?', whereArgs: [month, year]);
  }

  // ── Widget notify ─────────────────────────────────────────
  static const _widgetChannel =
  MethodChannel('com.example.expense_tracker/widget');

  static Future<void> notifyWidget() async {
    try {
      await _widgetChannel.invokeMethod('updateWidget');
    } catch (_) {}
  }
  // ── Category Budgets ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCategoryBudgetsByMonth(
      int month, int year) async {
    final db = await database;
    return db.query('category_budgets',
        where: 'month = ? AND year = ?',
        whereArgs: [month, year]);
  }

  Future<void> upsertCategoryBudget(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('category_budgets', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategoryBudget(
      String id, int month, int year) async {
    final db = await database;
    await db.delete('category_budgets',
        where: 'id = ? AND month = ? AND year = ?',
        whereArgs: [id, month, year]);
  }

  Future<void> updateCategoryBudgetSpent(
      String id, int month, int year, double spent) async {
    final db = await database;
    await db.update('category_budgets',
        {'spent': spent},
        where: 'id = ? AND month = ? AND year = ?',
        whereArgs: [id, month, year]);
  }

  // ── Shopping ──────────────────────────────────────────────────────────────
  Future<List<Map<String,dynamic>>> getShoppingLists() async {
    final db = await database;
    return db.query('shopping_lists', orderBy: 'created_at DESC');
  }

  Future<void> insertShoppingList(Map<String,dynamic> data) async {
    final db = await database;
    await db.insert('shopping_lists', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteShoppingList(String id) async {
    final db = await database;
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateShoppingListTitle(
      String id, String title, String emoji) async {
    final db = await database;
    await db.update('shopping_lists',
        {'title': title, 'emoji': emoji},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String,dynamic>>> getShoppingItems(String listId) async {
    final db = await database;
    return db.query('shopping_items',
        where: 'list_id = ?', whereArgs: [listId],
        orderBy: 'sort_order ASC, rowid ASC');
  }

  Future<void> insertShoppingItem(Map<String,dynamic> data) async {
    final db = await database;
    await db.insert('shopping_items', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateShoppingItem(String id,
      {String? name, String? quantity, bool? isChecked}) async {
    final db = await database;
    final map = <String,dynamic>{};
    if (name      != null) map['name']       = name;
    if (quantity  != null) map['quantity']   = quantity;
    if (isChecked != null) map['is_checked'] = isChecked ? 1 : 0;
    if (map.isEmpty) return;
    await db.update('shopping_items', map,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteShoppingItem(String id) async {
    final db = await database;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCheckedItems(String listId) async {
    final db = await database;
    await db.delete('shopping_items',
        where: 'list_id = ? AND is_checked = 1', whereArgs: [listId]);
  }

}
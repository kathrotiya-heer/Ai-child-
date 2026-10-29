import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // ============================================================
  // DATABASE GETTER
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'safelearn.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // CREATE TABLES
  // ============================================================

  Future<void> _onCreate(Database db, int version) async {
    // ----------------------------------------------------------
    // PARENT SETTINGS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE parent_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pin TEXT NOT NULL,
        screen_time_limit INTEGER NOT NULL DEFAULT 60
      )
    ''');

    // ----------------------------------------------------------
    // CHILDREN
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE children (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // LEARNING PROGRESS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE learning_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER,
        subject TEXT NOT NULL,
        lessons_completed INTEGER NOT NULL DEFAULT 0,
        stars INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ----------------------------------------------------------
    // QUIZ SCORES
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE quiz_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // SAFETY REQUESTS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE safety_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'new',
        created_at TEXT NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // AUTH SESSION
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE auth_session (
        id INTEGER PRIMARY KEY,
        access_token TEXT NOT NULL,
        parent_id INTEGER NOT NULL,
        parent_name TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');
  }

  // ============================================================
  // DATABASE UPGRADE
  // ============================================================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ----------------------------------------------------------
    // VERSION 2
    // ----------------------------------------------------------

    if (oldVersion < 2) {
      await _ensureColumn(
        db,
        'children',
        'is_active',
        'INTEGER NOT NULL DEFAULT 0',
      );

      await _ensureColumn(
        db,
        'children',
        'created_at',
        "TEXT NOT NULL DEFAULT ''",
      );

      await _ensureColumn(db, 'learning_progress', 'child_id', 'INTEGER');

      await _ensureColumn(db, 'quiz_scores', 'child_id', 'INTEGER');

      await _ensureColumn(db, 'safety_requests', 'child_id', 'INTEGER');

      await _ensureParentTable(db);

      final children = await db.query('children', orderBy: 'id ASC');

      if (children.isNotEmpty) {
        final firstId = children.first['id'] as int;

        String createdAt = children.first['created_at'] as String? ?? '';

        if (createdAt.isEmpty) {
          createdAt = DateTime.now().toIso8601String();
        }

        await db.update(
          'children',
          {'is_active': 1, 'created_at': createdAt},
          where: 'id = ?',
          whereArgs: [firstId],
        );

        await db.update('learning_progress', {
          'child_id': firstId,
        }, where: 'child_id IS NULL');

        await db.update('quiz_scores', {
          'child_id': firstId,
        }, where: 'child_id IS NULL');

        await db.update('safety_requests', {
          'child_id': firstId,
        }, where: 'child_id IS NULL');
      }
    }

    // ----------------------------------------------------------
    // VERSION 3
    // AUTH SESSION
    // ----------------------------------------------------------

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auth_session (
          id INTEGER PRIMARY KEY,
          access_token TEXT NOT NULL,
          parent_id INTEGER NOT NULL,
          parent_name TEXT NOT NULL,
          email TEXT NOT NULL
        )
      ''');
    }

    // ----------------------------------------------------------
    // VERSION 4
    // CHILD -> PARENT RELATION
    // ----------------------------------------------------------

    if (oldVersion < 4) {
      await _ensureColumn(
        db,
        'children',
        'parent_id',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // ============================================================
  // ENSURE PARENT TABLE
  // ============================================================

  Future<void> _ensureParentTable(Database db) async {
    final tables = await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type='table'
      AND name='parent_settings'
    ''');

    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE parent_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pin TEXT NOT NULL,
          screen_time_limit INTEGER NOT NULL DEFAULT 60
        )
      ''');
    } else {
      await _ensureColumn(
        db,
        'parent_settings',
        'screen_time_limit',
        'INTEGER NOT NULL DEFAULT 60',
      );
    }
  }

  // ============================================================
  // ENSURE COLUMN
  // ============================================================

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');

    final exists = info.any((row) => row['name'] == column);

    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  // ============================================================
  // PARENT SETTINGS
  // ============================================================

  Future<Map<String, dynamic>?> getParentSettings() async {
    final db = await database;

    final rows = await db.query('parent_settings', limit: 1);

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  // ============================================================
  // CREATE PARENT PIN
  // ============================================================

  Future<void> createParentPin(String pin) async {
    final db = await database;

    final existing = await getParentSettings();

    if (existing != null) {
      return;
    }

    await db.insert('parent_settings', {'pin': pin, 'screen_time_limit': 60});
  }

  // ============================================================
  // VERIFY PARENT PIN
  // ============================================================

  Future<bool> verifyParentPin(String pin) async {
    final settings = await getParentSettings();

    if (settings == null) {
      return false;
    }

    return settings['pin'] == pin;
  }

  // ============================================================
  // UPDATE SCREEN TIME
  // ============================================================

  Future<void> updateScreenTime(int minutes) async {
    final db = await database;

    var settings = await getParentSettings();

    if (settings == null) {
      await createParentPin('1234');
      settings = await getParentSettings();
    }

    if (settings == null) {
      return;
    }

    await db.update(
      'parent_settings',
      {'screen_time_limit': minutes},
      where: 'id = ?',
      whereArgs: [settings['id']],
    );
  }

  // ============================================================
  // CREATE CHILD
  // ============================================================

  Future<int> createChild({required String name, required int age}) async {
    final db = await database;

    // Get currently logged-in user
    final session = await getAuthSession();

    if (session == null) {
      throw Exception('User is not logged in');
    }

    final parentId = session['parent_id'];

    if (parentId == null) {
      throw Exception('Parent ID not found');
    }

    // Only deactivate children of CURRENT USER
    await db.update(
      'children',
      {'is_active': 0},
      where: 'parent_id = ?',
      whereArgs: [parentId],
    );

    // Save child with current user's parent_id
    final childId = await db.insert('children', {
      'parent_id': parentId,
      'name': name,
      'age': age,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    print('CHILD SAVED -> Parent: $parentId | Child: $childId | Name: $name');

    return childId;
  }

  // ============================================================
  // GET CURRENT USER'S CHILDREN
  // ============================================================

  Future<List<Map<String, dynamic>>> getChildren() async {
    final db = await database;

    final session = await getAuthSession();

    if (session == null) {
      return [];
    }

    final parentId = session['parent_id'];

    if (parentId == null) {
      return [];
    }

    // IMPORTANT:
    // Only return children belonging to current user
    final children = await db.query(
      'children',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'created_at ASC, id ASC',
    );

    print('GET CHILDREN -> Parent: $parentId | Count: ${children.length}');

    return children;
  }

  // ============================================================
  // GET ACTIVE CHILD
  // ============================================================

  Future<Map<String, dynamic>?> getActiveChild() async {
    final db = await database;

    final session = await getAuthSession();

    if (session == null) {
      return null;
    }

    final parentId = session['parent_id'];

    if (parentId == null) {
      return null;
    }

    // First find active child of CURRENT USER
    var rows = await db.query(
      'children',
      where: 'parent_id = ? AND is_active = ?',
      whereArgs: [parentId, 1],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return rows.first;
    }

    // If no active child, get first child of CURRENT USER
    rows = await db.query(
      'children',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final id = rows.first['id'] as int;

    await setActiveChild(id);

    return rows.first;
  }

  // ============================================================
  // GET CHILD
  // ============================================================

  Future<Map<String, dynamic>?> getChild() {
    return getActiveChild();
  }

  // ============================================================
  // SET ACTIVE CHILD
  // ============================================================

  Future<void> setActiveChild(int childId) async {
    final db = await database;

    final session = await getAuthSession();

    if (session == null) {
      return;
    }

    final parentId = session['parent_id'];

    if (parentId == null) {
      return;
    }

    await db.transaction((txn) async {
      // Deactivate only current user's children
      await txn.update(
        'children',
        {'is_active': 0},
        where: 'parent_id = ?',
        whereArgs: [parentId],
      );

      // Activate only if child belongs to current user
      await txn.update(
        'children',
        {'is_active': 1},
        where: 'id = ? AND parent_id = ?',
        whereArgs: [childId, parentId],
      );
    });
  }

  // ============================================================
  // SAVE LEARNING PROGRESS
  // ============================================================

  Future<void> saveLearningProgress({
    required String subject,
    required int lessonsCompleted,
    required int stars,
  }) async {
    final db = await database;

    final child = await getActiveChild();

    if (child == null) {
      return;
    }

    final childId = child['id'] as int;

    final existing = await db.query(
      'learning_progress',
      where: 'child_id = ? AND subject = ?',
      whereArgs: [childId, subject],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('learning_progress', {
        'child_id': childId,
        'subject': subject,
        'lessons_completed': lessonsCompleted,
        'stars': stars,
      });

      return;
    }

    final row = existing.first;

    final oldLessons = (row['lessons_completed'] as int?) ?? 0;

    final oldStars = (row['stars'] as int?) ?? 0;

    await db.update(
      'learning_progress',
      {
        'lessons_completed': oldLessons + lessonsCompleted,
        'stars': oldStars + stars,
      },
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  // ============================================================
  // GET LEARNING PROGRESS
  // ============================================================

  Future<List<Map<String, dynamic>>> getLearningProgress() async {
    final db = await database;

    final child = await getActiveChild();

    if (child == null) {
      return [];
    }

    return await db.query(
      'learning_progress',
      where: 'child_id = ?',
      whereArgs: [child['id']],
      orderBy: 'id ASC',
    );
  }

  // ============================================================
  // SAVE QUIZ SCORE
  // ============================================================

  Future<void> saveQuizScore({required int score, required int total}) async {
    final db = await database;

    final child = await getActiveChild();

    if (child == null) {
      return;
    }

    await db.insert('quiz_scores', {
      'child_id': child['id'],
      'score': score,
      'total': total,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // GET QUIZ SCORES
  // ============================================================

  Future<List<Map<String, dynamic>>> getQuizScores() async {
    final db = await database;

    final child = await getActiveChild();

    if (child == null) {
      return [];
    }

    return await db.query(
      'quiz_scores',
      where: 'child_id = ?',
      whereArgs: [child['id']],
      orderBy: 'id DESC',
    );
  }

  // ============================================================
  // CREATE SAFETY REQUEST
  // ============================================================

  Future<void> createSafetyRequest({
    required String type,
    required String message,
  }) async {
    final db = await database;

    final child = await getActiveChild();

    if (child == null) {
      return;
    }

    await db.insert('safety_requests', {
      'child_id': child['id'],
      'type': type,
      'message': message,
      'status': 'new',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // GET SAFETY REQUESTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getSafetyRequests() async {
    final db = await database;

    final child = await getActiveChild();

    if (child == null) {
      return [];
    }

    return await db.query(
      'safety_requests',
      where: 'child_id = ?',
      whereArgs: [child['id']],
      orderBy: 'id DESC',
    );
  }

  // ============================================================
  // MARK SAFETY REQUEST HANDLED
  // ============================================================

  Future<void> markSafetyRequestHandled(int id) async {
    final db = await database;

    await db.update(
      'safety_requests',
      {'status': 'handled'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // SAVE AUTH SESSION
  // ============================================================

  Future<void> saveAuthSession({
    required String token,
    required int parentId,
    required String name,
    required String email,
  }) async {
    final db = await database;

    // Only one currently logged-in session
    await db.delete('auth_session');

    await db.insert('auth_session', {
      'id': 1,
      'access_token': token,
      'parent_id': parentId,
      'parent_name': name,
      'email': email,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    print('AUTH SESSION SAVED -> Parent ID: $parentId');
  }

  // ============================================================
  // GET AUTH SESSION
  // ============================================================

  Future<Map<String, dynamic>?> getAuthSession() async {
    final db = await database;

    final result = await db.query(
      'auth_session',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ============================================================
  // CLEAR AUTH SESSION
  // ============================================================

  Future<void> clearAuthSession() async {
    final db = await database;

    await db.delete('auth_session');
  }

  // ============================================================
  // CLOSE DATABASE
  // ============================================================

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

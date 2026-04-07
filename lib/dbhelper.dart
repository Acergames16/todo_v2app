import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_v2/todo.model.dart';

class DbHelper {
static Database? _db;
static String tableName = 'todo_v2';

static Future<Database> get database async {
  if(_db != null) return _db!;
  _db =await dbInit();
  return _db!;
}

static Future<Database> dbInit() async{
  final dbPath = await getDatabasesPath();
  final path = join(dbPath,'$tableName.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate:(db, version) async {
    await db.execute(
      '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isDone INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
      '''
    );
    },
  );
}
static Future<List<Todo>> fetchAll(String order) async{
  final db = await database;
  final maps = await db.query(tableName, orderBy: order);
  return maps.map((m) => Todo.fromMap(m)).toList();
}
static Future<int> insert(Todo todo) async {
  final db = await database;
  final id = await db.insert(tableName, todo.toMapInsert());
  return id;
}
static Future<int> update(Todo todo) async {
  final db = await database;
  return db.update(tableName, todo.toMapInsert(), where: 'id = ?', whereArgs: [todo.id]);
}
static Future<int> delete(int id) async {
  final db = await database;
  return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
}
}


import 'package:flutter/material.dart';
class Todo {
int? id;
String title;
bool isDone;
DateTime createdAt;

static const List<String> filters =['all','active','overdue','completed'];

Todo({this.id, required this.title, this.isDone = false, required this.createdAt});

Map<String, dynamic> toMapInsert(){
  return {
    'id': id,
    'title': title,
    'isDone': isDone ? 1 : 0,
    'createdAt': createdAt.toIso8601String()
  };
}

factory Todo.fromMap(Map<String, dynamic> map){
  return Todo(
  id: map['id'],
  title: map['title'],
  isDone: map['isDone'] == 1,
  createdAt: DateTime.parse(map['createdAt'])
  );
}

String get status {
  if(isDone) return 'Completed';
  final minutes = DateTime.now().difference(createdAt).inMinutes;
  if(minutes >= 5) return 'Overdue';
  return 'Ongoing';
}

Color get colorState {
  if (isDone) return Colors.white;
  final minutes = DateTime.now().difference(createdAt).inMinutes;
  if (minutes >= 5) {
    return Colors.red;
  } else if (minutes >= 4) {
    return Colors.orange;
  } else if (minutes >= 3) {
    return Colors.yellow;
  } else {
    return Colors.green;
  }
}

bool matchesFilter(String filter) {
  if (filter == 'all') return true;
  final minutes = DateTime.now().difference(createdAt).inMinutes;
  final isOverdue = !isDone && minutes >= 5;
  switch (filter) {
    case 'completed': return isDone;
    case 'overdue': return isOverdue;
    case 'active': return !isDone && !isOverdue;
    default: return false;
  }
}
}
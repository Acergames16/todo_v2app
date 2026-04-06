import 'dart:async';

import 'package:flutter/material.dart';
import 'package:todo_v2/todo.model.dart';
import 'package:todo_v2/dbhelper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    List<Todo> _todos =[];
    Timer? _timer;
    
    @override
    void initState(){
      super.initState();
      _loadTodos();
    }
    @override
    void dispose(){
      _timer?.cancel();
      super.dispose();
    }

    void _scheduleNextUpdate(){
      _timer?.cancel();
       Duration? soonest;

       for(final todo in _todos){
        if(todo.isDone) continue;
        
        final age = DateTime.now().difference(todo.createdAt);

        for(final threshold in[
          const Duration(seconds: 3),
          const Duration(seconds: 4),
          const Duration(seconds: 5),
        ]){
          if(age<threshold){
            final timeUntil = threshold-age;
            if(soonest == null || timeUntil< soonest){
              soonest =timeUntil;
            }
            break;
          }
        }
       }
      if(soonest == null) return;
      _timer =Timer(soonest,(){
        setState(() {});
        _scheduleNextUpdate();
      });
    }

    Future<void> _loadTodos() async {
      final todos = await DbHelper.fetchAll();
      _todos = todos;
      setState(() {});
      _scheduleNextUpdate();
    }
    Future<void> _addTodo(String title) async {
      final todo = Todo(title: title, createdAt: DateTime.now());
      await DbHelper.insert(todo);
      _loadTodos();
    }
    Future<void> _deleteTodo(int id) async {
      await DbHelper.delete(id);
      _loadTodos();
    }
    Future<void> _toggleIsDone(Todo todo) async {
      todo.isDone = !todo.isDone;
      await DbHelper.update(todo);
      _loadTodos();
    }

    Future<void> _editTodo(Todo todo) async {
      final controller = TextEditingController(text: todo.title);
      showDialog(
        context: context, 
        builder: (_) => AlertDialog(
          title: const Text('Edit Todo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Update you todo'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: (){
                if(controller.text.trim().isNotEmpty){
                  todo.title = controller.text.trim();
                  DbHelper.update(todo);
                  _loadTodos();
                  Navigator.pop(context);
                }
              }, child: const Text('Update')),
          ],

        ));
    }
    void _deleteWarning(int id){
      showDialog(
        context: context, 
        builder: (_) => AlertDialog(
          title: const Text('Are you sure you wanna delete?'),
          actions: [
            TextButton(
              onPressed:(){ 
                return Navigator.pop(context);}, 
            child: const Text ('Cancel')),
            TextButton(
              onPressed:(){ 
                _deleteTodo(id);
                Navigator.pop(context);}, 
            child: const Text ('Delete')),
          ],
        ));

    }

    Future<void> _showAddDialog() async {
      final controller = TextEditingController();
      showDialog(
        context: context, 
        builder: (_) => AlertDialog(
          title: const Text('Add Todo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Add your todo'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: (){
                if(controller.text.trim().isNotEmpty){
                  _addTodo(controller.text.trim());
                  Navigator.pop(context);
                }
              }, child: const Text('Add')),
          ],

        ));
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: false,
      ),

      body: _todos.isEmpty
      ? Center(child: Text('No Todos yet. Tap  +  to add one.'),)
      :
      ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (_, i) {
          final todo = _todos[i];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              tileColor: todo.colorState,
              onTap: () => _editTodo(todo),
              title: Text(todo.title),
              subtitle: Text(todo.status),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () => _deleteWarning(todo.id!) , icon: Icon(Icons.remove)),
                  Checkbox(value: todo.isDone, onChanged:(_) =>  _toggleIsDone(todo)),
                ],
              ),
            ),
          );
        },

        ), 
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog ,
          child: Icon(Icons.add),),
    );
  }
}
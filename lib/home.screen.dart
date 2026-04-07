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
    String _filter = 'all';
    bool _fromNewest = true;

    @override
    void initState(){
      super.initState();
      _loadTodos();}

    @override
    void dispose(){
      _timer?.cancel();
      super.dispose();}

    void _scheduleNextUpdate(){
      _timer?.cancel();
      Duration? soonest;
    
      for(final todo in _todos){
        if(todo.isDone) continue;  
        final age = DateTime.now().difference(todo.createdAt);
        for(final threshold in[
          const Duration(minutes: 3),
          const Duration(minutes: 4),
          const Duration(minutes: 5),])
          { 
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
      _timer = Timer(soonest,(){
        setState(() {});
        _scheduleNextUpdate();
      });
    }

    Future<void> _loadTodos() async {
      final todos = await DbHelper.fetchAll(_fromNewest ? 'id':'id DESC');
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
    // Future<void> _toggleIsDone(Todo todo) async {
    //   todo.isDone = !todo.isDone;
    //   await DbHelper.update(todo);
    //   _loadTodos();
    // }
    Future<void> _markAsComplete(Todo todo) async {
      todo.isDone = true;
      await DbHelper.update(todo);
      _loadTodos();
    }
    void _toggleOrder(){
      _fromNewest = !_fromNewest;
      setState(() {});
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

    void _deleteWarningDialog(int id, String title){
      showDialog(
        context: context, 
        builder: (_) => AlertDialog(
          title: Text("Are you sure you want to delete: '$title' "),
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

  List<Todo> get _filteredTodos=> _todos.where((t) => t.matchesFilter(_filter,) ).toList();

  String get messageForEmpty {
    switch(_filter){
      case 'active': return 'No active Todos yet.'; 
      case 'overdue': return 'No overdue todo!';
      case 'completed' : return 'No done todos yet';
      default: return 'No todos yet, press + to add.';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _toggleOrder , 
            icon: Text(_fromNewest ? 'Oldest to New' : 'Newest to Oldest', style: TextStyle(fontSize: 13),)),
            SizedBox(width: 16,),
        ],
        
      ),
      body: Column(
        children: [
            _buildFilterBar(),
          Expanded(
            child: _filteredTodos.isEmpty
            ? Center(child: Text(messageForEmpty),)
            : ListView.builder(
              itemCount: _filteredTodos.length,
              itemBuilder: (_, i) =>_buildCard(_filteredTodos[i]),
              ),
          ),
        ],
      ), 
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog ,
          child: Icon(Icons.add),),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: Todo.filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChoiceChip(
              label: Text(f[0].toUpperCase() + f.substring(1)),
              selected: isSelected,
              onSelected: (_) => setState(() => _filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard (Todo todo){
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
            IconButton(onPressed: () => _deleteWarningDialog(todo.id!,todo.title) , icon: Icon(Icons.delete_outline_sharp)),
            !todo.isDone  
            ?TextButton(
              onPressed: ()=>_markAsComplete(todo), 
              child:Text('Mark as Done', style: TextStyle(color: Colors.black),) )
            :Text('Finished', style: TextStyle(),)
              ],
            ),
          ),
        );
   }
}

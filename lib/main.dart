import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _toDoController = TextEditingController();

  List<Map<String, dynamic>> _todoList;
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((String data) {
      setState(() {
        _todoList = (jsonDecode(data) as List<dynamic>)
            .map((dynamic e) => e as Map<String, dynamic>)
            ?.toList();
      });
    });
  }

  bool toBoolean(String str, [bool strict]) {
    if (strict == true) {
      return str == '1' || str == 'true';
    }
    return str != '0' && str != 'false' && str != '';
  }

  void addToDo() {
    setState(() {
      final Map<String, dynamic> newToDo = <String, dynamic>{};
      newToDo['title'] = _toDoController.text;
      newToDo['checked'] = false;
      _toDoController.text = '';

      _todoList.add(newToDo);
      _saveData();
    });
  }

  Future<void> _refresh() async {
    await Future<dynamic>.delayed(const Duration(seconds: 1));

    setState(() {
      _todoList.sort((dynamic a, dynamic b) {
        if (toBoolean(a['checked'].toString()) &&
            !toBoolean(b['checked'].toString())) {
          return 1;
        } else if (!toBoolean(a['checked'].toString()) &&
            toBoolean(b['checked'].toString())) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
  }

  //Baixa o arquivo da lista
  Future<File> _getFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();

    return File('${directory.path}/data.json');
  }

  //Salva o arquivo da lista
  Future<File> _saveData() async {
    final String data = json.encode(_todoList);
    final File file = await _getFile();
    return file.writeAsString(data);
  }

  //Le os dados do arquivo
  Future<String> _readData() async {
    try {
      final File file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]['title'].toString()),
        value: toBoolean(_todoList[index]['checked'].toString()),
        secondary: CircleAvatar(
          child: Icon(toBoolean(_todoList[index]['checked'].toString())
              ? Icons.check
              : Icons.error),
        ),
        onChanged: (bool c) {
          setState(() {
            _todoList[index]['checked'] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (DismissDirection direction) {
        setState(() {
          _lastRemoved = Map<String, dynamic>.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);

          _saveData();

          final SnackBar snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos, _lastRemoved);

                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 5),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de tafefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                      labelText: 'Nova Tafera',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: const Text('ADD'),
                  onPressed: addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: _todoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

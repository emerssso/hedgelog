import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

main() => runApp(HedgelogApp());

const appName = 'Hedgelog';

class HedgelogApp extends StatelessWidget {
  const HedgelogApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      home:
          HomePage(FirestoreTaskRepository(Firestore.instance), title: appName),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage(this.taskRepository, {Key key, this.title}) : super(key: key);

  final String title;
  final TaskRepository taskRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder(
        stream: taskRepository.taskStream,
        builder: _widgetFactory,
      ),
    );
  }

  Widget _widgetFactory(BuildContext context, AsyncSnapshot snapshot) {
    if (!snapshot.hasData) return const Text('Loading...');
    return ListView.builder(
      itemCount: snapshot.data.documents.length,
      padding: const EdgeInsets.only(top: 10.0),
      itemExtent: 55.0,
      itemBuilder: (context, index) =>
          _buildListItem(context, snapshot.data.documents[index]),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot task) {
    return ListTile(
      key: ValueKey(task.documentID),
      title: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x80000000)),
          borderRadius: BorderRadius.circular(5.0),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(task['name']),
            ),
            _iconFor(task)
          ],
        ),
      ),
      onTap: () => taskRepository.checkTask(task),
      onLongPress: () => taskRepository.uncheckTask(task),
    );
  }

  Icon _iconFor(DocumentSnapshot task) {
    final isNeeded = task['nextTime']?.isBefore(DateTime.now()) ?? true;

    return Icon(
      isNeeded ? Icons.close : Icons.check,
      color: isNeeded ? Colors.red : Colors.green,
    );
  }
}

abstract class TaskRepository {
  Stream<QuerySnapshot> get taskStream;

  checkTask(DocumentSnapshot task);

  uncheckTask(DocumentSnapshot task);
}

class FirestoreTaskRepository implements TaskRepository {
  final Firestore firestore;

  FirestoreTaskRepository(this.firestore)
      : taskStream = firestore
            .collection('tasks')
            .orderBy('nextTime', descending: false)
            .snapshots();

  @override
  final Stream<QuerySnapshot> taskStream;

  @override
  checkTask(DocumentSnapshot task) {
    firestore.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(task.reference);
      await transaction.update(freshSnap.reference, {
        'nextTime': DateTime.now().add(Duration(hours: freshSnap['waitHours']))
      });
    });
  }

  @override
  uncheckTask(DocumentSnapshot task) {
    firestore.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(task.reference);
      await transaction.update(freshSnap.reference,
          {'nextTime': DateTime.now().subtract(Duration(minutes: 1))});
    });
  }
}

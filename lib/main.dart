import 'dart:async';
import 'package:async/async.dart';
import 'package:intl/intl.dart';

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
          HomePage(FirestoreRepository(Firestore.instance), title: appName),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage(this.repository, {Key key, this.title}) : super(key: key);

  final String title;
  final DataRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder(
          stream: StreamZip(
              [repository.taskStream, repository.currentTempStream]),
          builder: _taskListFactory,
        ),
    );
  }

  Widget _taskListFactory(BuildContext context, AsyncSnapshot snapshot) {
    if (!snapshot.hasData) return const Text('Loading...');

    QuerySnapshot tasks = snapshot.data[0];
    DocumentSnapshot temperatureDoc = snapshot.data[1];

    return ListView.builder(
      itemCount: tasks.documents.length + 1,
      padding: const EdgeInsets.only(top: 10.0),
      itemExtent: 55.0,
      itemBuilder: (context, index) => index == 0
          ? _buildHeader(context, temperatureDoc)
          : _buildListItem(context, tasks.documents[index - 1]),
    );
  }

  Widget _buildHeader(BuildContext context, DocumentSnapshot snapshot) =>
      ListTile(
        key: ValueKey(snapshot.documentID),
        title: Container(
          decoration: _listDecoration,
          padding: const EdgeInsets.all(12.0),
          child: Text("Current temperature "
                "(at ${_dateFormat.format(snapshot.data['time'])}): "
                "${_formatDouble(snapshot.data['temp'])}°F"),
        ),
      );

  String _formatDouble(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot task) =>
      ListTile(
        key: ValueKey(task.documentID),
        title: Container(
          decoration: _listDecoration,
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
        onTap: () => repository.checkTask(task),
        onLongPress: () => repository.uncheckTask(task),
      );

  Icon _iconFor(DocumentSnapshot task) {
    final isNeeded = task['nextTime']?.isBefore(DateTime.now()) ?? true;

    return Icon(
      isNeeded ? Icons.close : Icons.check,
      color: isNeeded ? Colors.red : Colors.green,
    );
  }

  final _listDecoration = BoxDecoration(
    border: Border.all(color: const Color(0x80000000)),
    borderRadius: BorderRadius.circular(5.0),
  );
}

abstract class DataRepository {
  Stream<QuerySnapshot> get taskStream;

  Stream<DocumentSnapshot> get currentTempStream;

  checkTask(DocumentSnapshot task);

  uncheckTask(DocumentSnapshot task);
}

class FirestoreRepository implements DataRepository {
  final Firestore firestore;

  FirestoreRepository(this.firestore)
      : taskStream = firestore
            .collection('tasks')
            .orderBy('nextTime', descending: false)
            .snapshots(),
        currentTempStream =
            firestore.document('temperatures/current').snapshots();

  @override
  final Stream<QuerySnapshot> taskStream;

  @override
  final Stream<DocumentSnapshot> currentTempStream;

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

final _dateFormat = DateFormat.Hm().addPattern("'on'").add_Md();

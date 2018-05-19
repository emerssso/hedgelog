import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {


  runApp(HedgelogApp());
}

const appName = 'Hedgelog';

class HedgelogApp extends StatelessWidget {
  const HedgelogApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      home: const HomePage(title: appName),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder(
        stream: Firestore.instance.collection('tasks').snapshots(),
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

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return ListTile(
      key: ValueKey(document.documentID),
      title: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x80000000)),
          borderRadius: BorderRadius.circular(5.0),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(document['name']),
            ),
            _iconFor(document)
          ],
        ),
      ),
      onTap: () => Firestore.instance.runTransaction((transaction) async {
            DocumentSnapshot freshSnap =
                await transaction.get(document.reference);
            await transaction.update(freshSnap.reference, {
              'nextTime':
                  DateTime.now().add(Duration(hours: freshSnap['waitHours']))
            });
          }),
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

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DataRepository {
  Stream<QuerySnapshot> get taskStream;

  Stream<DocumentSnapshot> get currentTempStream;

  Stream<QuerySnapshot> get alertStream;

  checkTask(DocumentSnapshot task);

  uncheckTask(DocumentSnapshot task);

  deleteAlert(DocumentSnapshot alert);
}

class FirestoreRepository implements DataRepository {
  final Firestore firestore;

  FirestoreRepository(this.firestore)
      : taskStream = firestore
            .collection('tasks')
            .orderBy('nextTime', descending: false)
            .snapshots(),
        currentTempStream =
            firestore.document('temperatures/current').snapshots(),
        alertStream = firestore
            .collection('alerts')
            .orderBy('start', descending: true)
            .snapshots();

  @override
  final Stream<QuerySnapshot> taskStream;

  @override
  final Stream<DocumentSnapshot> currentTempStream;

  @override
  final Stream<QuerySnapshot> alertStream;

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

  @override
  deleteAlert(DocumentSnapshot alert) {
    firestore.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(alert.reference);
      await transaction.delete(freshSnap.reference);
    });
  }
}
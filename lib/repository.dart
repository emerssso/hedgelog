import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hedgelog/sign_in.dart';

abstract class DataRepository {
  SignInBloc get signInBloc;

  Stream<DocumentSnapshot> get currentTempStream;

  Stream<QuerySnapshot> get alertStream;

  void checkTask(DocumentSnapshot task);

  void uncheckTask(DocumentSnapshot task);

  void deleteAlert(DocumentSnapshot alert);

  void clearAllAlerts();

  void requestLampOn(bool lampOn);

  void requestSendTemp();
}

class FirestoreRepository implements DataRepository {
  final Firestore firestore;
  @override
  final SignInBloc signInBloc;

  FirestoreRepository(this.firestore, this.signInBloc)
      : currentTempStream =
            firestore.document('temperatures/current').snapshots(),
        alertStream = firestore
            .collection('alerts')
            .orderBy('start', descending: true)
            .snapshots();

  @override
  final Stream<DocumentSnapshot> currentTempStream;

  @override
  final Stream<QuerySnapshot> alertStream;

  @override
  void checkTask(DocumentSnapshot task) {
    firestore.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(task.reference);
      await transaction.update(freshSnap.reference, {
        'nextTime': DateTime.now().add(Duration(hours: freshSnap['waitHours']))
      });
    });
  }

  @override
  void uncheckTask(DocumentSnapshot task) {
    firestore.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(task.reference);
      await transaction.update(freshSnap.reference,
          {'nextTime': DateTime.now().subtract(Duration(minutes: 1))});
    });
  }

  @override
  void deleteAlert(DocumentSnapshot alert) {
    firestore.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(alert.reference);
      await transaction.delete(freshSnap.reference);
    });
  }

  Future<void> deleteAlertById(String id) =>
      firestore.document('alerts/$id').delete();

  @override
  void clearAllAlerts() async {
    final batch = firestore.batch();

    final deadAlerts = await firestore
        .collection('alerts')
        .where('active', isEqualTo: false)
        .orderBy('start')
        .limit(500)
        .getDocuments();

    for (final alert in deadAlerts.documents) {
      batch.delete(alert.reference);
    }

    batch.commit();
  }

  @override
  void requestLampOn(bool lampOn) async {
    await firestore
        .document('commands/lamp')
        .setData({'active': true, 'target': lampOn});
  }

  @override
  void requestSendTemp() async {
    var document = firestore.document('commands/sendTemp');
    await document.setData({'active': true});
  }
}

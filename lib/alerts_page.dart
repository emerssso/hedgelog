import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hedgelog/list_tile.dart';
import 'package:hedgelog/repository.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatelessWidget {
  final DataRepository _repository;

  AlertsPage(this._repository);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _repository.alertStream,
      builder: _alertListFactory,
    );
  }

  Widget _alertListFactory(BuildContext context, AsyncSnapshot snapshot) {
    if (!snapshot.hasData) return const Text('Loading...');

    return ListView.builder(
      itemCount: snapshot.data.documents.length,
      padding: const EdgeInsets.only(top: 10.0),
      itemBuilder: (context, index) =>
          _buildListItem(snapshot.data.documents[index], context),
    );
  }

  Widget _buildListItem(DocumentSnapshot alert, BuildContext context) =>
      HedgelogListTile(
          id: alert.documentID,
          onTap: () {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      content: const Text("Do you want to delete this alert?"),
                      actions: <Widget>[
                        FlatButton(
                          child: const Text("NO"),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        FlatButton(
                            child: const Text("YES"),
                            onPressed: () {
                              _repository.deleteAlert(alert);
                              Navigator.of(context).pop();
                            })
                      ],
                    ));
          },
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: alert["active"]
                ? <Widget>[
                    Text(alert['message'], style: _alertStyle),
                    _getStartTime(alert),
                  ]
                : <Widget>[
                    Text(alert['message'], style: _secondaryTextStyle),
                    _getStartTime(alert),
                    Text(
                        alert["end"] != null
                            ? "End time: ${_dateFormat.format(alert["end"])}"
                            : "No end",
                        style: _secondaryTextStyle),
                  ],
          ));

  Text _getStartTime(DocumentSnapshot alert) => Text(
      alert["start"] != null
          ? "Start time: ${_dateFormat.format(alert["start"])}"
          : "No start",
      style: _secondaryTextStyle);
}

const _alertStyle = TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
const _secondaryTextStyle =
    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic);

final _dateFormat = DateFormat.Hm().addPattern("'on'").add_Md();

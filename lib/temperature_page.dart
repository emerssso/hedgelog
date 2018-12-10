import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hedgelog/hedgelog_icons.dart';
import 'package:hedgelog/repository.dart';
import 'package:intl/intl.dart';

class TemperaturePage extends StatelessWidget {
  final DataRepository _repository;

  TemperaturePage(this._repository);

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: _repository.currentTempStream,
        builder: _buildHeader,
      );

  Widget _buildHeader(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (!snapshot.hasData) return const Text('Loading...');

    return Container(
      alignment: AlignmentDirectional.topCenter,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Icon(
                    snapshot.data.data['lamp']
                        ? HedgelogIcons.thermometer_up
                        : HedgelogIcons.thermometer_down,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "${_formatDouble(snapshot.data.data['temp'])}°F",
                  style: Theme.of(context).textTheme.title,
                ),
              ],
            ),
          ),
          Text(
            "${_dateFormat.format(snapshot.data.data['time'])}",
            style: Theme.of(context).textTheme.subtitle,
          ),
        ],
      ),
    );
  }
}

final _dateFormat = DateFormat.Hm().addPattern("'on'").add_Md();

String _formatDouble(double n) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
}

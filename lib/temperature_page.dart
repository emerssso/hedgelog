import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hedgelog/hedgelog_icons.dart';
import 'package:hedgelog/repository.dart';
import 'package:intl/intl.dart';

class TemperaturePage extends StatelessWidget {
  final DataRepository _repository;

  const TemperaturePage(this._repository);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _repository.currentTempStream,
        builder: _buildHeader,
      );
  }

  Widget _buildHeader(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    return Container(
      alignment: AlignmentDirectional.topStart,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                    '${_formatDouble(snapshot.data.data['temp'])}°F',
                    style: Theme.of(context).textTheme.title,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).primaryIconTheme.color,
                ),
                onPressed: _repository.requestSendTemp,
                padding: EdgeInsets.zero,
              )
            ],
          ),
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Text(
              '${_dateFormat.format(snapshot.data.data['time'])}',
              style: Theme.of(context).textTheme.subtitle,
            ),
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Heat lamp', style: Theme.of(context).textTheme.title),
              Switch(
                value: snapshot.data.data['lamp'],
                onChanged: _heatLampEnabled(snapshot.data.data['temp'])
                    ? _repository.requestLampOn
                    : null,
              )
            ],
          ),
        ],
      ),
    );
  }

  bool _heatLampEnabled(double temp) => temp >= 75 && temp <= 78;
}

final _dateFormat = DateFormat.Hm().addPattern('\'on\'').add_Md();

String _formatDouble(double n) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
}

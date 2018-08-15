import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

main() => runApp(HedgelogApp());

const appName = 'Hedgelog';

final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

class HedgelogApp extends StatelessWidget {
  const HedgelogApp();

  @override
  Widget build(BuildContext context) {
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    return MaterialApp(
      title: appName,
      home: BottomNav(),
    );
  }
}

class TasksPage extends StatelessWidget {
  TasksPage(this._repository, {Key key}) : super(key: key);

  final DataRepository _repository;

  @override
  Widget build(BuildContext context) {
    //zip.listen((_) => print("updated data!"));
    return StreamBuilder(
      stream: _repository.taskStream,
      builder: _taskListFactory,
    );
  }

  Widget _taskListFactory(BuildContext context, AsyncSnapshot snapshot) {
    if (!snapshot.hasData) return const Text('Loading...');

    return ListView.builder(
      itemCount: snapshot.data.documents.length,
      padding: const EdgeInsets.only(top: 10.0),
      itemExtent: 55.0,
      itemBuilder: (context, index) =>
          _buildListItem(snapshot.data.documents[index]),
    );
  }

  Widget _buildListItem(DocumentSnapshot task) => _buildListTile(
      id: task.documentID,
      onTap: () => _repository.checkTask(task),
      onLongPress: () => _repository.uncheckTask(task),
      content: Row(
        children: <Widget>[
          Expanded(
            child: Text(task['name']),
          ),
          _iconFor(task)
        ],
      ));

  Icon _iconFor(DocumentSnapshot task) {
    final isNeeded = task['nextTime']?.isBefore(DateTime.now()) ?? true;

    return Icon(
      isNeeded ? Icons.close : Icons.check,
      color: isNeeded ? Colors.red : Colors.green,
      size: 24.0,
    );
  }
}

// Generates a consistent list tile between pages
ListTile _buildListTile(
        {@required String id,
        @required Widget content,
        Function onTap,
        Function onLongPress}) =>
    ListTile(
      key: ValueKey(id),
      title: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x80000000)),
            borderRadius: BorderRadius.circular(5.0),
          ),
          padding: const EdgeInsets.all(10.0),
          child: content),
      onTap: onTap,
      onLongPress: onLongPress,
    );

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
      _buildListTile(
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

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        alignment: AlignmentDirectional.topCenter,
        padding: const EdgeInsets.all(12.0),
        child: Text("Current temperature "
            "(at ${_dateFormat.format(snapshot.data.data['time'])}): "
            "${_formatDouble(snapshot.data.data['temp'])}°F"),
      ),
    );
  }

  String _formatDouble(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
  }
}

class NavigationIconView {
  NavigationIconView(
      {Widget icon,
      String title,
      Color color,
      TickerProvider vsync,
      this.builder})
      : _color = color,
        _title = title,
        item = BottomNavigationBarItem(
          icon: icon,
          title: Text(title),
          backgroundColor: color,
        ),
        controller = AnimationController(
          duration: kThemeAnimationDuration,
          vsync: vsync,
        ) {
    _animation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );
  }

  final Color _color;
  final String _title;
  final BottomNavigationBarItem item;
  final AnimationController controller;
  final WidgetFactory builder;
  CurvedAnimation _animation;

  FadeTransition transition(
      BottomNavigationBarType type, BuildContext context) {
    Color iconColor;
    if (type == BottomNavigationBarType.shifting) {
      iconColor = _color;
    } else {
      final ThemeData themeData = Theme.of(context);
      iconColor = themeData.brightness == Brightness.light
          ? themeData.primaryColor
          : themeData.accentColor;
    }

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.02), // Slightly down.
          end: Offset.zero,
        ).animate(_animation),
        child: IconTheme(
          data: IconThemeData(
            color: iconColor,
            size: 120.0,
          ),
          child: Semantics(
            label: 'Placeholder for $_title tab',
            child: builder(),
          ),
        ),
      ),
    );
  }
}

class BottomNav extends StatefulWidget {
  @override
  _BottomNavState createState() => _BottomNavState();
}

typedef Widget WidgetFactory();

class _BottomNavState extends State<BottomNav>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<NavigationIconView> _navigationViews;

  @override
  void initState() {
    super.initState();

    _navigationViews = <NavigationIconView>[
      NavigationIconView(
          icon: const Icon(Icons.view_list),
          title: 'Tasks',
          color: Colors.blue,
          vsync: this,
          builder: () => TasksPage(FirestoreRepository(Firestore.instance))),
      NavigationIconView(
          icon: const Icon(Icons.warning),
          title: 'Alerts',
          color: Colors.purple,
          vsync: this,
          builder: () => AlertsPage(FirestoreRepository(Firestore.instance))),
      NavigationIconView(
          icon: const Icon(Icons.whatshot),
          title: 'Temperature',
          color: Colors.red,
          vsync: this,
          builder: () =>
              TemperaturePage(FirestoreRepository(Firestore.instance))),
    ];

    for (NavigationIconView view in _navigationViews)
      view.controller.addListener(_rebuild);

    _navigationViews[_currentIndex].controller.value = 1.0;
  }

  @override
  void dispose() {
    for (NavigationIconView view in _navigationViews) view.controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    setState(() {
      // Rebuild in order to animate views.
    });
  }

  Widget _buildTransitionsStack() {
    final List<FadeTransition> transitions = <FadeTransition>[];

    for (NavigationIconView view in _navigationViews)
      transitions
          .add(view.transition(BottomNavigationBarType.shifting, context));

    // We want to have the newly animating (fading in) views on top.
    transitions.sort((FadeTransition a, FadeTransition b) {
      final Animation<double> aAnimation = a.opacity;
      final Animation<double> bAnimation = b.opacity;
      final double aValue = aAnimation.value;
      final double bValue = bAnimation.value;
      return aValue.compareTo(bValue);
    });

    return Stack(children: transitions);
  }

  @override
  Widget build(BuildContext context) {
    final BottomNavigationBar botNavBar = BottomNavigationBar(
      items: _navigationViews
          .map((NavigationIconView navigationView) => navigationView.item)
          .toList(),
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.shifting,
      onTap: (int index) {
        setState(() {
          _navigationViews[_currentIndex].controller.reverse();
          _currentIndex = index;
          _navigationViews[_currentIndex].controller.forward();
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
      ),
      body: Center(child: _buildTransitionsStack()),
      bottomNavigationBar: botNavBar,
    );
  }
}

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

final _dateFormat = DateFormat.Hm().addPattern("'on'").add_Md();

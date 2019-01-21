import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hedgelog/alerts_page.dart';
import 'package:hedgelog/hedgelog_icons.dart';
import 'package:hedgelog/repository.dart';
import 'package:hedgelog/temperature_page.dart';

main() => runApp(HedgelogApp());

const appName = 'Hedgelog';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

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

    _firebaseMessaging.subscribeToTopic("alerts");

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print("onMessage: $message");
        Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("New alert: $message.message")));
      },
    );

    var iconTheme = IconThemeData.fallback().copyWith(color: Colors.purple);
    return MaterialApp(
      title: appName,
      home: BottomNav(),
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.purple,
        buttonColor: Colors.purple,
        iconTheme: iconTheme,
        primaryIconTheme: iconTheme,
      ),
    );
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
  final Widget Function() builder;
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

class _BottomNavState extends State<BottomNav> with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<NavigationIconView> _navigationViews;
  DataRepository _repository = FirestoreRepository(Firestore.instance);

  @override
  void initState() {
    super.initState();

    _navigationViews = [
      NavigationIconView(
          icon: const Icon(Icons.warning),
          title: 'Alerts',
          color: Colors.purple,
          vsync: this,
          builder: () => AlertsPage(FirestoreRepository(Firestore.instance))),
      NavigationIconView(
          icon: const Icon(HedgelogIcons.thermometer),
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
    transitions.sort((a, b) => a.opacity.value.compareTo(b.opacity.value));

    return Stack(children: transitions);
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          title: const Text(appName),
          actions: [
            IconButton(
              onPressed: () => showAlertDeleteConfirmation(context),
              icon: Icon(
                Icons.clear_all,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: Center(child: _buildTransitionsStack()),
        bottomNavigationBar: BottomNavigationBar(
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
        ),
      );

  void showAlertDeleteConfirmation(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              content: const Text("Delete ALL inactive alerts?"),
              actions: <Widget>[
                FlatButton(
                  child: const Text("NO"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FlatButton(
                    child: const Text("YES"),
                    onPressed: () {
                      _repository.clearAllAlerts();
                      Navigator.of(context).pop();
                    })
              ],
            ));
  }
}

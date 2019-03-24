import 'package:flutter/material.dart';

/// A consistent list tile between pages.
class HedgelogListTile extends StatelessWidget {
  final String id;
  final Widget content;
  final void Function() onTap;
  final void Function() onLongPress;

  const HedgelogListTile(
      {@required this.id,
      @required this.content,
      this.onTap,
      this.onLongPress});

  @override
  Widget build(BuildContext context) => ListTile(
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
}

class HedgelogProgressIndicator extends StatelessWidget {
  const HedgelogProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.purple),
      ),
    );
  }
}

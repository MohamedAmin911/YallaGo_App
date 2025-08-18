import 'package:flutter/material.dart';

import 'package:taxi_app/common/extensions.dart';

Widget buildTopUI(BuildContext context) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: KColor.bg,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 1)
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.menu,
            color: KColor.primary,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    ),
  );
}

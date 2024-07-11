import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {

  const BaseScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Base Screen')),
    );
  }
}
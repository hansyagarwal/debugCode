import 'package:flutter/material.dart';

class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key, required this.isFirstStep, required this.userId, this.inAppChangePassword = false});

  final bool isFirstStep;
  final String userId;
  final bool inAppChangePassword;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
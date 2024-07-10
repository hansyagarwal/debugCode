import 'package:flutter/material.dart';

class UIColorPair {
  final Color light;
  final Color dark;

  UIColorPair({required this.light, required this.dark});
}

class UITheme {
  final UIColorPair accentBlue;
  final UIColorPair darkBlue;
  final UIColorPair greyTwo;
  final UIColorPair red;

  UITheme({
    required this.accentBlue,
    required this.darkBlue,
    required this.greyTwo,
    required this.red,
  });

  TextStyle font({
    required double size,
    required UIColorPair colorPair,
  }) {
    return TextStyle(
      fontSize: size,
      color: colorPair.light,
    );
  }

  Color color(UIColorPair colorPair) {
    return colorPair.light;
  }
}

final uiTheme = UITheme(
  accentBlue: UIColorPair(light: Color(0xFF1E88E5), dark: Color(0xFF0D47A1)),
  darkBlue: UIColorPair(light: Color(0xFF1565C0), dark: Color(0xFF0D47A1)),
  greyTwo: UIColorPair(light: Color(0xFFBDBDBD), dark: Color(0xFF616161)),
  red: UIColorPair(light: Color(0xFFD32F2F), dark: Color(0xFFB71C1C)),
);

import 'package:flutter/material.dart';

const backgroundColor = Color.fromARGB(255, 242, 243, 226);
const cardBackgroundColor = Color.fromARGB(255, 255, 255, 255);
const mainColor = Color.fromARGB(255, 19, 79, 71); // hex equivalent #134F47
const secondaryColor =
    Color.fromARGB(255, 224, 176, 112); // hex equivalent #996A2D
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 850;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 850;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;
}
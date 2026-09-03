import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snow_growth/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const SnowGrowthApp());
}

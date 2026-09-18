import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snow_growth/app.dart';
import 'package:snow_growth/core/services/appsflyer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppsFlyer SDK
  final appsFlyerService = AppsFlyerService();
  await appsFlyerService.initSdk();
  // Optional: Set a dummy or real customer ID
  // appsFlyerService.setCustomerUserId("SOME_USER_ID");

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const SnowGrowthApp());
}

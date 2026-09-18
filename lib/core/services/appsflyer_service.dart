import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

class AppsFlyerService {
  static final AppsFlyerService _instance = AppsFlyerService._internal();

  factory AppsFlyerService() {
    return _instance;
  }

  AppsFlyerService._internal();

  late AppsflyerSdk _appsflyerSdk;

  Future<void> initSdk() async {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: 'rk5rSYHn7GfJEcS3VXXJW3',
      appId: 'com.snowgrowth.app',
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 50,
      manualStart: true,
    );

    _appsflyerSdk = AppsflyerSdk(options);

    await _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    _appsflyerSdk.startSDK(
      onSuccess: () {
        if (kDebugMode) {
          print("AppsFlyer SDK initialized successfully.");
        }
      },
      onError: (int errorCode, String errorMessage) {
        if (kDebugMode) {
          print(
            "Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage",
          );
        }
      },
    );
  }

  void setCustomerUserId(String userId) {
    _appsflyerSdk.setCustomerUserId(userId);
  }
}

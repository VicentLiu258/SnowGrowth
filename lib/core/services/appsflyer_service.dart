import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

class AppsFlyerService {
  static final AppsFlyerService _instance = AppsFlyerService._internal();

  factory AppsFlyerService() {
    return _instance;
  }

  AppsFlyerService._internal();

  AppsflyerSdk? _appsflyerSdk;

  Future<void> initSdk() async {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: 'rk5rSYHn7GfJEcS3VXXJW3',
      appId: 'com.snowgrowth.app',
      showDebug: !kReleaseMode, // 测试包(非Release模式)开启DebugLog，正式包关闭
      timeToWaitForATTUserAuthorization: 50,
      manualStart: true,
    );

    final sdk = AppsflyerSdk(options);
    _appsflyerSdk = sdk;

    await sdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    sdk.startSDK(
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
    _appsflyerSdk?.setCustomerUserId(userId);
  }

  Future<bool?> logEvent(String eventName, [Map<String, dynamic>? eventValues]) async {
    final sdk = _appsflyerSdk;
    if (sdk == null) return false;
    return sdk.logEvent(eventName, eventValues);
  }
}

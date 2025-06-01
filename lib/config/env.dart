import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/*
.env dosyasına eklenecek değerler:

FIREBASE_PROJECT_ID=petadoption-b33b9
FIREBASE_STORAGE_BUCKET=petadoption-b33b9.firebasestorage.app

WEB_API_KEY=AIzaSyApVA0DWDNeYIsTm5IcwPVdIWJya6sTENU
WEB_APP_ID=1:435395318116:web:0ffe0621986607e5eb2a71
WEB_MESSAGING_SENDER_ID=435395318116
WEB_AUTH_DOMAIN=petadoption-b33b9.firebaseapp.com
WEB_MEASUREMENT_ID=G-G2DJBYHBXT

ANDROID_API_KEY=AIzaSyBa9nrRNEm8upL2eUvygx1LU2AeQO6Hp2E
ANDROID_APP_ID=1:435395318116:android:2d7a42fdbae430bfeb2a71
ANDROID_MESSAGING_SENDER_ID=435395318116

IOS_API_KEY=AIzaSyAH7vi01j8i4isTc9TtMWUetfbM8Nd6wOg
IOS_APP_ID=1:435395318116:ios:7a8264a340ae7fdaeb2a71
IOS_MESSAGING_SENDER_ID=435395318116
IOS_CLIENT_ID=435395318116-440945imbjdg5teabs8tp27v67svcajp.apps.googleusercontent.com
IOS_BUNDLE_ID=com.example.petAdoptionMobileApp

WINDOWS_API_KEY=AIzaSyApVA0DWDNeYIsTm5IcwPVdIWJya6sTENU
WINDOWS_APP_ID=1:435395318116:web:31e4fe8cf80b4561eb2a71
WINDOWS_MESSAGING_SENDER_ID=435395318116
WINDOWS_AUTH_DOMAIN=petadoption-b33b9.firebaseapp.com
WINDOWS_MEASUREMENT_ID=G-D5SS957G38

DATA_CONNECT_SERVICE_ID=petadoptionmobileapp
DATA_CONNECT_LOCATION=us-central1
DATA_CONNECT_DATABASE=fdcdb
DATA_CONNECT_INSTANCE_ID=petadoptionmobileapp-fdc
*/

class Env {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  
  // Web configuration
  static String get webApiKey => dotenv.env['WEB_API_KEY'] ?? '';
  static String get webAppId => dotenv.env['WEB_APP_ID'] ?? '';
  static String get webMessagingSenderId => dotenv.env['WEB_MESSAGING_SENDER_ID'] ?? '';
  static String get webAuthDomain => dotenv.env['WEB_AUTH_DOMAIN'] ?? '';
  static String get webMeasurementId => dotenv.env['WEB_MEASUREMENT_ID'] ?? '';

  // Android configuration
  static String get androidApiKey => dotenv.env['ANDROID_API_KEY'] ?? '';
  static String get androidAppId => dotenv.env['ANDROID_APP_ID'] ?? '';
  static String get androidMessagingSenderId => dotenv.env['ANDROID_MESSAGING_SENDER_ID'] ?? '';

  // iOS configuration
  static String get iosApiKey => dotenv.env['IOS_API_KEY'] ?? '';
  static String get iosAppId => dotenv.env['IOS_APP_ID'] ?? '';
  static String get iosMessagingSenderId => dotenv.env['IOS_MESSAGING_SENDER_ID'] ?? '';
  static String get iosClientId => dotenv.env['IOS_CLIENT_ID'] ?? '';
  static String get iosBundleId => dotenv.env['IOS_BUNDLE_ID'] ?? '';

  // Windows configuration
  static String get windowsApiKey => dotenv.env['WINDOWS_API_KEY'] ?? '';
  static String get windowsAppId => dotenv.env['WINDOWS_APP_ID'] ?? '';
  static String get windowsMessagingSenderId => dotenv.env['WINDOWS_MESSAGING_SENDER_ID'] ?? '';
  static String get windowsAuthDomain => dotenv.env['WINDOWS_AUTH_DOMAIN'] ?? '';
  static String get windowsMeasurementId => dotenv.env['WINDOWS_MEASUREMENT_ID'] ?? '';

  // Data Connect configuration
  static String get dataConnectServiceId => dotenv.env['DATA_CONNECT_SERVICE_ID'] ?? '';
  static String get dataConnectLocation => dotenv.env['DATA_CONNECT_LOCATION'] ?? '';
  static String get dataConnectDatabase => dotenv.env['DATA_CONNECT_DATABASE'] ?? '';
  static String get dataConnectInstanceId => dotenv.env['DATA_CONNECT_INSTANCE_ID'] ?? '';
} 
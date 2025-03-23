library default_connector;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class ConnectorConfig {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  ConnectorConfig({
    required this.auth,
    required this.firestore,
  });
}

class FirebaseDataConnect {
  final ConnectorConfig config;

  FirebaseDataConnect({required this.config});
  
  // ... existing code ...
}

typedef CallerSDKType = Future<void> Function();

class DefaultConnector {


  static ConnectorConfig connectorConfig = ConnectorConfig(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );

  DefaultConnector({required this.dataConnect});
  static DefaultConnector get instance {
    return DefaultConnector(
        dataConnect: FirebaseDataConnect(
            config: connectorConfig));
  }

  FirebaseDataConnect dataConnect;
}


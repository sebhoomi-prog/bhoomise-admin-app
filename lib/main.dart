import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/bhoomise_app.dart';
import 'bloc/base/index.dart';
import 'core/push/fcm_push.dart';
import 'core/storage/hive_boxes.dart';
import 'core/storage/local_storage.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFirebaseMessaging();

  await Hive.initFlutter();
  final hiveLocal = await Hive.openBox<dynamic>(HiveBoxes.local);
  Get.put<LocalStorage>(LocalStorage(hiveLocal), permanent: true);

  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);

  runApp(const BhoomiseApp());
}

import 'package:flutter/material.dart';
import 'core/app_services.dart';
import 'app.dart'; // o donde tengas tu MaterialApp/GoRouter

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppServices.I.init();

  runApp(App());
}
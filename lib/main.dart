import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'persistence/pick_store.dart';
import 'screens/sheet_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PickrApp());
}

class PickrApp extends StatelessWidget {
  const PickrApp({super.key, this.store});

  final PickStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pickr',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SheetScreen(store: store ?? SharedPreferencesPickStore()),
    );
  }
}

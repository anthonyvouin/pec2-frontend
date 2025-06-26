import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:firstflutterapp/notifiers/theme_notifier.dart';
import 'package:firstflutterapp/theme.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  MultiProvider multiProvider = MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserNotifier()),
      ChangeNotifierProvider(create: (_) => SSEProvider()),
      ChangeNotifierProvider(create: (_) => ThemeNotifier()),
    ],
    child: const ToastificationWrapper(
      child: MyApp(),
    ),
  );

  runApp(multiProvider);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'OnlyFlick',
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.themeMode == AppThemeMode.system 
          ? ThemeMode.system 
          : (themeNotifier.themeMode == AppThemeMode.dark 
              ? ThemeMode.dark 
              : ThemeMode.light),
      routerConfig: router,
    );
  }
}


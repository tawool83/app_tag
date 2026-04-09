import 'package:flutter/material.dart';
import 'router.dart';

class AppTagApp extends StatelessWidget {
  const AppTagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppTag',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

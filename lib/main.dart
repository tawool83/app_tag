import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/di/app_providers.dart';
import 'core/di/hive_config.dart';
import 'core/di/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await initSupabase();
  runApp(
    ProviderScope(
      overrides: buildAppOverrides(),
      child: const AppTagApp(),
    ),
  );
}

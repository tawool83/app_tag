import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'services/history_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HistoryService.init();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: AppTagApp()));
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../../core/di/supabase_config.dart';
import '../../data/datasources/supabase_profile_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

final supabaseProfileDataSourceProvider =
    Provider<SupabaseProfileDataSource?>((ref) {
  if (!isSupabaseConfigured) return null;
  return SupabaseProfileDataSource(Supabase.instance.client);
});

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final ds = ref.watch(supabaseProfileDataSourceProvider);
  if (ds == null) return null;
  return ProfileRepositoryImpl(ds);
});

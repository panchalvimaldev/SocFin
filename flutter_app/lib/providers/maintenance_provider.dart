import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/maintenance_model.dart';
import '../services/api_service.dart';

final maintenanceBillsProvider =
    FutureProvider.family<List<MaintenanceBillModel>, String>((ref, societyId) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get(ApiConfig.maintenanceBills(societyId));
  return (res.data as List).map((e) => MaintenanceBillModel.fromJson(e)).toList();
});

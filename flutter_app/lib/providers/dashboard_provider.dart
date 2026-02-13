import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

final dashboardProvider =
    FutureProvider.family<DashboardModel, String>((ref, societyId) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get(ApiConfig.dashboard(societyId));
  return DashboardModel.fromJson(res.data);
});

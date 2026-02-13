import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

// ── Monthly Summary ─────────────────────────────────────
final monthlySummaryProvider = FutureProvider.family<List<MonthlySummary>, ({String societyId, int year})>(
  (ref, params) async {
    final api = ref.watch(apiServiceProvider);
    final res = await api.get(
      ApiConfig.monthlySummary(params.societyId),
      params: {'year': params.year},
    );
    return (res.data as List).map((e) => MonthlySummary.fromJson(e)).toList();
  },
);

// ── Category Spending ───────────────────────────────────
final categorySpendingProvider =
    FutureProvider.family<List<CategorySpendingModel>, ({String societyId, int year})>(
  (ref, params) async {
    final api = ref.watch(apiServiceProvider);
    final res = await api.get(
      ApiConfig.categorySpending(params.societyId),
      params: {'year': params.year},
    );
    return (res.data as List).map((e) => CategorySpendingModel.fromJson(e)).toList();
  },
);

// ── Outstanding Dues ────────────────────────────────────
final outstandingDuesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, societyId) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get(ApiConfig.outstandingDues(societyId));
  return List<Map<String, dynamic>>.from(res.data);
});

// ── Annual Summary ──────────────────────────────────────
final annualSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, ({String societyId, int year})>(
  (ref, params) async {
    final api = ref.watch(apiServiceProvider);
    final res = await api.get(
      ApiConfig.annualSummary(params.societyId),
      params: {'year': params.year},
    );
    return Map<String, dynamic>.from(res.data);
  },
);

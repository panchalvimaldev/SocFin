import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/approval_model.dart';
import '../services/api_service.dart';

final approvalsProvider =
    FutureProvider.family<List<ApprovalModel>, String>((ref, societyId) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get(ApiConfig.approvals(societyId));
  return (res.data as List).map((e) => ApprovalModel.fromJson(e)).toList();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

// ── Transaction List State ──────────────────────────────
class TransactionListState {
  final List<TransactionModel> transactions;
  final int total;
  final int page;
  final bool isLoading;
  final String? typeFilter;
  final String? categoryFilter;

  const TransactionListState({
    this.transactions = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.typeFilter,
    this.categoryFilter,
  });

  TransactionListState copyWith({
    List<TransactionModel>? transactions,
    int? total,
    int? page,
    bool? isLoading,
    String? typeFilter,
    String? categoryFilter,
  }) =>
      TransactionListState(
        transactions: transactions ?? this.transactions,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoading: isLoading ?? this.isLoading,
        typeFilter: typeFilter ?? this.typeFilter,
        categoryFilter: categoryFilter ?? this.categoryFilter,
      );
}

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final ApiService _api;
  final String _societyId;

  TransactionListNotifier(this._api, this._societyId)
      : super(const TransactionListState());

  Future<void> fetch({int page = 1, String? type, String? category}) async {
    state = state.copyWith(isLoading: true, page: page, typeFilter: type, categoryFilter: category);
    try {
      final params = <String, dynamic>{'page': page, 'limit': 20};
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (category != null && category.isNotEmpty) params['category'] = category;

      final res = await _api.get(ApiConfig.transactions(_societyId), params: params);
      final countRes = await _api.get(ApiConfig.transactionCount(_societyId), params: params);

      final txns = (res.data as List).map((e) => TransactionModel.fromJson(e)).toList();
      state = state.copyWith(
        transactions: txns,
        total: countRes.data['count'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createTransaction(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConfig.transactions(_societyId), data: data);
      await fetch(page: 1);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final transactionListProvider = StateNotifierProvider.family<
    TransactionListNotifier, TransactionListState, String>(
  (ref, societyId) {
    final api = ref.watch(apiServiceProvider);
    return TransactionListNotifier(api, societyId);
  },
);

// ── Categories Provider ─────────────────────────────────
final transactionCategoriesProvider =
    FutureProvider.family<TransactionCategories, String>((ref, societyId) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get(ApiConfig.transactionCategories(societyId));
  return TransactionCategories.fromJson(res.data);
});

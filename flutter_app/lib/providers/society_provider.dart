import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/society_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

// ── Society State ───────────────────────────────────────
class SocietyState {
  final List<SocietyModel> societies;
  final SocietyModel? current;
  final bool isLoading;

  const SocietyState({this.societies = const [], this.current, this.isLoading = false});

  String get role => current?.role ?? 'member';
  bool get isManager => current?.isManager ?? false;
  bool get isCommittee => current?.isCommittee ?? false;
  bool get canApprove => current?.canApprove ?? false;

  SocietyState copyWith({List<SocietyModel>? societies, SocietyModel? current, bool? isLoading}) =>
      SocietyState(
        societies: societies ?? this.societies,
        current: current ?? this.current,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Society Notifier ────────────────────────────────────
class SocietyNotifier extends StateNotifier<SocietyState> {
  final ApiService _api;
  final StorageService _storage;

  SocietyNotifier(this._api, this._storage) : super(const SocietyState());

  Future<void> fetchSocieties() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiConfig.societies);
      final list = (res.data as List).map((e) => SocietyModel.fromJson(e)).toList();
      state = state.copyWith(societies: list, isLoading: false);

      // Restore stored society or auto-select first
      final stored = await _storage.getSociety();
      if (stored != null) {
        final found = list.where((s) => s.id == stored['id']);
        if (found.isNotEmpty) {
          state = state.copyWith(current: found.first);
          return;
        }
      }
      if (list.length == 1) {
        selectSociety(list.first);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectSociety(SocietyModel society) {
    state = state.copyWith(current: society);
    _storage.saveSociety({
      'id': society.id,
      'name': society.name,
      'role': society.role,
    });
  }

  void clear() {
    state = const SocietyState();
  }
}

// ── Provider ────────────────────────────────────────────
final societyProvider = StateNotifierProvider<SocietyNotifier, SocietyState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return SocietyNotifier(api, storage);
});

// ── Members Provider ────────────────────────────────────
final membersProvider =
    FutureProvider.family<List<MembershipModel>, String>((ref, societyId) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get(ApiConfig.members(societyId));
  return (res.data as List).map((e) => MembershipModel.fromJson(e)).toList();
});

// ── Flats Provider ──────────────────────────────────────
final flatsProvider =
    FutureProvider.family<List<FlatModel>, String>((ref, societyId) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get(ApiConfig.flats(societyId));
  return (res.data as List).map((e) => FlatModel.fromJson(e)).toList();
});

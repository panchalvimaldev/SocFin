import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// ── Auth State ──────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.token, this.isLoading = false, this.error});

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({UserModel? user, String? token, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        token: token ?? this.token,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Auth Notifier ───────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final StorageService _storage;

  AuthNotifier(this._api, this._storage) : super(const AuthState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final token = await _storage.getToken();
    final userData = await _storage.getUser();
    if (token != null && userData != null) {
      state = AuthState(token: token, user: UserModel.fromJson(userData));
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post(ApiConfig.login, data: {
        'email': email,
        'password': password,
      });
      final authRes = AuthResponse.fromJson(res.data);
      await _storage.saveToken(authRes.accessToken);
      await _storage.saveUser(authRes.user.toJson());
      state = AuthState(token: authRes.accessToken, user: authRes.user);
      return true;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post(ApiConfig.register, data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      });
      final authRes = AuthResponse.fromJson(res.data);
      await _storage.saveToken(authRes.accessToken);
      await _storage.saveUser(authRes.user.toJson());
      state = AuthState(token: authRes.accessToken, user: authRes.user);
      return true;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      try {
        // DioException
        final dynamic dioErr = e;
        return dioErr.response?.data?['detail']?.toString() ?? 'Something went wrong';
      } catch (_) {}
    }
    return 'Something went wrong';
  }
}

// ── Provider ────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(api, storage);
});

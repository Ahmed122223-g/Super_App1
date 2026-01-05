import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'dart:js' as js;

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? userType;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.userType,
    this.errorMessage,
  });
  
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    String? userType,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      userType: userType ?? this.userType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  
  AuthNotifier(this._storage) : super(const AuthState()) {
    // Register global logout callback for 401 Unauthorized
    ApiService().onUnauthorized = () {
      if (state.status == AuthStatus.authenticated) {
        logout();
      }
    };
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userType = await _storage.read(key: 'user_type');
      
      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          userType: userType,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loginSuccess(String token, String userType) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_type', value: userType);
    
    state = state.copyWith(
      status: AuthStatus.authenticated,
      token: token,
      userType: userType,
    );
  }
  
  Future<void> logout() async {
    await _storage.write(key: 'auth_token', value: '');
    await _storage.write(key: 'user_type', value: '');
    
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_type');
    
    await ApiService().clearToken();
    
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      token: null,
      userType: null,
    );
    
    try {
      js.context['localStorage'].callMethod('clear');
      js.context['sessionStorage'].callMethod('clear');
    } catch (e) {
      print('Could not clear storage: $e');
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      js.context['location'].callMethod('reload');
    } catch (e) {
      print('Could not reload page: $e');
    }
  }
}

// Global providers
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});

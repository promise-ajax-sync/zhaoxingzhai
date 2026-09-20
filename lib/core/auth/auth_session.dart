import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_backend_config.dart';
import 'package:zhaoxingzhai/core/auth/session_token_store.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.emailVerified = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    emailVerified: json['emailVerified'] as bool? ?? false,
  );

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool emailVerified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (displayName != null) 'displayName': displayName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'emailVerified': emailVerified,
  };
}

class AuthSession extends ChangeNotifier {
  AuthSession({
    required http.Client client,
    AiBackendConfig? config,
    Future<SharedPreferences> Function()? preferencesFactory,
    SessionTokenStore? tokenStore,
  }) : _client = _retainClient(client),
       _config = config ?? AiBackendConfig.fromEnvironment(),
       _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance,
       _tokenStore = tokenStore ?? const SecureSessionTokenStore();

  static const _accessTokenKey = 'zhaoxingzhai.auth.access_token.v1';
  static const _refreshTokenKey = 'zhaoxingzhai.auth.refresh_token.v1';
  static const _accessExpiresAtKey = 'zhaoxingzhai.auth.access_expires_at.v1';
  static const _userKey = 'zhaoxingzhai.auth.user.v1';
  static const deviceIdKey = 'zhaoxingzhai.anonymous_device_id.v1';

  static http.Client _retainClient(http.Client value) => value;

  final http.Client _client;
  final AiBackendConfig _config;
  final Future<SharedPreferences> Function() _preferencesFactory;
  final SessionTokenStore _tokenStore;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessExpiresAt;
  AuthUser? _user;
  bool _busy = false;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isSignedIn => _user != null && _accessToken != null;
  bool get busy => _busy;

  Uri _uri(String path) => _config.interpretUri.replace(path: path);

  Future<void> restore() async {
    final preferences = await _preferencesFactory();
    _accessToken = await _tokenStore.read(_accessTokenKey);
    _refreshToken = await _tokenStore.read(_refreshTokenKey);
    _accessExpiresAt = DateTime.tryParse(
      await _tokenStore.read(_accessExpiresAtKey) ?? '',
    );
    if (_accessToken == null &&
        preferences.getString(_accessTokenKey) != null) {
      _accessToken = preferences.getString(_accessTokenKey);
      _refreshToken = preferences.getString(_refreshTokenKey);
      _accessExpiresAt = DateTime.tryParse(
        preferences.getString(_accessExpiresAtKey) ?? '',
      );
      if (_accessToken != null) {
        await _tokenStore.write(_accessTokenKey, _accessToken!);
      }
      if (_refreshToken != null) {
        await _tokenStore.write(_refreshTokenKey, _refreshToken!);
      }
      if (_accessExpiresAt != null) {
        await _tokenStore.write(
          _accessExpiresAtKey,
          _accessExpiresAt!.toIso8601String(),
        );
      }
      await preferences.remove(_accessTokenKey);
      await preferences.remove(_refreshTokenKey);
      await preferences.remove(_accessExpiresAtKey);
    }
    final rawUser = preferences.getString(_userKey);
    if (rawUser != null) {
      try {
        _user = AuthUser.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawUser) as Map),
        );
      } catch (_) {
        await _clear();
      }
    }
    if (_accessToken == null || _refreshToken == null || _user == null) {
      await _clear();
    }
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) => _authenticate('/api/v1/auth/register', {
    'email': email,
    'password': password,
    if (displayName?.trim().isNotEmpty ?? false)
      'displayName': displayName!.trim(),
  });

  Future<void> login({required String email, required String password}) =>
      _authenticate('/api/v1/auth/login', {
        'email': email,
        'password': password,
      });

  Future<void> _authenticate(String path, Map<String, dynamic> payload) async {
    _setBusy(true);
    try {
      final response = await _client.post(
        _uri(path),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-ID': await deviceId(_preferencesFactory),
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(_errorMessage(response));
      }
      await _acceptTokens(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    final refreshToken = _refreshToken;
    if (refreshToken != null) {
      try {
        await _client.post(
          _uri('/api/v1/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      } catch (_) {
        // Local logout must still succeed when the backend is unavailable.
      }
    }
    await _clear();
    notifyListeners();
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    final token = await accessTokenForRequest();
    if (token == null) throw StateError('请先登录');
    _setBusy(true);
    try {
      final response = await _client.patch(
        _uri('/api/v1/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (displayName != null) 'displayName': displayName.trim(),
          if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(_errorMessage(response));
      }
      _user = AuthUser.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map,
        ),
      );
      final preferences = await _preferencesFactory();
      await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final token = await accessTokenForRequest();
    if (token == null) throw StateError('请先登录');
    if (bytes.isEmpty) throw StateError('头像文件不能为空');
    _setBusy(true);
    try {
      final request = http.MultipartRequest('POST', _uri('/api/v1/auth/avatar'))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes('avatar', bytes, filename: filename),
        );
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(_errorMessage(response));
      }
      _user = AuthUser.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map,
        ),
      );
      final preferences = await _preferencesFactory();
      await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await accessTokenForRequest();
    if (token == null) throw StateError('请先登录');
    _setBusy(true);
    try {
      final response = await _client.post(
        _uri('/api/v1/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode != 204) {
        throw StateError(_errorMessage(response));
      }
      await _clear();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> deleteAccount({required String password}) async {
    final token = await accessTokenForRequest();
    if (token == null) throw StateError('请先登录');
    _setBusy(true);
    try {
      final response = await _client.delete(
        _uri('/api/v1/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password, 'confirmation': 'DELETE'}),
      );
      if (response.statusCode != 204) {
        throw StateError(_errorMessage(response));
      }
      await _clear();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> requestEmailVerification() async {
    final token = await accessTokenForRequest();
    if (token == null) throw StateError('请先登录');
    final response = await _client.post(
      _uri('/api/v1/auth/request-email-verification'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessage(response));
    }
    final json = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map,
    );
    return json['developmentToken'] as String?;
  }

  Future<void> confirmEmail(String verificationToken) async {
    final token = await accessTokenForRequest();
    if (token == null) throw StateError('请先登录');
    final response = await _client.post(
      _uri('/api/v1/auth/confirm-email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'token': verificationToken.trim()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessage(response));
    }
    _user = AuthUser.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map,
      ),
    );
    final preferences = await _preferencesFactory();
    await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<String?> requestPasswordReset(String email) async {
    final response = await _client.post(
      _uri('/api/v1/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessage(response));
    }
    final json = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map,
    );
    return json['developmentToken'] as String?;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': resetToken.trim(),
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 204) {
      throw StateError(_errorMessage(response));
    }
  }

  Future<String?> accessTokenForRequest() async {
    if (_accessToken == null || _refreshToken == null) return null;
    final expiresAt = _accessExpiresAt;
    if (expiresAt == null ||
        expiresAt.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 1)),
        )) {
      return _accessToken;
    }
    try {
      final response = await _client.post(
        _uri('/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _clear();
        notifyListeners();
        return null;
      }
      await _acceptTokens(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
      return _accessToken;
    } catch (_) {
      return _accessToken;
    }
  }

  Future<void> _acceptTokens(Map<String, dynamic> json) async {
    _accessToken = json['accessToken'] as String;
    _refreshToken = json['refreshToken'] as String;
    _accessExpiresAt = DateTime.parse(json['accessExpiresAt'] as String)
        .toUtc();
    _user = AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map));
    final preferences = await _preferencesFactory();
    await _tokenStore.write(_accessTokenKey, _accessToken!);
    await _tokenStore.write(_refreshTokenKey, _refreshToken!);
    await _tokenStore.write(
      _accessExpiresAtKey,
      _accessExpiresAt!.toIso8601String(),
    );
    await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> _clear() async {
    _accessToken = null;
    _refreshToken = null;
    _accessExpiresAt = null;
    _user = null;
    final preferences = await _preferencesFactory();
    await _tokenStore.delete(_accessTokenKey);
    await _tokenStore.delete(_refreshTokenKey);
    await _tokenStore.delete(_accessExpiresAtKey);
    await preferences.remove(_userKey);
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  static String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return '请求失败：HTTP ${response.statusCode}';
  }

  static Future<String> deviceId(
    Future<SharedPreferences> Function() preferencesFactory,
  ) async {
    final preferences = await preferencesFactory();
    final existing = preferences.getString(deviceIdKey);
    if (existing != null && existing.length >= 16) return existing;
    final random = Random.secure();
    final value = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await preferences.setString(deviceIdKey, value);
    return value;
  }
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const _baseUrl = 'http://10.0.2.2:8088';
  static const _authKey = 'access_token';
  static final _storage = FlutterSecureStorage();

  /// 登录接口
  static Future<void> login({
    required String username,
    required String password,
    required bool remember,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    final data = _processRestBean(resp);

    final rawExpire = data['expire'];
    late String expireIso;
    if (rawExpire is int) {
      expireIso =
          DateTime.fromMillisecondsSinceEpoch(rawExpire).toIso8601String();
    } else if (rawExpire is String) {
      expireIso = DateTime.parse(rawExpire).toIso8601String();
    } else {
      throw Exception('无法解析的过期时间格式：$rawExpire');
    }

    final authObj = jsonEncode({
      'token': data['token'],
      'expire': expireIso,
      'username': data['username'],
      'id': data['id'].toString(),
      'remember': remember,
    });

    await _storage.write(key: _authKey, value: authObj);
  }

  /// 登出接口
  static Future<void> logout() async {
    final headers = await _getAuthHeader();
    final uri = Uri.parse('$_baseUrl/auth/logout');
    final resp = await http.get(uri, headers: headers);
    _processRestBean(resp);
    await _storage.delete(key: _authKey);
  }

  /// GET 通用 (自动给 /api/** 加 token/Content-Type)
  /// 现在返回类型改为 Future<dynamic>，直接返回 RestBean.data（可能是 Map 或 List）
  static Future<dynamic> getApi(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
    final headers =
        path.startsWith('/auth/')
            ? {'Content-Type': 'application/json'}
            : await _getAuthHeader();
    final resp = await http.get(uri, headers: headers);
    return _processRestBean(resp);
  }

  /// GET（无返回 data，仅检查 code == 200）
  static Future<void> getVoid(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
    final headers =
        path.startsWith('/auth/')
            ? {'Content-Type': 'application/json'}
            : await _getAuthHeader();
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('网络错误：${resp.statusCode}');
    }
    final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    if (jsonMap['code'] != 200) {
      throw Exception('请求失败：${jsonMap['message']}');
    }
    // data 肯定是 null，直接返回
  }

  /// POST 通用 (返回 RestBean.data)
  static Future<dynamic> postApi(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers =
        path.startsWith('/auth/')
            ? {'Content-Type': 'application/json'}
            : await _getAuthHeader();
    final body = data == null ? null : jsonEncode(data);
    final resp = await http.post(uri, headers: headers, body: body);
    return _processRestBean(resp);
  }

  /// POST（无返回 data，仅检查 code == 200）
  static Future<void> postVoid(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers =
        path.startsWith('/auth/')
            ? {'Content-Type': 'application/json'}
            : await _getAuthHeader();
    final body = data == null ? null : jsonEncode(data);
    final resp = await http.post(uri, headers: headers, body: body);

    if (resp.statusCode != 200) {
      throw Exception('网络错误：${resp.statusCode}');
    }
    final jsonBody = jsonDecode(resp.body) as Map<String, dynamic>;
    if (jsonBody['code'] != 200) {
      throw Exception('操作失败：${jsonBody['message']}');
    }
    // data 肯定是 null，直接返回
  }

  /// 组装带 token 的 header，并验证过期时间
  static Future<Map<String, String>> _getAuthHeader() async {
    final raw = await _storage.read(key: _authKey);
    if (raw == null) return {'Content-Type': 'application/json'};

    final obj = jsonDecode(raw) as Map<String, dynamic>;
    final expire = DateTime.parse(obj['expire'] as String);
    if (expire.isBefore(DateTime.now())) {
      await _storage.delete(key: _authKey);
      throw Exception('登录已过期，请重新登录');
    }
    return {
      'Authorization': 'Bearer ${obj['token']}',
      'Content-Type': 'application/json',
    };
  }

  /// 统一解析后端 RestBean<T>
  /// 现在返回值不做强制 Map<String,dynamic> 转换，而是直接把 data 原样返回
  static dynamic _processRestBean(http.Response resp) {
    if (resp.statusCode != 200) {
      throw Exception('网络错误：${resp.statusCode}');
    }
    final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    if (jsonMap['code'] != 200) {
      throw Exception('请求失败：${jsonMap['message']}');
    }
    // 直接返回 data 字段（可能是 Map<String, dynamic>、也可能是 List<dynamic>、或 null）
    return jsonMap['data'];
  }

  static Future<Map<String, dynamic>> getAuthObject() async {
    final raw = await _storage.read(key: _authKey);
    if (raw == null) throw Exception('尚未登录');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// 搜索博客
  static Future<List<dynamic>> searchBlogs(String keyword, String uid) async {
    final data = await getApi(
      '/auth/search/keyword',
      queryParameters: {'keyword': keyword, 'uid': uid},
    );
    return data as List<dynamic>;
  }

  /// 检查是否已关注
  static Future<bool> isFollowing(String followerId, String followedId) async {
    try {
      final data = await getApi(
        '/auth/follow/check',
        queryParameters: {'followerId': followerId, 'followedId': followedId},
      );
      return data as bool;
    } catch (e) {
      return false;
    }
  }

  /// 获取搜索历史
  static Future<List<Map<String, dynamic>>> getSearchHistory(String uid, {int limit = 10}) async {
    final data = await getApi(
      '/auth/search/history/$uid',
      queryParameters: {'limit': limit.toString()},
    );
    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// 获取热门搜索关键词
  static Future<List<Map<String, dynamic>>> getPopularKeywords(String uid) async {
    final data = await getApi('/auth/search/popular/$uid');
    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }
}

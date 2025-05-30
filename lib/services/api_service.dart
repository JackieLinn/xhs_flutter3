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

    // 处理后端返回的 expire，可能是数字(毫秒)也可能是 ISO 字符串
    final rawExpire = data['expire'];
    late String expireIso;
    if (rawExpire is int) {
      // 数字 (millis since epoch)
      expireIso =
          DateTime.fromMillisecondsSinceEpoch(rawExpire).toIso8601String();
    } else if (rawExpire is String) {
      // 字符串，假设是 ISO 8601 或者 fastjson2 默认格式
      expireIso = DateTime.parse(rawExpire).toIso8601String();
    } else {
      throw Exception('无法解析的过期时间格式：$rawExpire');
    }

    // 构造要存储的对象
    final authObj = jsonEncode({
      'token': data['token'],
      'expire': expireIso,
      'username': data['username'],
      'id': data['id'].toString(),
      'remember': remember,
    });

    // 写入 Secure Storage
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
  static Future<Map<String, dynamic>> getApi(
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

  /// 请求返回 RestBean<Void> 的 GET
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
    // 只做状态码和 code 检查，不取 data
    if (resp.statusCode != 200) {
      throw Exception('网络错误：${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['code'] != 200) {
      throw Exception('请求失败：${json['message']}');
    }
    // data 肯定是 null，直接返回 void
  }

  /// POST 通用
  static Future<Map<String, dynamic>> postApi(
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

  /// 请求返回 RestBean<Void> 的 POST
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
  static Map<String, dynamic> _processRestBean(http.Response resp) {
    if (resp.statusCode != 200) {
      throw Exception('网络错误：${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['code'] != 200) {
      throw Exception('请求失败：${json['message']}');
    }
    return json['data'] as Map<String, dynamic>;
  }
}

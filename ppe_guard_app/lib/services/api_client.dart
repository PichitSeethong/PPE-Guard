import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/server_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final instance = ApiClient._();
  static const _timeout = Duration(seconds: 15);

  String? _accessToken;

  void setAccessToken(String? value) => _accessToken = value;
  String? get accessToken => _accessToken;

  Future<dynamic> get(String path, {Map<String, String>? query, bool authenticated = true}) async {
    try {
      final response = await http.get(_uri(path, query), headers: _headers(authenticated)).timeout(_timeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('เชื่อมต่อ Server ไม่ได้ กรุณาตรวจสอบ IP, เครือข่าย และสถานะ Server');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool authenticated = true}) async {
    return _request('POST', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body, {bool authenticated = true}) async {
    return _request('PATCH', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body, bool authenticated = true}) async {
    try {
      final headers = {..._headers(authenticated), 'Content-Type': 'application/json'};
      late http.Response response;
      final uri = _uri(path);
      switch (method) {
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: jsonEncode(body ?? const {})).timeout(_timeout);
          break;
        case 'POST':
        default:
          response = await http.post(uri, headers: headers, body: jsonEncode(body ?? const {})).timeout(_timeout);
      }
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('เชื่อมต่อ Server ไม่ได้ กรุณาตรวจสอบ IP, เครือข่าย และสถานะ Server');
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ServerConfig.baseUrl}$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers(bool authenticated) {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = _accessToken;
    if (authenticated && token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      body = <String, dynamic>{};
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    final detail = body is Map ? body['detail'] : null;
    throw ApiException(detail?.toString() ?? 'Server ตอบกลับข้อผิดพลาด (${response.statusCode})', statusCode: response.statusCode);
  }

  String evidenceUrl(String path) => authenticatedUrl(path).toString();

  Uri authenticatedUrl(String path, {Map<String, String>? query}) {
    final raw = path.startsWith('http') ? Uri.parse(path) : _uri(path, query);
    final token = _accessToken;
    final parameters = <String, String>{...raw.queryParameters};
    if (token != null && token.isNotEmpty) parameters['token'] = token;
    return raw.replace(queryParameters: parameters);
  }

  Uri get dashboardSocketUri => Uri.parse('${ServerConfig.webSocketBaseUrl}/ws/dashboard').replace(queryParameters: {'token': _accessToken ?? ''});
}

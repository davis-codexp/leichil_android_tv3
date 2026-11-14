import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_storage.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;

  const ApiResponse({
    required this.statusCode,
    required this.data,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiService {
    ApiService._();
    //static const String baseUrl = 'https://leichiltv.com';
    static const String baseUrl = 'http://192.168.0.169:9999';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = token;
    }

    return headers;
  }

  static Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _headers();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      dynamic data;

      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = response.body;
        }
      }

      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
      );
    } catch (e, stackTrace) {
      debugPrint('========== API POST ERROR ==========');
      debugPrint('URL: $uri');
      debugPrint('ERROR TYPE: ${e.runtimeType}');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('====================================');

      return const ApiResponse(
        statusCode: 500,
        data: {
          'success': false,
          'message': 'Unable to connect to server',
        },
      );
    }
  }

  static Future<ApiResponse> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      debugPrint('========== API GET ==========');
      debugPrint('URL: $uri');

      final response = await http
          .get(
            uri,
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('HTTP STATUS: ${response.statusCode}');
      debugPrint('CONTENT TYPE: ${response.headers['content-type']}');
      debugPrint('=============================');

      dynamic data;

      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = response.body;
        }
      }

      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
      );
    } catch (e, stackTrace) {
      debugPrint('========== API GET ERROR ==========');
      debugPrint('URL: $uri');
      debugPrint('ERROR TYPE: ${e.runtimeType}');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('===================================');

      return const ApiResponse(
        statusCode: 500,
        data: {
          'success': false,
          'message': 'Unable to connect to server',
        },
      );
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ReverseGeocodingService {
  ReverseGeocodingService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  static const String _primaryUrl =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';

  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(_primaryUrl).replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'localityLanguage': 'en',
      });

      final request = await _httpClient.getUrl(uri).timeout(
            const Duration(seconds: 8),
          );
      final response = await request.close().timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data is Map<String, dynamic>) {
          final formatted = _extractFromPrimaryProvider(data);
          if (formatted != 'unknown') {
            return formatted;
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return 'unknown';
  }

  String _extractFromPrimaryProvider(Map<String, dynamic> data) {
    try {
      final principalSubdivision = (data['principalSubdivision'] ??
              data['city'] ??
              data['locality'] ??
              '')
          .toString();
      final county = _cleanName(principalSubdivision, ['County']);

      final admin = data['localityInfo']?['administrative'];
      String ward = '';
      String locality = '';

      if (admin is List) {
        for (final item in admin) {
          if (item is Map<String, dynamic>) {
            final name = (item['name'] ?? '').toString();
            if (ward.isEmpty &&
                RegExp(r'ward', caseSensitive: false).hasMatch(name)) {
              ward = _cleanName(name, ['Ward']);
            } else if (locality.isEmpty &&
                name != county &&
                (item['adminLevel'] ?? 0) >= 5) {
              locality = _cleanName(name, []);
            }
          }
        }
      }

      final parts = [county, locality, ward]
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      return parts.isNotEmpty ? parts.join('.') : 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  String _cleanName(String value, List<String> wordsToRemove) {
    var result = value;
    for (final word in wordsToRemove) {
      result =
          result.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }
    result = result.trim();
    if (result.isEmpty) return '';
    return result
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

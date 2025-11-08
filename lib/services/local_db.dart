import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/client.dart';

class LocalDB {
  static const _binId = '690ee3a7ae596e708f4bd148';
  static const _masterKey =
      r'$2a$10$SgT4qoOKXP6CD4u1jPEpduwi.2NbrCqV2u71AaL7mGaW.77CmNU7u';
  static const _baseUrl = 'https://api.jsonbin.io/v3/b';

  static final http.Client _httpClient = http.Client();
  static List<ClientModel> _cache = [];

  static Future<void> init() async {
    await _syncFromRemote();
  }

  static Future<void> refresh() => _syncFromRemote();

  static Future<ClientModel> addClient(
    String name,
    String mobile4g,
    String fibre,
  ) async {
    final id = _nextId();
    final model =
        ClientModel(id: id, name: name, mobile4g: mobile4g, fibre: fibre);
    final previous = List<ClientModel>.from(_cache);
    _cache.add(model);
    _sortCache();
    try {
      await _persist();
      return model;
    } catch (e) {
      _cache = previous;
      rethrow;
    }
  }

  static Future<void> updateClient(ClientModel client) async {
    final index = _cache.indexWhere((c) => c.id == client.id);
    if (index == -1) {
      throw ArgumentError('Client with id ${client.id} not found.');
    }
    final previous = List<ClientModel>.from(_cache);
    _cache[index] = client;
    _sortCache();
    try {
      await _persist();
    } catch (e) {
      _cache = previous;
      rethrow;
    }
  }

  static Future<void> deleteClient(int id) async {
    final previous = List<ClientModel>.from(_cache);
    _cache.removeWhere((c) => c.id == id);
    try {
      await _persist();
    } catch (e) {
      _cache = previous;
      rethrow;
    }
  }

  static List<ClientModel> getAll() => List.unmodifiable(_cache);

  static List<ClientModel> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return getAll();
    return _cache
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.mobile4g.toLowerCase().contains(query) ||
            c.fibre.toLowerCase().contains(query))
        .toList(growable: false);
  }

  static Future<void> _syncFromRemote() async {
    final uri = Uri.parse('$_baseUrl/$_binId/latest');
    final response = await _httpClient.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body);
      final record = payload is Map<String, dynamic> ? payload['record'] : null;
      final List<dynamic> rawList;
      if (record is Map<String, dynamic>) {
        rawList = (record['clients'] as List?) ?? const [];
      } else if (record is List) {
        rawList = record;
      } else {
        rawList = const [];
      }
      _cache = rawList
          .whereType<Map>()
          .map((entry) => ClientModel.fromMap(
                Map<String, dynamic>.from(entry),
              ))
          .toList();
      _sortCache();
      return;
    }

    if (response.statusCode == 404) {
      _cache = [];
      return;
    }

    throw JsonBinException(
      'Failed to load data from JSONBin.',
      statusCode: response.statusCode,
      details: response.body,
    );
  }

  static Future<void> _persist() async {
    final uri = Uri.parse('$_baseUrl/$_binId');
    final body =
        jsonEncode({'clients': _cache.map((c) => c.toMap()).toList()});
    final response = await _httpClient.put(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode >= 400) {
      throw JsonBinException(
        'Failed to save data to JSONBin.',
        statusCode: response.statusCode,
        details: response.body,
      );
    }
  }

  static Map<String, String> get _headers => {
        'X-Master-Key': _masterKey,
      };

  static int _nextId() {
    if (_cache.isEmpty) return 1;
    return _cache.map((c) => c.id).reduce(max) + 1;
  }

  static void _sortCache() {
    _cache.sort((a, b) => a.name.compareTo(b.name));
  }
}

class JsonBinException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  const JsonBinException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (statusCode != null) {
      buffer.write(' (status $statusCode)');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write(': $details');
    }
    return buffer.toString();
  }
}

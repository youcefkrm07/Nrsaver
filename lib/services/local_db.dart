import 'dart:async';
// ignore_for_file: unnecessary_import
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/client.dart';

class LocalDB {
  static const _boxName = 'clients_box_v1';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  // Auto-increment id based on latest key
  static int _nextId() {
    if (_box.isEmpty) return 1;
    final keys = _box.keys.whereType<int>().toList()..sort();
    return (keys.isEmpty ? 0 : keys.last) + 1;
  }

  static Future<ClientModel> addClient(String name, String mobile4g, String fibre) async {
    final id = _nextId();
    final model = ClientModel(id: id, name: name, mobile4g: mobile4g, fibre: fibre);
    await _box.put(id, model.toMap());
    return model;
  }

  static Future<void> updateClient(ClientModel client) async {
    await _box.put(client.id, client.toMap());
  }

  static Future<void> deleteClient(int id) async {
    await _box.delete(id);
  }

  static List<ClientModel> getAll() {
    return _box.toMap().entries
        .where((e) => e.key is int)
        .map((e) => ClientModel.fromMap(Map<String, dynamic>.from(e.value)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<ClientModel> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return getAll();
    return getAll().where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.mobile4g.contains(query) ||
          c.fibre.contains(query);
    }).toList();
  }
}

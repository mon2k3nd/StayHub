import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RentalDraftRepository {
  static const String _draftKeyPrefix = 'rental_draft_';
  final _storage = const FlutterSecureStorage();

  Future<void> saveDraft(String roomId, Map<String, dynamic> data) async {
    final key = '$_draftKeyPrefix$roomId';
    await _storage.write(key: key, value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getDraft(String roomId) async {
    final key = '$_draftKeyPrefix$roomId';
    final jsonString = await _storage.read(key: key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearDraft(String roomId) async {
    final key = '$_draftKeyPrefix$roomId';
    await _storage.delete(key: key);
  }
}

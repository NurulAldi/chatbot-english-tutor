import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatHistoryService {
  static const String _key = 'chat_sessions';

  static Future<List<ChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final sessions = jsonList
        .map((json) => ChatSession.fromJson(json))
        .toList();

    // Sort logic handled in UI, but good to ensure latest is first.
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions;
  }

  static Future<void> saveSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }
}

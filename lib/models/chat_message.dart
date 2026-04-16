class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() {
    return {'text': text, 'isUser': isUser};
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
    );
  }
}

class ChatSession {
  final String id;
  final String title;
  final DateTime timestamp;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

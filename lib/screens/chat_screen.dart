import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:uuid/uuid.dart'; // We'll need this for ID generation
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../services/gemini_service.dart';
import '../services/chat_history_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  String? _currentSessionId;

  // Gemini Service instance
  GeminiService? _geminiService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initGemini();
  }

  void _initGemini() {
    try {
      _geminiService = GeminiService();
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'Gagal memuat API Key Gemini. Pastikan .env sudah benar.',
          isUser: false,
        ),
      );
    }
  }

  Future<void> _loadHistory() async {
    final sessions = await ChatHistoryService.loadSessions();
    setState(() {
      _sessions = sessions;
    });
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentSessionId = null;
      _initGemini(); // restart session gemini
    });
    Navigator.pop(context); // Close drawer
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _currentSessionId = session.id;
      _messages = List.from(session.messages);
      _initGemini(); // Initialize new gemini context
    });
    // Ideally here we send old history to gemini but since our service
    // restarts the ChatSession we'll just start fresh but keep UI history.
    Navigator.pop(context); // Close drawer
    _scrollToBottom();
  }

  Future<void> _saveCurrentSession() async {
    if (_messages.isEmpty) return;

    if (_currentSessionId == null) {
      _currentSessionId = const Uuid().v4();
      final title = _messages.first.text;
      final newSession = ChatSession(
        id: _currentSessionId!,
        title: title.length > 20 ? '${title.substring(0, 20)}...' : title,
        timestamp: DateTime.now(),
        messages: List.from(_messages),
      );
      _sessions.insert(0, newSession);
    } else {
      final index = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (index >= 0) {
        _sessions[index] = ChatSession(
          id: _currentSessionId!,
          title: _sessions[index].title,
          timestamp: DateTime.now(), // Update timestamp
          messages: List.from(_messages),
        );
        // Move to top
        final s = _sessions.removeAt(index);
        _sessions.insert(0, s);
      }
    }

    await ChatHistoryService.saveSessions(_sessions);
    setState(() {}); // refresh sidebar
  }

  Future<void> _deleteSession(ChatSession session) async {
    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);

      // Jika history yang dihapus adalah obrolan yang sedang aktif (terbuka), maka restart ke halaman kosong (New Chat)
      if (_currentSessionId == session.id) {
        _messages.clear();
        _currentSessionId = null;
        _initGemini();
      }
    });

    // Simpan daftar terbaru ke penyimpan lokal
    await ChatHistoryService.saveSessions(_sessions);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    await _saveCurrentSession();

    if (_geminiService != null) {
      final response = await _geminiService!.sendMessage(text);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
      await _saveCurrentSession();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine drawer width to be 1/3 of the screen
    final drawerWidth = MediaQuery.of(context).size.width / 3;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            Colors.transparent, // Background transparent for gradient
        drawer: Drawer(
          width: drawerWidth < 250 ? 250 : drawerWidth, // ensure min width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF111827)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    Text(
                      'Chats List',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF22C55E),
                ),
                title: Text(
                  'New Chat',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                onTap: _startNewChat,
              ),
              const Divider(),
              Expanded(
                child: _sessions.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada history',
                          style: GoogleFonts.inter(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          // Sort order is implicitly newest first as managed by saveCurrentSession
                          return ListTile(
                            leading: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.black54,
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _currentSessionId == session.id
                                    ? const Color(0xFF22C55E)
                                    : Colors.black87,
                                fontWeight: _currentSessionId == session.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () => _deleteSession(session),
                            ),
                            onTap: () => _loadSession(session),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        top: 60.0, // space for top left button
                        bottom: 16.0,
                        left: 8.0,
                        right: 8.0,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(message: _messages[index]);
                      },
                    ),
                    // Judul transisi animasi
                    Center(
                      child: AnimatedOpacity(
                        opacity: _messages.isEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: IgnorePointer(
                          ignoring: _messages.isNotEmpty,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF22C55E),
                                        Color(0xFFE0F2FE),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Ada yang bisa saya bantu hari ini?',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF111827),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Pilih prompt di bawah ini atau tulis pesan sendiri untuk mulai belajar bahasa Inggris',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildPromptCard(
                                        'Tolong periksa grammar dari kalimat ini: "I has went to market"',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildPromptCard(
                                        'Jelaskan perbedaan "much" dan "many" beserta contohnya',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Icon riwayat chat (logo saja) di pojok kiri atas
                    Positioned(
                      top: 8.0,
                      left: 16.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF111827),
                          ),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          tooltip: 'History',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                ),
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 24.0,
        top: 8.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.inter(color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText:
                          'Bagaimana English Tutor bisa membantu anda hari ini?',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF22C55E),
                        Color(0xFF84CC16),
                      ], // Vibrant Green to Lime
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard(String title) {
    return GestureDetector(
      onTap: () {
        _controller.text = title;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

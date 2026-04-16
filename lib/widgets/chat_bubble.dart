import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth:
            MediaQuery.of(context).size.width * (message.isUser ? 0.8 : 0.75),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: message.isUser
                ? Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 15.0,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 15.0,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: bubble,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10.0, top: 4.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF22C55E),
                    Color(0xFFE0F2FE),
                  ], // Green to light blue/whiteish
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }
}

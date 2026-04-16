import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('API Key is missing from .env');
    }

    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'Anda adalah pakar bahasa Inggris. '
        'Analisis input pengguna. Gunakan strikethrough (~~) untuk bagian yang salah dan Bold untuk koreksinya. '
        'Jika benar semua, balas singkat. Jika banyak salah, jelaskan secara detail per poin grammar. '
        'Jangan gunakan warna, cukup format Markdown. '
        'Selain itu, jika pengguna meminta contoh atau teori (misalnya "Kasih contoh kalimat pake kata X dong" atau "Apa bedanya Y dan Z?"), '
        'berikan definisi singkat, daftar contoh kalimat, dan penjelasan penggunaan kata dalam konteks tersebut.',
      ),
    );
  }

  Future<String> sendMessage(String text) async {
    try {
      final response = await _model.generateContent([Content.text(text)]);
      return response.text ?? 'Maaf, saya tidak dapat menghasilkan respons.';
    } catch (e) {
      return 'Error: $e';
    }
  }
}

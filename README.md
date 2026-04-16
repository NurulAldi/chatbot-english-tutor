# English Tutor AI Chatbot

A simple yet powerful Flutter application powered by the Gemini API, designed to help users improve their English. It acts as an interactive English tutor that corrects grammar mistakes and provides examples or theory upon request.

## ✨ Features

- **Grammar Correction**: Automatically analyzes user input and corrects English grammar. It uses strikethrough for incorrect words and bold for corrections.
- **Detailed Explanations**: Provides in-depth explanations for multiple grammatical errors.
- **Theory & Contextual Examples**: Detects when users ask for examples or vocabulary distinctions (e.g., "difference between bring and take") and provides definitions, examples, and context.
- **Markdown Rendering**: Beautifully renders AI responses using Markdown for clear readability.
- **Minimalist UI**: Clean, distraction-free chat interface inspired by modern messaging apps.

## 🛠 Tech Stack & Dependencies

- **Framework**: Flutter (Dart)
- **AI Integration**: `google_generative_ai` (Gemini 1.5 Pro)
- **Environment Management**: `flutter_dotenv` (for secure API key storage)
- **Typography**: `google_fonts` (using the 'Inter' font family)
- **Text Rendering**: `flutter_markdown` (for rendering Gemini's markdown responses)

## 📂 Project Structure

```text
lib/
├── models/
│   └── chat_message.dart      # Data model for chat messages (text, isUser)
├── screens/
│   └── chat_screen.dart       # Main chat interface and UI logic
├── services/
│   └── gemini_service.dart    # Gemini API connection and system prompt logic
├── widgets/
│   └── chat_bubble.dart       # Custom chat bubble UI component
└── main.dart                  # Application entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version recommended)
- A Gemini API Key from [Google AI Studio](https://aistudio.google.com/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd chatbot_english
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Create a `.env` file in the root directory of the project and add your Gemini API key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```
   *Note: Ensure the `.env` file is declared in your `pubspec.yaml` under `assets`.*

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🧠 System Prompt Architecture

The Gemini model is initialized with specific **System Instructions** to act as an English expert. The prompt enforces:
- Using `~~strikethrough~~` for mistakes and `**bold**` for corrections.
- Explaining grammar rules clearly if there are multiple errors.
- Adapting to "theory/example" requests by providing definitions, bulleted examples, and contextual usage.

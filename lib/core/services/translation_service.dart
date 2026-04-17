import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service responsible for dynamic AI-powered translations.
/// It includes a caching mechanism to avoid redundant AI calls.
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  // Simple in-memory cache: { "sourceText_targetLang": "translatedText" }
  final Map<String, String> _cache = {};

  /// Translates [text] to [targetLanguageCode] using AI.
  Future<String> translate(String text, String targetLanguageCode) async {
    // 1. Don't translate if text is empty or numeric
    if (text.trim().isEmpty || double.tryParse(text) != null) return text;

    // 2. Ikenas Protection: Never translate the app name
    if (text.toLowerCase() == 'ikenas') return 'Ikenas';

    // 3. Check Cache
    final cacheKey = '${text}_$targetLanguageCode';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // 4. AI Translation Logic (Placeholder for Gemini/Vertex AI)
      // For now, we simulate an AI call with a small delay.
      // In production, you would use:
      // final response = await gemini.generateContent('Translate this to $targetLanguageCode: $text');

      String translatedText =
          await _simulateAiTranslation(text, targetLanguageCode);

      // 5. Cache the result
      _cache[cacheKey] = translatedText;
      return translatedText;
    } catch (e) {
      if (kDebugMode) print('Translation Error: $e');
      return text; // Fallback to original text on error
    }
  }

  /// Placeholder for actual AI API call.
  /// This simulates the behavior of an LLM.
  Future<String> _simulateAiTranslation(String text, String targetLang) async {
    // In a real scenario, this would be an HTTP call to Gemini.
    await Future.delayed(const Duration(milliseconds: 300));

    // Protection: Even the AI shouldn't change Ikenas
    String processedText =
        text.replaceAll(RegExp(r'Ikenas', caseSensitive: false), '[[IKENAS]]');

    // The AI handles everything in production.
    // Use processedText to simulate transformation then restore Ikenas
    return processedText.replaceAll('[[IKENAS]]', 'Ikenas');
  }

  void clearCache() {
    _cache.clear();
  }
}

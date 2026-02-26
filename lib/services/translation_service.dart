import 'package:translator/translator.dart';

class TranslationService {
  static final GoogleTranslator _translator = GoogleTranslator();
  static final Map<String, String> _memoryCache = {};

  static Future<String> translate(String text, String targetLanguage) async {
    if (text.isEmpty || targetLanguage == 'en') return text;

    String cacheKey = '${targetLanguage}_$text';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }
    
    try {
      var translation = await _translator.translate(text, from: 'en', to: targetLanguage);
      _memoryCache[cacheKey] = translation.text;
      return translation.text;
    } catch (e) {
      print("Translation error: $e");
      return text;
    }
  }
}

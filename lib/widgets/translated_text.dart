import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/language_provider.dart';
import 'package:reality_cart/services/translation_service.dart';

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        String targetLang = languageProvider.currentLocale.languageCode;
        
        if (targetLang == 'en' || text.isEmpty) {
          return Text(
            text,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
          );
        }

        return FutureBuilder<String>(
          // Use FutureBuilder to fetch translation
          future: TranslationService.translate(text, targetLang),
          builder: (context, snapshot) {
            String displayText = text; // Default to original while loading or on error
            
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
               displayText = snapshot.data!;
            }

            return Text(
              displayText,
              style: style,
              maxLines: maxLines,
              overflow: overflow,
              textAlign: textAlign,
            );
          },
        );
      },
    );
  }
}

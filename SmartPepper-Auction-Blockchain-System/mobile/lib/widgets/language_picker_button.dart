import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';

class LanguagePickerButton extends StatelessWidget {
  final Color? iconColor;

  const LanguagePickerButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return PopupMenuButton<String>(
      icon: Icon(Icons.translate, color: iconColor ?? Colors.white),
      tooltip: context.tr('settings_select_language'),
      onSelected: (String code) {
        languageProvider.changeLanguage(code);
      },
      itemBuilder: (BuildContext context) {
        return languageProvider.supportedLanguages.map((language) {
          final isSelected =
              languageProvider.locale.languageCode == language['code'];

          return PopupMenuItem<String>(
            value: language['code']!,
            child: Row(
              children: [
                Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  language['nativeName']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

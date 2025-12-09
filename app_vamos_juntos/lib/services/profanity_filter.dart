import 'package:flutter/services.dart' show rootBundle;

class ProfanityFilter {
  ProfanityFilter._();
  static final instance = ProfanityFilter._();

  Set<String> _words = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final data = await rootBundle.loadString('assets/data/profanity_es.txt');
    _words = data
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty && !w.startsWith('#'))
        .toSet();
    _loaded = true;
  }

  bool containsProfanity(String text) {
    if (!_loaded) {
      throw Exception('Filtro de profanidad no cargado. Llamar ProfanityFilter.instance.load() primero.');
    }
    final normalized = text.toLowerCase();
    for (final w in _words) {
      if (normalized.contains(w)) return true;
    }
    return false;
  }

  String censor(String text) {
    if (!_loaded) {
      throw Exception('Filtro de profanidad no cargado. Llamar ProfanityFilter.instance.load() primero.');
    }
    var output = text;
    for (final w in _words) {
      final re = RegExp(RegExp.escape(w), caseSensitive: false);
      output = output.replaceAllMapped(re, (m) => '*' * m[0]!.length);
    }
    return output;
  }
}

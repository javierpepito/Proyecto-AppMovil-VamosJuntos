import 'package:flutter/services.dart' show rootBundle;

class ProfanityFilter {
  ProfanityFilter._();
  static final instance = ProfanityFilter._();

  Set<String> _words = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final data = await rootBundle.loadString('assets/data/profanity_es.txt');
      _words = data
          .split('\n')
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.isNotEmpty && !w.startsWith('#'))
          .toSet();
      _loaded = true;
    } catch (_) {
      // Si el asset no existe o falla, no rompemos el envío.
      _words = {};
      _loaded = true;
    }
  }

  bool containsProfanity(String text) {
    if (!_loaded) return false;
    final normalized = text.toLowerCase();
    for (final w in _words) {
      if (normalized.contains(w)) return true;
    }
    return false;
  }

  String censor(String text) {
    if (!_loaded) return text;
    var output = text;
    for (final w in _words) {
      final re = RegExp(RegExp.escape(w), caseSensitive: false);
      output = output.replaceAllMapped(re, (m) => '*' * m[0]!.length);
    }
    return output;
  }
}
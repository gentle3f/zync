import 'dart:convert';

import 'package:http/http.dart' as http;

import 'interest_catalog.dart';
import 'language_support.dart';
import 'models.dart';

class AiQuestionResult {
  const AiQuestionResult({
    required this.question,
    required this.fromAi,
    this.secondaryQuestion,
    this.secondaryLanguage,
  });

  final String question;
  final bool fromAi;
  final String? secondaryQuestion;
  final String? secondaryLanguage;
}

class NormalizedInterestResult {
  const NormalizedInterestResult({
    required this.id,
    required this.canonicalName,
    required this.displayName,
    required this.category,
  });

  final String id;
  final String canonicalName;
  final String displayName;
  final String category;
}

class AiService {
  const AiService({this.baseUrl = const String.fromEnvironment('ZYNC_API_BASE')});

  final String baseUrl;

  String _label(SelectedInterest item, String language) {
    return InterestCatalog.byId(item.id)?.labelFor(language) ?? item.customLabel ?? item.id;
  }

  Future<NormalizedInterestResult?> normalizeInterest({
    required String input,
    required String language,
  }) async {
    final trimmed = input.trim();
    if (baseUrl.trim().isEmpty || trimmed.length < 2) return null;
    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/v1/normalize-interest'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'input': trimmed,
              'language': ZyncLanguage.canonical(language),
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final id = (json['id'] as String?)?.trim() ?? '';
      final canonicalName = (json['canonicalName'] as String?)?.trim() ?? '';
      final displayName = (json['displayName'] as String?)?.trim() ?? '';
      final category = (json['category'] as String?)?.trim() ?? 'other';
      if (id.isEmpty || canonicalName.isEmpty || displayName.isEmpty) return null;
      return NormalizedInterestResult(
        id: id,
        canonicalName: canonicalName,
        displayName: displayName,
        category: category.isEmpty ? 'other' : category,
      );
    } catch (_) {
      return null;
    }
  }

  Future<AiQuestionResult> generateQuestion({
    required String language,
    required ConversationMode mode,
    required MatchResult match,
    String? secondaryLanguage,
    String sessionSeed = '',
  }) async {
    final primary = ZyncLanguage.canonical(language);
    final secondary = secondaryLanguage == null ? null : ZyncLanguage.canonical(secondaryLanguage);
    final wantsSecondary = secondary != null && secondary != primary;
    final boundedSessionSeed = sessionSeed.length > 64 ? sessionSeed.substring(0, 64) : sessionSeed;

    if (baseUrl.trim().isEmpty) {
      return _fallback(
        language: primary,
        secondaryLanguage: wantsSecondary ? secondary : null,
        match: match,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/v1/question'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'language': primary,
              if (wantsSecondary) 'secondaryLanguage': secondary,
              'mode': mode.name,
              'shared': match.shared.map((item) => _label(item, primary)).take(8).toList(),
              'personA': match.onlyMine.map((item) => _label(item, primary)).take(8).toList(),
              'personB': match.onlyTheirs.map((item) => _label(item, primary)).take(8).toList(),
              if (boundedSessionSeed.isNotEmpty) 'sessionSeed': boundedSessionSeed,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback(
          language: primary,
          secondaryLanguage: wantsSecondary ? secondary : null,
          match: match,
        );
      }
      final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final question = (json['question'] as String?)?.trim();
      final secondaryQuestion = (json['secondaryQuestion'] as String?)?.trim();
      if (question == null || question.isEmpty || (wantsSecondary && (secondaryQuestion == null || secondaryQuestion.isEmpty))) {
        return _fallback(
          language: primary,
          secondaryLanguage: wantsSecondary ? secondary : null,
          match: match,
        );
      }
      return AiQuestionResult(
        question: question,
        fromAi: true,
        secondaryQuestion: wantsSecondary ? secondaryQuestion : null,
        secondaryLanguage: wantsSecondary ? secondary : null,
      );
    } catch (_) {
      return _fallback(
        language: primary,
        secondaryLanguage: wantsSecondary ? secondary : null,
        match: match,
      );
    }
  }

  AiQuestionResult _fallback({
    required String language,
    required String? secondaryLanguage,
    required MatchResult match,
  }) {
    return AiQuestionResult(
      question: _fallbackQuestion(language: language, match: match),
      fromAi: false,
      secondaryQuestion: secondaryLanguage == null
          ? null
          : _fallbackQuestion(language: secondaryLanguage, match: match),
      secondaryLanguage: secondaryLanguage,
    );
  }

  String _fallbackQuestion({
    required String language,
    required MatchResult match,
  }) {
    String label(SelectedInterest item) => _label(item, language);

    if (match.shared.isNotEmpty) {
      final interest = label(match.shared.first);
      final templates = <String, String>{
        'zh-Hant': '你哋第一次對「$interest」產生興趣係幾時？當時發生咗咩？',
        'zh-Hans': '你们第一次对“$interest”产生兴趣是什么时候？当时发生了什么？',
        'ja': '二人が「$interest」に興味を持ったきっかけは何ですか？',
        'ko': '두 분이 처음 “$interest”에 관심을 갖게 된 계기는 무엇인가요?',
        'es': '¿Qué hizo que cada uno se interesara por $interest por primera vez?',
        'fr': 'Qu’est-ce qui vous a donné envie de découvrir $interest pour la première fois ?',
        'pt': 'O que fez cada um de vocês se interessar por $interest pela primeira vez?',
        'en': 'What first got each of you interested in $interest?',
      };
      return templates[ZyncLanguage.canonical(language)] ?? templates['en']!;
    }

    final a = match.onlyMine.isNotEmpty ? label(match.onlyMine.first) : 'your interests';
    final b = match.onlyTheirs.isNotEmpty ? label(match.onlyTheirs.first) : 'their interests';
    final templates = <String, String>{
      'zh-Hant': '如果將「$a」同「$b」混合成一個週末活動，你哋會點設計？',
      'zh-Hans': '如果把“$a”和“$b”混合成一个周末活动，你们会怎么设计？',
      'ja': '「$a」と「$b」を組み合わせて週末の活動を作るなら、どんなものにしますか？',
      'ko': '“$a”와 “$b”를 하나의 주말 활동으로 합친다면 어떤 모습일까요?',
      'es': 'Si combinarais $a y $b en una actividad de fin de semana, ¿cómo sería?',
      'fr': 'Si vous combiniez $a et $b en une activité de week-end, à quoi ressemblerait-elle ?',
      'pt': 'Se vocês combinassem $a e $b em uma atividade de fim de semana, como seria?',
      'en': 'If $a and $b were combined into one weekend activity, what would it look like?',
    };
    return templates[ZyncLanguage.canonical(language)] ?? templates['en']!;
  }
}

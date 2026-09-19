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
    this.model,
    this.interactionType = 'play',
    this.turnPattern = const [],
  });

  final String question;
  final bool fromAi;
  final String? secondaryQuestion;
  final String? secondaryLanguage;
  final String? model;
  final String interactionType;
  final List<String> turnPattern;
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

String _interactionTypeForMode(ConversationMode mode) => switch (mode) {
      ConversationMode.easy => 'pick',
      ConversationMode.fun => 'play',
      ConversationMode.debate => 'defend',
      ConversationMode.deep => 'reveal',
      ConversationMode.guess => 'guess',
      ConversationMode.surprise => 'surprise',
    };

List<String> _turnPatternForMode(ConversationMode mode) => switch (mode) {
      ConversationMode.easy => const ['choose', 'compare'],
      ConversationMode.fun => const ['act', 'react'],
      ConversationMode.debate => const ['choose', 'defend', 'compare'],
      ConversationMode.deep => const ['share', 'react'],
      ConversationMode.guess => const ['predict', 'reveal', 'react'],
      ConversationMode.surprise => const ['react', 'compare'],
    };

class AiService {
  const AiService({
    this.baseUrl = const String.fromEnvironment('ZYNC_API_BASE'),
  });

  final String baseUrl;

  bool get hasRemote => baseUrl.trim().isNotEmpty;

  String _label(SelectedInterest item, String language) {
    return InterestCatalog.byId(item.id)?.labelFor(language) ??
        item.customLabel ??
        item.id;
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
            Uri.parse(
              '${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/v1/normalize-interest',
            ),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'input': trimmed,
              'language': ZyncLanguage.canonical(language),
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final json =
          Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final id = (json['id'] as String?)?.trim() ?? '';
      final canonicalName = (json['canonicalName'] as String?)?.trim() ?? '';
      final displayName = (json['displayName'] as String?)?.trim() ?? '';
      final category = (json['category'] as String?)?.trim() ?? 'other';
      if (id.isEmpty || canonicalName.isEmpty || displayName.isEmpty) {
        return null;
      }
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

  AiQuestionResult localFallback({
    required String language,
    required MatchResult match,
    String? secondaryLanguage,
    ConversationMode mode = ConversationMode.fun,
  }) {
    final primary = ZyncLanguage.canonical(language);
    final secondary = secondaryLanguage == null
        ? null
        : ZyncLanguage.canonical(secondaryLanguage);
    return _fallback(
      language: primary,
      secondaryLanguage:
          secondary != null && secondary != primary ? secondary : null,
      match: match,
      mode: mode,
    );
  }

  Future<AiQuestionResult?> generateAiQuestion({
    required String language,
    required ConversationMode mode,
    required MatchResult match,
    String? secondaryLanguage,
    String sessionSeed = '',
    String connectionKey = '',
  }) async {
    final primary = ZyncLanguage.canonical(language);
    final secondary = secondaryLanguage == null
        ? null
        : ZyncLanguage.canonical(secondaryLanguage);
    final wantsSecondary = secondary != null && secondary != primary;
    final boundedSessionSeed =
        sessionSeed.length > 64 ? sessionSeed.substring(0, 64) : sessionSeed;
    final boundedConnectionKey = connectionKey.length > 180
        ? connectionKey.substring(0, 180)
        : connectionKey;

    if (baseUrl.trim().isEmpty) return null;

    try {
      final response = await http
          .post(
            Uri.parse(
              '${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/v1/question',
            ),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'language': primary,
              if (wantsSecondary) 'secondaryLanguage': secondary,
              'mode': mode.name,
              'shared': match.shared
                  .map((item) => _label(item, primary))
                  .take(8)
                  .toList(),
              'personA': match.onlyMine
                  .map((item) => _label(item, primary))
                  .take(8)
                  .toList(),
              'personB': match.onlyTheirs
                  .map((item) => _label(item, primary))
                  .take(8)
                  .toList(),
              if (boundedSessionSeed.isNotEmpty)
                'sessionSeed': boundedSessionSeed,
              if (boundedConnectionKey.trim().isNotEmpty)
                'connectionKey': boundedConnectionKey.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final json =
          Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final question = (json['question'] as String?)?.trim();
      final secondaryQuestion =
          (json['secondaryQuestion'] as String?)?.trim();

      if (question == null ||
          question.isEmpty ||
          (wantsSecondary &&
              (secondaryQuestion == null || secondaryQuestion.isEmpty))) {
        return null;
      }

      final servedModel = (json['model'] as String?)?.trim();
      final interactionRaw = json['interaction'];
      final interaction = interactionRaw is Map
          ? Map<String, dynamic>.from(interactionRaw)
          : const <String, dynamic>{};
      final interactionType =
          (interaction['type'] as String?)?.trim() ?? _interactionTypeForMode(mode);
      final turnPattern = ((interaction['turnPattern'] as List?) ?? const [])
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .take(6)
          .toList(growable: false);
      return AiQuestionResult(
        question: question,
        fromAi: true,
        secondaryQuestion: wantsSecondary ? secondaryQuestion : null,
        secondaryLanguage: wantsSecondary ? secondary : null,
        model: servedModel == null || servedModel.isEmpty ? null : servedModel,
        interactionType: interactionType.isEmpty
            ? _interactionTypeForMode(mode)
            : interactionType,
        turnPattern: turnPattern.isEmpty ? _turnPatternForMode(mode) : turnPattern,
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
    String connectionKey = '',
  }) async {
    final ai = await generateAiQuestion(
      language: language,
      secondaryLanguage: secondaryLanguage,
      mode: mode,
      match: match,
      sessionSeed: sessionSeed,
      connectionKey: connectionKey,
    );
    return ai ??
        localFallback(
          language: language,
          secondaryLanguage: secondaryLanguage,
          match: match,
          mode: mode,
        );
  }

  AiQuestionResult _fallback({
    required String language,
    required String? secondaryLanguage,
    required MatchResult match,
    required ConversationMode mode,
  }) {
    return AiQuestionResult(
      question: _fallbackQuestion(language: language, match: match, mode: mode),
      fromAi: false,
      secondaryQuestion: secondaryLanguage == null
          ? null
          : _fallbackQuestion(
              language: secondaryLanguage,
              match: match,
              mode: mode,
            ),
      secondaryLanguage: secondaryLanguage,
      interactionType: _interactionTypeForMode(mode),
      turnPattern: _turnPatternForMode(mode),
    );
  }

  String _fallbackQuestion({
    required String language,
    required MatchResult match,
    required ConversationMode mode,
  }) {
    String label(SelectedInterest item) => _label(item, language);

    if (match.shared.isNotEmpty) {
      final interest = label(match.shared.first);
      final code = ZyncLanguage.canonical(language);
      final templates = switch (mode) {
        ConversationMode.easy => <String, String>{
            'zh-Hant':'講「$interest」時，一齊揀：你偏向預先計劃，定係到時先算？揀完先比較。',
            'zh-Hans':'说到“$interest”，一起选：你偏向提前计划，还是到时再说？选完再比较。',
            'ja':'「$interest」なら、計画派？その場派？同時に選んで比べよう。',
            'ko':'“$interest”라면 계획형인가요, 즉흥형인가요? 동시에 고르고 비교해 보세요.',
            'es':'Con $interest, ¿sois más de planear o improvisar? Elegid a la vez y comparad.',
            'fr':'Pour $interest, plutôt tout planifier ou improviser ? Choisissez en même temps puis comparez.',
            'pt':'Com $interest, preferem planear ou improvisar? Escolham ao mesmo tempo e comparem.',
            'en':'For $interest, are you more plan-it-out or wing-it? Choose at the same time, then compare.',
          },
        ConversationMode.debate => <String, String>{
            'zh-Hant':'講「$interest」，邊樣更重要：跟公認做法，定係用自己方式享受？各揀一邊再辯護。',
            'zh-Hans':'说到“$interest”，哪个更重要：遵循公认做法，还是用自己的方式享受？各选一边再辩护。',
            'ja':'「$interest」では、王道を守ることと自分流で楽しむこと、どちらが大事？立場を選んで弁護しよう。',
            'ko':'“$interest”에서는 정석을 따르는 것과 자기 방식으로 즐기는 것 중 무엇이 더 중요할까요? 한쪽을 골라 변호해 보세요.',
            'es':'En $interest, ¿importa más hacerlo “bien” o disfrutarlo a tu manera? Elegid un lado y defendedlo.',
            'fr':'Pour $interest, vaut-il mieux respecter les codes ou en profiter à sa façon ? Choisissez un camp et défendez-le.',
            'pt':'Em $interest, importa mais seguir a forma certa ou aproveitar à tua maneira? Escolham um lado e defendam-no.',
            'en':'For $interest, what matters more: doing it the “right” way or enjoying it your own way? Pick a side and defend it.',
          },
        ConversationMode.deep => <String, String>{
            'zh-Hant':'如果一年完全冇得接觸「$interest」，你最掛住嘅會係邊一部分？一個先講，另一個再回應。',
            'zh-Hans':'如果一年完全不能接触“$interest”，你最想念的会是哪一部分？一个先说，另一个再回应。',
            'ja':'もし1年間「$interest」に触れられないなら、何が一番恋しくなる？一人が先に話し、もう一人が反応しよう。',
            'ko':'1년 동안 “$interest”를 전혀 못 한다면 무엇이 가장 그리울까요? 한 사람이 먼저 말하고 다른 사람이 반응하세요.',
            'es':'Si pasarais un año sin $interest, ¿qué echaríais más de menos? Uno comparte primero y el otro reacciona.',
            'fr':'Si vous deviez passer un an sans $interest, qu’est-ce qui vous manquerait le plus ? L’un partage, l’autre réagit.',
            'pt':'Se passassem um ano sem $interest, do que teriam mais saudades? Um partilha primeiro e o outro reage.',
            'en':'If you had to go a year without $interest, what part would you miss most? One shares first; the other reacts.',
          },
        ConversationMode.guess => <String, String>{
            'zh-Hant':'先估對方會推薦「$interest」邊一樣畀完全新手，估完先畀對方揭曉真正答案。',
            'zh-Hans':'先猜对方会把“$interest”的什么推荐给完全新手，猜完再让对方揭晓真正答案。',
            'ja':'相手が「$interest」の初心者に最初に勧めるものを予想してから、本当の答えを聞こう。',
            'ko':'상대가 “$interest” 완전 초보에게 무엇을 먼저 추천할지 맞혀본 뒤 실제 답을 공개하세요.',
            'es':'Adivina qué recomendaría primero la otra persona a un principiante total en $interest; luego que revele su respuesta.',
            'fr':'Devine ce que l’autre conseillerait d’abord à un débutant complet en $interest, puis laisse-le révéler sa réponse.',
            'pt':'Adivinha o que a outra pessoa recomendaria primeiro a um completo iniciante em $interest; depois revela a resposta.',
            'en':'Guess what the other person would recommend first to a complete beginner in $interest, then let them reveal the real answer.',
          },
        ConversationMode.surprise => <String, String>{
            'zh-Hant':'你突然得一個鐘、零準備，要令一個陌生人明白「$interest」點解有趣——你第一步會做咩？',
            'zh-Hans':'你突然只有一小时、零准备，要让一个陌生人明白“$interest”为什么有趣——你第一步会做什么？',
            'ja':'準備ゼロで1時間だけ使って、知らない人に「$interest」の面白さを伝えるなら最初に何をする？',
            'ko':'준비 없이 한 시간 안에 낯선 사람에게 “$interest”의 재미를 보여줘야 한다면 가장 먼저 무엇을 할까요?',
            'es':'Tienes una hora y cero preparación para enseñarle a un desconocido por qué $interest es divertido. ¿Qué haces primero?',
            'fr':'Tu as une heure et zéro préparation pour montrer à un inconnu pourquoi $interest est intéressant. Tu fais quoi d’abord ?',
            'pt':'Tens uma hora e zero preparação para mostrar a um desconhecido porque $interest é divertido. O que fazes primeiro?',
            'en':'You get one hour and zero preparation to show a stranger why $interest is fun. What do you do first?',
          },
        ConversationMode.fun => <String, String>{
            'zh-Hant':'一人幫「$interest」加一條荒謬新規則；邊個版本會更好玩？',
            'zh-Hans':'每人给“$interest”加一条荒谬新规则；谁的版本会更好玩？',
            'ja':'「$interest」に一人ずつ変な新ルールを追加するとしたら？どちらの方が面白くなる？',
            'ko':'각자 “$interest”에 황당한 새 규칙 하나를 추가해 보세요. 누구의 버전이 더 재미있을까요?',
            'es':'Inventad cada uno una regla absurda nueva para $interest. ¿Cuál haría que fuera más divertido?',
            'fr':'Inventez chacun une nouvelle règle absurde pour $interest. Laquelle le rendrait plus drôle ?',
            'pt':'Inventem cada um uma nova regra absurda para $interest. Qual tornaria tudo mais divertido?',
            'en':'Each invent one ridiculous new rule for $interest. Whose version would make it more fun?',
          },
      };
      return templates[code] ?? templates['en']!;
    }

    if (match.onlyMine.isNotEmpty && match.onlyTheirs.isEmpty) {
      final interest = label(match.onlyMine.first);
      final templates = <String, String>{
        'zh-Hant':
            '你最想對方講一個關於「$interest」而外行人通常唔知道嘅故事或者細節係咩？',
        'zh-Hans':
            '你最想让对方讲一个关于“$interest”而外行人通常不知道的故事或细节是什么？',
        'ja':
            '「$interest」について、詳しくない相手に一番話してみたい意外なことは何ですか？',
        'ko':
            '“$interest”를 잘 모르는 상대에게 꼭 들려주고 싶은 의외의 이야기나 디테일은 무엇인가요?',
        'es':
            '¿Qué historia o detalle sorprendente sobre $interest le contarías a alguien que no lo conoce bien?',
        'fr':
            'Quelle histoire ou quel détail surprenant sur $interest raconterais-tu à quelqu’un qui connaît peu ce sujet ?',
        'pt':
            'Que história ou detalhe surpreendente sobre $interest você contaria a alguém que conhece pouco isso?',
        'en':
            'What is one story or surprising detail about $interest you would tell someone who does not know it well?',
      };
      return templates[ZyncLanguage.canonical(language)] ?? templates['en']!;
    }

    if (match.onlyTheirs.isNotEmpty && match.onlyMine.isEmpty) {
      final interest = label(match.onlyTheirs.first);
      final templates = <String, String>{
        'zh-Hant':
            '不如請對方講一個關於「$interest」而你可能估唔到嘅故事或者細節？',
        'zh-Hans':
            '不如请对方讲一个关于“$interest”而你可能想不到的故事或细节？',
        'ja':
            '相手に「$interest」について、あなたが意外に思いそうな話や細部を一つ教えてもらうなら何を聞きますか？',
        'ko':
            '상대에게 “$interest”에 대해 당신이 의외라고 느낄 만한 이야기나 디테일 하나를 들려달라고 해보세요.',
        'es':
            'Pídele que te cuente una historia o detalle sobre $interest que probablemente no esperarías.',
        'fr':
            'Demande-lui de raconter une histoire ou un détail sur $interest auquel tu ne t’attendrais probablement pas.',
        'pt':
            'Peça para a outra pessoa contar uma história ou detalhe sobre $interest que você provavelmente não esperaria.',
        'en':
            'Ask them for one story or surprising detail about $interest that you probably would not expect.',
      };
      return templates[ZyncLanguage.canonical(language)] ?? templates['en']!;
    }

    final a = match.onlyMine.isNotEmpty
        ? label(match.onlyMine.first)
        : 'your interests';
    final b = match.onlyTheirs.isNotEmpty
        ? label(match.onlyTheirs.first)
        : 'their interests';
    final templates = <String, String>{
      'zh-Hant':
          '如果將「$a」同「$b」混合成一個週末活動，你哋會點設計？',
      'zh-Hans':
          '如果把“$a”和“$b”混合成一个周末活动，你们会怎么设计？',
      'ja': '「$a」と「$b」を組み合わせて週末の活動を作るなら、どんなものにしますか？',
      'ko': '“$a”와 “$b”를 하나의 주말 활동으로 합친다면 어떤 모습일까요?',
      'es':
          'Si combinarais $a y $b en una actividad de fin de semana, ¿cómo sería?',
      'fr':
          'Si vous combiniez $a et $b en une activité de week-end, à quoi ressemblerait-elle ?',
      'pt':
          'Se vocês combinassem $a e $b em uma atividade de fim de semana, como seria?',
      'en':
          'If $a and $b were combined into one weekend activity, what would it look like?',
    };
    return templates[ZyncLanguage.canonical(language)] ?? templates['en']!;
  }
}

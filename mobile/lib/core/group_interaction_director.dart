import 'group_discovery_service.dart';
import 'group_zync_protocol.dart';
import 'interest_catalog.dart';
import 'zync_alias.dart';

enum GroupInputKind {
  none,
  participantSingle,
  participantSet,
}

class GroupInputOption {
  const GroupInputOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class GroupInputSpec {
  const GroupInputSpec({
    required this.kind,
    required this.requiredSelections,
    required this.options,
  });

  final GroupInputKind kind;
  final int requiredSelections;
  final List<GroupInputOption> options;

  bool get privateInputRequired => kind != GroupInputKind.none;
}

class GroupInteractionRound {
  const GroupInteractionRound({
    required this.id,
    required this.mechanic,
    required this.title,
    required this.prompt,
    required this.input,
    required this.revealTitle,
    required this.revealBody,
    required this.followUp,
    required this.interestId,
    required this.targetParticipantIds,
  });

  final String id;
  final GroupDiscoveryMechanic mechanic;
  final String title;
  final String prompt;
  final GroupInputSpec input;
  final String revealTitle;
  final String revealBody;
  final String followUp;
  final String interestId;
  final List<String> targetParticipantIds;
}

class GroupInteractionDirector {
  const GroupInteractionDirector._();

  static GroupInteractionRound build({
    required GroupDiscoveryCandidate candidate,
    required List<GroupParticipantProfile> participants,
    required String locale,
  }) {
    final interest =
        InterestCatalog.byId(candidate.interestId)?.labelFor(locale) ??
            candidate.interestId;
    final options = participants
        .map(
          (participant) => GroupInputOption(
            id: participant.participantId,
            label: ZyncAlias.displayName(
              nickname: participant.nickname,
              localId: participant.participantId,
              locale: locale,
            ),
          ),
        )
        .toList(growable: false);
    final targetNames = candidate.participantIds.map((id) {
      final participant = participants.firstWhere(
        (item) => item.participantId == id,
      );
      return ZyncAlias.displayName(
        nickname: participant.nickname,
        localId: participant.participantId,
        locale: locale,
      );
    }).toList(growable: false);

    return switch (candidate.mechanic) {
      GroupDiscoveryMechanic.hiddenCluster => GroupInteractionRound(
          id: candidate.id,
          mechanic: candidate.mechanic,
          title: _copy(locale, 'hiddenTitle'),
          prompt: _copy(
            locale,
            'hiddenPrompt',
            count: candidate.subsetSize,
          ),
          input: GroupInputSpec(
            kind: GroupInputKind.participantSet,
            requiredSelections: candidate.subsetSize,
            options: options,
          ),
          revealTitle: _copy(locale, 'hiddenReveal', value: interest),
          revealBody: targetNames.join(' · '),
          followUp: _copy(locale, 'hiddenFollowUp'),
          interestId: candidate.interestId,
          targetParticipantIds: candidate.participantIds,
        ),
      GroupDiscoveryMechanic.majorityPattern => GroupInteractionRound(
          id: candidate.id,
          mechanic: candidate.mechanic,
          title: _copy(locale, 'majorityTitle'),
          prompt: _copy(
            locale,
            'majorityPrompt',
            count: candidate.subsetSize,
          ),
          input: GroupInputSpec(
            kind: GroupInputKind.participantSet,
            requiredSelections: candidate.subsetSize,
            options: options,
          ),
          revealTitle: _copy(locale, 'majorityReveal', value: interest),
          revealBody: targetNames.join(' · '),
          followUp: _copy(locale, 'majorityFollowUp'),
          interestId: candidate.interestId,
          targetParticipantIds: candidate.participantIds,
        ),
      GroupDiscoveryMechanic.onlyOne => GroupInteractionRound(
          id: candidate.id,
          mechanic: candidate.mechanic,
          title: _copy(locale, 'onlyOneTitle'),
          prompt: _copy(locale, 'onlyOnePrompt', value: interest),
          input: GroupInputSpec(
            kind: GroupInputKind.participantSingle,
            requiredSelections: 1,
            options: options,
          ),
          revealTitle: _copy(locale, 'onlyOneReveal'),
          revealBody: targetNames.single,
          followUp: _copy(locale, 'onlyOneFollowUp', value: interest),
          interestId: candidate.interestId,
          targetParticipantIds: candidate.participantIds,
        ),
      GroupDiscoveryMechanic.whoKnowsThis => GroupInteractionRound(
          id: candidate.id,
          mechanic: candidate.mechanic,
          title: _copy(locale, 'expertTitle'),
          prompt: _copy(locale, 'expertPrompt', value: interest),
          input: GroupInputSpec(
            kind: GroupInputKind.participantSingle,
            requiredSelections: 1,
            options: options,
          ),
          revealTitle: _copy(locale, 'expertReveal'),
          revealBody: targetNames.single,
          followUp: _copy(locale, 'expertFollowUp', value: interest),
          interestId: candidate.interestId,
          targetParticipantIds: candidate.participantIds,
        ),
      GroupDiscoveryMechanic.allTogether => GroupInteractionRound(
          id: candidate.id,
          mechanic: candidate.mechanic,
          title: _copy(locale, 'allTitle'),
          prompt: _copy(locale, 'allPrompt'),
          input: const GroupInputSpec(
            kind: GroupInputKind.none,
            requiredSelections: 0,
            options: [],
          ),
          revealTitle: _copy(locale, 'allReveal', value: interest),
          revealBody: _copy(locale, 'allBody'),
          followUp: _copy(locale, 'allFollowUp'),
          interestId: candidate.interestId,
          targetParticipantIds: candidate.participantIds,
        ),
    };
  }

  static String _language(String locale) {
    final raw = locale.replaceAll('_', '-').toLowerCase();
    if (raw.startsWith('zh')) {
      return raw.contains('hans') ||
              raw.contains('-cn') ||
              raw.contains('-sg')
          ? 'zh-Hans'
          : 'zh-Hant';
    }
    for (final language in ['ja', 'ko', 'es', 'fr', 'pt']) {
      if (raw.startsWith(language)) return language;
    }
    return 'en';
  }

  static String _copy(
    String locale,
    String key, {
    int? count,
    String? value,
  }) {
    final lang = _language(locale);
    var text = (_copies[lang] ?? _copies['en']!)[key] ??
        _copies['en']![key] ??
        '';
    if (count != null) text = text.replaceAll('{count}', '$count');
    if (value != null) text = text.replaceAll('{value}', value);
    return text;
  }

  static const Map<String, Map<String, String>> _copies = {
    'en': {
      'hiddenTitle': 'Hidden cluster',
      'hiddenPrompt':
          '{count} people here secretly picked the same interest. Who are they?',
      'hiddenReveal': 'The hidden connection: {value}',
      'hiddenFollowUp': 'How did this never come up before?',
      'majorityTitle': 'Quiet majority',
      'majorityPrompt':
          '{count} people here share one interest. Guess the group.',
      'majorityReveal': 'The shared interest: {value}',
      'majorityFollowUp': 'Did anyone expect this group?',
      'onlyOneTitle': 'Only one',
      'onlyOnePrompt': 'Only one person picked {value}. Who was it?',
      'onlyOneReveal': 'It was…',
      'onlyOneFollowUp':
          'Give them 30 seconds: what should a beginner know about {value}?',
      'expertTitle': 'Who knows this?',
      'expertPrompt': 'Who is most likely the {value} person?',
      'expertReveal': 'Meet the room expert',
      'expertFollowUp':
          'Teach the room one surprisingly useful thing about {value}.',
      'allTitle': 'Plot twist',
      'allPrompt': 'There is one interest every person here picked.',
      'allReveal': 'Everyone picked {value}',
      'allBody': 'You had this in common before Zync even started.',
      'allFollowUp': 'Would you actually do it together?',
    },
    'zh-Hant': {
      'hiddenTitle': '隱藏小隊',
      'hiddenPrompt': '呢度有 {count} 個人偷偷揀咗同一個興趣。你估係邊幾個？',
      'hiddenReveal': '原來你哋都鍾意：{value}',
      'hiddenFollowUp': '點解你哋之前一直都冇講起過？',
      'majorityTitle': '低調大多數',
      'majorityPrompt': '呢度有 {count} 個人有同一個興趣。你估係邊幾個？',
      'majorityReveal': '共同興趣係：{value}',
      'majorityFollowUp': '有人一早估到係呢班人嗎？',
      'onlyOneTitle': '只有一個',
      'onlyOnePrompt': '全場只有一個人揀咗「{value}」。你估係邊個？',
      'onlyOneReveal': '答案係……',
      'onlyOneFollowUp': '畀佢 30 秒：新手第一次接觸「{value}」最應該知咩？',
      'expertTitle': '邊個最識？',
      'expertPrompt': '你估邊個最可能係「{value}」嗰位？',
      'expertReveal': '搵到房內高手',
      'expertFollowUp': '教大家一樣關於「{value}」意外地實用嘅嘢。',
      'allTitle': '原來全場都有',
      'allPrompt': '有一個興趣，呢度每一個人都有揀。',
      'allReveal': '全場共同興趣：{value}',
      'allBody': '原來未開始傾，你哋已經有呢樣共同點。',
      'allFollowUp': '如果真係一齊做一次，你哋會唔會去？',
    },
    'zh-Hans': {
      'hiddenTitle': '隐藏小队',
      'hiddenPrompt': '这里有 {count} 个人偷偷选了同一个兴趣。你猜是哪几个人？',
      'hiddenReveal': '原来你们都喜欢：{value}',
      'hiddenFollowUp': '为什么你们之前一直没聊到过？',
      'majorityTitle': '低调大多数',
      'majorityPrompt': '这里有 {count} 个人有同一个兴趣。你猜是哪几个人？',
      'majorityReveal': '共同兴趣是：{value}',
      'majorityFollowUp': '有人一开始就猜到是这群人吗？',
      'onlyOneTitle': '只有一个',
      'onlyOnePrompt': '全场只有一个人选了“{value}”。你猜是谁？',
      'onlyOneReveal': '答案是……',
      'onlyOneFollowUp': '给TA 30秒：新手第一次接触“{value}”最应该知道什么？',
      'expertTitle': '谁最懂？',
      'expertPrompt': '你猜谁最可能是“{value}”那位？',
      'expertReveal': '找到房间里的高手',
      'expertFollowUp': '教大家一个关于“{value}”意外实用的东西。',
      'allTitle': '原来全场都有',
      'allPrompt': '有一个兴趣，这里每个人都选了。',
      'allReveal': '全场共同兴趣：{value}',
      'allBody': '原来还没开始聊，你们已经有这个共同点。',
      'allFollowUp': '如果真的一起做一次，你们会不会去？',
    },
    'ja': {
      'hiddenTitle': '隠れグループ',
      'hiddenPrompt': 'ここに同じ興味を選んだ人が {count} 人います。誰でしょう？',
      'hiddenReveal': '隠れた共通点：{value}',
      'hiddenFollowUp': '今までどうして話題にならなかった？',
      'majorityTitle': '静かな多数派',
      'majorityPrompt': '{count} 人が同じ興味を持っています。誰でしょう？',
      'majorityReveal': '共通の興味：{value}',
      'majorityFollowUp': 'この組み合わせ、予想できた？',
      'onlyOneTitle': 'たった一人',
      'onlyOnePrompt': '{value} を選んだのは一人だけ。誰でしょう？',
      'onlyOneReveal': '答えは…',
      'onlyOneFollowUp': '{value} の初心者に一つだけ教えるなら？',
      'expertTitle': '一番詳しいのは？',
      'expertPrompt': '{value} に一番詳しそうなのは誰？',
      'expertReveal': 'この部屋のエキスパート',
      'expertFollowUp': '{value} について意外と役立つことを一つ教えて。',
      'allTitle': 'まさかの全員一致',
      'allPrompt': '全員が選んだ興味が一つあります。',
      'allReveal': '全員が選んだ：{value}',
      'allBody': '話す前から、すでに共通点がありました。',
      'allFollowUp': '本当にみんなでやってみる？',
    },
    'ko': {
      'hiddenTitle': '숨은 그룹',
      'hiddenPrompt': '여기 {count}명이 같은 관심사를 골랐어요. 누구일까요?',
      'hiddenReveal': '숨은 공통점: {value}',
      'hiddenFollowUp': '왜 지금까지 이 얘기가 안 나왔을까요?',
      'majorityTitle': '조용한 다수',
      'majorityPrompt': '{count}명이 같은 관심사를 갖고 있어요. 누구일까요?',
      'majorityReveal': '공통 관심사: {value}',
      'majorityFollowUp': '이 조합을 예상한 사람이 있나요?',
      'onlyOneTitle': '딱 한 명',
      'onlyOnePrompt': '{value}를 고른 사람은 한 명뿐이에요. 누구일까요?',
      'onlyOneReveal': '정답은…',
      'onlyOneFollowUp': '{value} 초보에게 딱 하나 알려준다면?',
      'expertTitle': '누가 제일 잘 알까?',
      'expertPrompt': '{value}를 가장 잘 알 것 같은 사람은 누구?',
      'expertReveal': '이 방의 전문가',
      'expertFollowUp': '{value}에 대해 의외로 유용한 것 하나를 알려주세요.',
      'allTitle': '전원 일치',
      'allPrompt': '여기 모든 사람이 고른 관심사가 하나 있어요.',
      'allReveal': '모두가 고른 것: {value}',
      'allBody': '대화하기 전부터 이미 공통점이 있었네요.',
      'allFollowUp': '진짜 다 같이 해볼까요?',
    },
    'es': {
      'hiddenTitle': 'Grupo oculto',
      'hiddenPrompt':
          '{count} personas eligieron en secreto el mismo interés. ¿Quiénes son?',
      'hiddenReveal': 'La conexión oculta: {value}',
      'hiddenFollowUp': '¿Cómo es que nunca había salido este tema?',
      'majorityTitle': 'Mayoría silenciosa',
      'majorityPrompt': '{count} personas comparten un interés. Adivina quiénes.',
      'majorityReveal': 'El interés compartido: {value}',
      'majorityFollowUp': '¿Alguien esperaba este grupo?',
      'onlyOneTitle': 'Solo una persona',
      'onlyOnePrompt': 'Solo una persona eligió {value}. ¿Quién fue?',
      'onlyOneReveal': 'Fue…',
      'onlyOneFollowUp': 'En 30 segundos: ¿qué debería saber un principiante sobre {value}?',
      'expertTitle': '¿Quién sabe más?',
      'expertPrompt': '¿Quién parece ser la persona de {value}?',
      'expertReveal': 'La persona experta del grupo',
      'expertFollowUp': 'Enséñanos algo sorprendentemente útil sobre {value}.',
      'allTitle': 'Giro inesperado',
      'allPrompt': 'Hay un interés que eligieron todas las personas.',
      'allReveal': 'Todo el grupo eligió {value}',
      'allBody': 'Ya tenían esto en común antes de empezar.',
      'allFollowUp': '¿Lo harían juntos de verdad?',
    },
    'fr': {
      'hiddenTitle': 'Groupe caché',
      'hiddenPrompt':
          '{count} personnes ont choisi le même intérêt en secret. Lesquelles ?',
      'hiddenReveal': 'Le lien caché : {value}',
      'hiddenFollowUp': 'Comment ce sujet n’est-il jamais sorti avant ?',
      'majorityTitle': 'Majorité discrète',
      'majorityPrompt': '{count} personnes partagent un intérêt. Devinez lesquelles.',
      'majorityReveal': 'L’intérêt commun : {value}',
      'majorityFollowUp': 'Quelqu’un avait prévu ce groupe ?',
      'onlyOneTitle': 'Une seule personne',
      'onlyOnePrompt': 'Une seule personne a choisi {value}. Qui ?',
      'onlyOneReveal': 'C’était…',
      'onlyOneFollowUp': 'En 30 secondes : que doit savoir un débutant sur {value} ?',
      'expertTitle': 'Qui s’y connaît ?',
      'expertPrompt': 'Qui semble être la personne la plus calée en {value} ?',
      'expertReveal': 'L’expert du groupe',
      'expertFollowUp': 'Apprends-nous une chose étonnamment utile sur {value}.',
      'allTitle': 'Tout le monde',
      'allPrompt': 'Il y a un intérêt choisi par absolument tout le monde.',
      'allReveal': 'Tout le monde a choisi {value}',
      'allBody': 'Vous aviez déjà ce point commun avant de commencer.',
      'allFollowUp': 'Vous le feriez vraiment ensemble ?',
    },
    'pt': {
      'hiddenTitle': 'Grupo escondido',
      'hiddenPrompt':
          '{count} pessoas escolheram secretamente o mesmo interesse. Quem são?',
      'hiddenReveal': 'A conexão escondida: {value}',
      'hiddenFollowUp': 'Como isso nunca apareceu na conversa antes?',
      'majorityTitle': 'Maioria discreta',
      'majorityPrompt': '{count} pessoas compartilham um interesse. Adivinhe quem.',
      'majorityReveal': 'O interesse em comum: {value}',
      'majorityFollowUp': 'Alguém esperava esse grupo?',
      'onlyOneTitle': 'Só uma pessoa',
      'onlyOnePrompt': 'Só uma pessoa escolheu {value}. Quem foi?',
      'onlyOneReveal': 'Foi…',
      'onlyOneFollowUp': 'Em 30 segundos: o que um iniciante deve saber sobre {value}?',
      'expertTitle': 'Quem entende disso?',
      'expertPrompt': 'Quem parece ser a pessoa de {value}?',
      'expertReveal': 'A pessoa especialista do grupo',
      'expertFollowUp': 'Ensine uma coisa surpreendentemente útil sobre {value}.',
      'allTitle': 'Todo mundo',
      'allPrompt': 'Existe um interesse que todo mundo aqui escolheu.',
      'allReveal': 'Todo mundo escolheu {value}',
      'allBody': 'Vocês já tinham isso em comum antes de começar.',
      'allFollowUp': 'Vocês realmente fariam isso juntos?',
    },
  };
}

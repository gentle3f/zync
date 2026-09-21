import 'interest_entity_metadata.dart';

class ActivityTemplate {
  const ActivityTemplate({
    required this.id,
    required this.titleLabels,
    required this.instructionLabels,
    this.minGroupSize = 2,
    this.maxGroupSize = 8,
    this.requiredVerbs = const {},
  });

  final String id;
  final Map<String, String> titleLabels;
  final Map<String, String> instructionLabels;
  final int minGroupSize;
  final int maxGroupSize;
  final Set<ActivityVerb> requiredVerbs;

  String titleFor(String locale) => _label(titleLabels, locale);

  String instructionFor(String locale) => _label(instructionLabels, locale);

  static String _label(Map<String, String> labels, String locale) {
    final raw = locale.replaceAll('_', '-').toLowerCase();
    final code = raw.startsWith('zh')
        ? (raw.contains('hant') || raw.contains('-hk') || raw.contains('-tw') || raw.contains('-mo')
            ? 'zh-Hant'
            : 'zh-Hans')
        : raw.split('-').first;
    return labels[code] ?? labels['en'] ?? '';
  }
}

class ActivityTemplates {
  const ActivityTemplates._();

  static const Map<String, ActivityTemplate> byId = {
    'activity.play_casual': ActivityTemplate(
      id: 'activity.play_casual',
      titleLabels: {
        'en': 'Play a casual round',
        'zh-Hant': '輕鬆玩一局',
        'zh-Hans': '轻松玩一局',
      },
      instructionLabels: {
        'en': 'Play together without making the score the main point.',
        'zh-Hant': '一齊輕鬆玩，唔需要將輸贏變成重點。',
        'zh-Hans': '一起轻松玩，不需要把输赢变成重点。',
      },
      requiredVerbs: {ActivityVerb.play},
    ),
    'activity.peer_teaches_beginner': ActivityTemplate(
      id: 'activity.peer_teaches_beginner',
      titleLabels: {
        'en': 'One knows, others discover',
        'zh-Hant': '一個識，其他人試',
        'zh-Hans': '一个会，其他人试',
      },
      instructionLabels: {
        'en': 'Let the experienced person show the group the three things a beginner needs first.',
        'zh-Hant': '由熟悉嗰個人帶其他人試，先教新手最需要知道嘅三樣嘢。',
        'zh-Hans': '由熟悉的人带其他人试，先教新手最需要知道的三件事。',
      },
      requiredVerbs: {ActivityVerb.learn},
    ),
    'activity.shared_mini_challenge': ActivityTemplate(
      id: 'activity.shared_mini_challenge',
      titleLabels: {
        'en': 'Make it a mini challenge',
        'zh-Hant': '整成一個小挑戰',
        'zh-Hans': '做成一个小挑战',
      },
      instructionLabels: {
        'en': 'Set one simple rule and complete a short challenge together.',
        'zh-Hant': '定一條簡單規則，一齊完成一個短挑戰。',
        'zh-Hans': '定一条简单规则，一起完成一个短挑战。',
      },
      requiredVerbs: {ActivityVerb.challenge},
    ),
    'activity.shared_exploration': ActivityTemplate(
      id: 'activity.shared_exploration',
      titleLabels: {
        'en': 'Explore together',
        'zh-Hant': '一齊探索',
        'zh-Hans': '一起探索',
      },
      instructionLabels: {
        'en': 'Pick a simple theme and explore it together at your own pace.',
        'zh-Hant': '揀一個簡單主題，用你哋自己嘅節奏一齊探索。',
        'zh-Hans': '选一个简单主题，用你们自己的节奏一起探索。',
      },
      requiredVerbs: {ActivityVerb.explore},
    ),
    'activity.make_and_compare': ActivityTemplate(
      id: 'activity.make_and_compare',
      titleLabels: {
        'en': 'Make it, then compare',
        'zh-Hant': '一齊整，再比較',
        'zh-Hans': '一起做，再比较',
      },
      instructionLabels: {
        'en': 'Each make your own version, then compare the choices you made.',
        'zh-Hant': '每人整自己版本，再比較大家點解會咁揀。',
        'zh-Hans': '每人做自己的版本，再比较大家为什么这样选。',
      },
      requiredVerbs: {ActivityVerb.make},
    ),
    'activity.create_together': ActivityTemplate(
      id: 'activity.create_together',
      titleLabels: {
        'en': 'Create something together',
        'zh-Hant': '一齊創作一樣嘢',
        'zh-Hans': '一起创作一样东西',
      },
      instructionLabels: {
        'en': 'Take turns adding one element until the group has made one shared result.',
        'zh-Hant': '輪流每人加一樣元素，最後一齊完成一個作品。',
        'zh-Hans': '轮流每人加一个元素，最后一起完成一个作品。',
      },
      requiredVerbs: {ActivityVerb.make},
    ),
    'activity.watch_and_compare': ActivityTemplate(
      id: 'activity.watch_and_compare',
      titleLabels: {
        'en': 'Watch, then compare',
        'zh-Hant': '一齊睇，再比較',
        'zh-Hans': '一起看，再比较',
      },
      instructionLabels: {
        'en': 'Watch a short piece together, then compare what each person noticed first.',
        'zh-Hant': '一齊睇一小段，再比較每個人第一時間留意到咩。',
        'zh-Hans': '一起看一小段，再比较每个人第一时间注意到什么。',
      },
      requiredVerbs: {ActivityVerb.watch},
    ),
    'activity.photo_theme_challenge': ActivityTemplate(
      id: 'activity.photo_theme_challenge',
      titleLabels: {
        'en': 'Photo theme challenge',
        'zh-Hant': '主題攝影挑戰',
        'zh-Hans': '主题摄影挑战',
      },
      instructionLabels: {
        'en': 'Choose one theme, take a small set of photos each, then reveal your favourite.',
        'zh-Hant': '揀一個主題，每人影幾張相，再揭曉自己最鍾意嗰張。',
        'zh-Hans': '选一个主题，每人拍几张照片，再揭晓自己最喜欢的一张。',
      },
      requiredVerbs: {ActivityVerb.make, ActivityVerb.challenge},
    ),
    'activity.listen_and_compare': ActivityTemplate(
      id: 'activity.listen_and_compare',
      titleLabels: {
        'en': 'Listen, then compare',
        'zh-Hant': '一齊聽，再比較',
        'zh-Hans': '一起听，再比较',
      },
      instructionLabels: {
        'en': 'Each person picks one track or short clip, then compare what grabbed your attention.',
        'zh-Hant': '每人揀一首歌或者一小段，一齊聽完再比較大家最留意咩。',
        'zh-Hans': '每人选一首歌或一小段，一起听完再比较大家最注意什么。',
      },
      requiredVerbs: {ActivityVerb.listen},
    ),
    'activity.read_and_compare': ActivityTemplate(
      id: 'activity.read_and_compare',
      titleLabels: {
        'en': 'Read, then compare',
        'zh-Hant': '一齊讀，再比較',
        'zh-Hans': '一起读，再比较',
      },
      instructionLabels: {
        'en': 'Pick a short piece or passage, read it together, then compare what each person noticed.',
        'zh-Hant': '揀一小段文字一齊讀，再比較每個人留意到嘅重點。',
        'zh-Hans': '选一小段文字一起读，再比较每个人注意到的重点。',
      },
      requiredVerbs: {ActivityVerb.read},
    ),

    'activity.browse_theme_challenge': ActivityTemplate(
      id: 'activity.browse_theme_challenge',
      titleLabels: {
        'en': 'Browse with a theme',
        'zh-Hant': '定個主題一齊行',
        'zh-Hans': '定个主题一起逛',
      },
      instructionLabels: {
        'en': 'Pick one playful theme, browse together, and each choose your best find. Buying anything is optional.',
        'zh-Hant': '先定一個有趣主題，一齊行一轉，每人揀自己最正嘅發現；唔一定要買嘢。',
        'zh-Hans': '先定一个有趣主题，一起逛一圈，每人选自己最好的发现；不一定要买东西。',
      },
      requiredVerbs: {ActivityVerb.explore, ActivityVerb.challenge},
    ),
    'activity.simple_wellness_reset': ActivityTemplate(
      id: 'activity.simple_wellness_reset',
      titleLabels: {
        'en': 'Take a simple reset together',
        'zh-Hant': '一齊做個簡單 reset',
        'zh-Hans': '一起做个简单 reset',
      },
      instructionLabels: {
        'en': 'Choose one gentle, low-pressure reset everyone is comfortable with, such as a short stretch, breathing break, or screen-free walk.',
        'zh-Hant': '揀一樣大家都舒服嘅輕鬆 reset，例如短時間拉筋、呼吸休息，或者放低手機行一陣。',
        'zh-Hans': '选一个大家都舒服的轻松 reset，例如短时间拉伸、呼吸休息，或者放下手机走一会儿。',
      },
      requiredVerbs: {ActivityVerb.practice},
    ),
    'activity.crossover_challenge': ActivityTemplate(
      id: 'activity.crossover_challenge',
      titleLabels: {
        'en': 'Mix two interests',
        'zh-Hant': '將兩個興趣混埋一齊',
        'zh-Hans': '把两个兴趣混在一起',
      },
      instructionLabels: {
        'en': 'Combine the two interests into one small activity or challenge that uses something from both.',
        'zh-Hant': '將兩個興趣各抽一樣元素，砌成一個大家一齊做到嘅小活動或者挑戰。',
        'zh-Hans': '从两个兴趣各取一个元素，组合成一个大家能一起完成的小活动或挑战。',
      },
    ),

  };
}

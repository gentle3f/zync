import 'dart:convert';

class ZyncAlias {
  const ZyncAlias._();

  static String displayName({
    required String nickname,
    required String localId,
    required String locale,
  }) {
    final trimmed = nickname.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return forId(localId, locale);
  }

  static String forId(String localId, String locale) {
    final lang = _language(locale);
    final words = _words[lang] ?? _words['en']!;
    final hash = _fnv1a(localId);
    final adjective = words.$1[hash % words.$1.length];
    final noun = words.$2[(hash ~/ 97) % words.$2.length];
    return lang.startsWith('zh') ? '$adjective$noun' : '$adjective $noun';
  }

  static String _language(String locale) {
    final value = locale.replaceAll('_', '-').toLowerCase();
    if (value.startsWith('zh')) {
      return value.contains('hans') || value.contains('-cn') || value.contains('-sg')
          ? 'zh-Hans'
          : 'zh-Hant';
    }
    for (final lang in ['ja', 'ko', 'es', 'fr', 'pt']) {
      if (value.startsWith(lang)) return lang;
    }
    return 'en';
  }

  static int _fnv1a(String value) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static const Map<String, (List<String>, List<String>)> _words = {
    'en': (
      [
        'Suspicious', 'Chaotic', 'Sleepy', 'Overcaffeinated', 'Emotional',
        'Extremely Serious', 'Questionable', 'Midnight', 'Weekend',
        'Unlicensed', 'Mildly Dangerous', 'Overthinking', 'Disco',
        'Part-Time', 'Secret', 'Unreasonably Confident',
      ],
      [
        'Capybara', 'Penguin', 'Hamster', 'Goose', 'Otter', 'Raccoon',
        'Potato', 'Toaster', 'Wizard', 'Ninja', 'Astronaut', 'Panda',
        'Goblin', 'Dumpling', 'Accountant', 'Vampire',
      ],
    ),
    'zh-Hant': (
      [
        '可疑', '暴躁', '失眠', '過度興奮', '認真', '神秘', '午夜',
        '週末', '兼職', '危險邊緣', '想太多', '迪士高', '無牌', '極度淡定',
      ],
      [
        '水豚', '企鵝', '倉鼠', '大鵝', '海獺', '浣熊', '薯仔', '多士爐',
        '巫師', '忍者', '太空人', '熊貓', '哥布林', '餃子', '會計師', '吸血鬼',
      ],
    ),
    'zh-Hans': (
      [
        '可疑', '暴躁', '失眠', '过度兴奋', '认真', '神秘', '午夜',
        '周末', '兼职', '危险边缘', '想太多', '迪斯科', '无证', '极度淡定',
      ],
      [
        '水豚', '企鹅', '仓鼠', '大鹅', '海獭', '浣熊', '土豆', '烤面包机',
        '巫师', '忍者', '宇航员', '熊猫', '哥布林', '饺子', '会计师', '吸血鬼',
      ],
    ),
    'ja': (
      ['怪しい', '眠たい', '深夜の', '週末限定', '考えすぎる', '妙に真面目な', '謎の', '無免許の'],
      ['カピバラ', 'ペンギン', 'ハムスター', 'ガチョウ', 'ラッコ', 'アライグマ', 'ポテト', '忍者'],
    ),
    'ko': (
      ['수상한', '졸린', '한밤중', '주말의', '생각이 많은', '지나치게 진지한', '정체불명', '무면허'],
      ['카피바라', '펭귄', '햄스터', '거위', '수달', '라쿤', '감자', '닌자'],
    ),
    'es': (
      ['Sospechoso', 'Caótico', 'Dormilón', 'Nocturno', 'Dramático', 'Serio', 'Misterioso', 'Ilegalmente Elegante'],
      ['Capibara', 'Pingüino', 'Hámster', 'Ganso', 'Nutria', 'Mapache', 'Patata', 'Ninja'],
    ),
    'fr': (
      ['Suspect', 'Chaotique', 'Endormi', 'Nocturne', 'Dramatique', 'Très Sérieux', 'Mystérieux', 'Sans Permis'],
      ['Capybara', 'Pingouin', 'Hamster', 'Oie', 'Loutre', 'Raton Laveur', 'Patate', 'Ninja'],
    ),
    'pt': (
      ['Suspeito', 'Caótico', 'Sonolento', 'Noturno', 'Dramático', 'Muito Sério', 'Misterioso', 'Sem Licença'],
      ['Capivara', 'Pinguim', 'Hamster', 'Ganso', 'Lontra', 'Guaxinim', 'Batata', 'Ninja'],
    ),
  };
}

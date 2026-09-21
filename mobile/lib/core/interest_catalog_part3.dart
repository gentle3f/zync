import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart3 = parseInterestCatalogRows(r'''media.anime|entertainment|anime_manga|10|Anime|日本動漫|日本动漫|anime;日漫
media.manga|entertainment|anime_manga|11|Manga|漫畫|漫画|
anime.jojo|entertainment|anime_manga|100|JoJo's Bizarre Adventure|JoJo的奇妙冒險|JoJo的奇妙冒险|jojo;ジョジョ
media.movies|entertainment|screen|12|Movies|電影|电影|film;cinema;戲劇電影
media.tv|entertainment|screen|13|TV Series|電視劇|电视剧|tv shows;series
music.pop|music|music_genres|16|Pop Music|流行音樂|流行音乐|pop
music.rock|music|music_genres|17|Rock Music|搖滾樂|摇滚乐|rock
music.classical|music|music_genres|18|Classical Music|古典音樂|古典音乐|classical
music.hip_hop|music|music_genres|330|Hip-Hop / Rap|嘻哈／饒舌|嘻哈／说唱|hip-hop;rap;嘻哈
music.r_and_b|music|music_genres|331|R&B|R&B 節奏藍調|R&B 节奏布鲁斯|
music.jazz|music|music_genres|332|Jazz|爵士樂|爵士乐|爵士
music.blues|music|music_genres|333|Blues|藍調|布鲁斯|
music.metal|music|music_genres|334|Metal|金屬樂|金属乐|
music.punk|music|music_genres|335|Punk|龐克音樂|朋克音乐|
music.indie|music|music_genres|336|Indie Music|獨立音樂|独立音乐|
music.alternative|music|music_genres|337|Alternative Music|另類音樂|另类音乐|
music.electronic|music|music_genres|338|Electronic Music|電子音樂|电子音乐|edm
music.house|music|music_genres|339|House Music|浩室音樂|House 音乐|
music.techno|music|music_genres|340|Techno|鐵克諾音樂|Techno 音乐|
music.trance|music|music_genres|341|Trance|Trance 電子音樂|Trance 电子音乐|
music.drum_and_bass|music|music_genres|342|Drum & Bass|鼓打貝斯|鼓打贝斯|dnb
music.k_pop|music|music_genres|343|K-Pop|K-Pop 韓國流行音樂|K-Pop 韩国流行音乐|韓國流行音樂;韩国流行音乐
music.j_pop|music|music_genres|344|J-Pop|J-Pop 日本流行音樂|J-Pop 日本流行音乐|日本流行音樂;日本流行音乐
music.cantopop|music|music_genres|345|Cantopop|廣東流行音樂|粤语流行音乐|廣東歌;广东歌
music.mandopop|music|music_genres|346|Mandopop|華語流行音樂|华语流行音乐|華語流行音樂;华语流行音乐
music.city_pop|music|music_genres|347|City Pop|City Pop 城市流行音樂|City Pop 城市流行音乐|
music.latin|music|music_genres|348|Latin Music|拉丁音樂|拉丁音乐|
music.reggae|music|music_genres|349|Reggae|雷鬼音樂|雷鬼音乐|
music.country|music|music_genres|350|Country Music|鄉村音樂|乡村音乐|
music.folk|music|music_genres|351|Folk Music|民謠|民谣|
music.world_music|music|music_genres|352|World Music|世界音樂|世界音乐|
music.soundtracks|music|music_genres|353|Film & Game Soundtracks|電影與遊戲配樂|电影与游戏配乐|ost
music.singing|music|music_making|360|Singing|唱歌|唱歌|唱歌
music.karaoke|music|music_making|361|Karaoke|卡拉 OK|卡拉 OK|卡拉OK
music.guitar|music|music_making|362|Guitar|結他|吉他|結他;吉他
music.piano|music|music_making|363|Piano|鋼琴|钢琴|鋼琴;钢琴
music.drums|music|music_making|364|Drums|鼓|鼓|鼓
music.bass_guitar|music|music_making|365|Bass Guitar|低音結他|贝斯|bass
music.violin|music|music_making|366|Violin|小提琴|小提琴|小提琴
music.cello|music|music_making|367|Cello|大提琴|大提琴|大提琴
music.ukulele|music|music_making|368|Ukulele|夏威夷小結他|尤克里里|夏威夷小結他
music.saxophone|music|music_making|369|Saxophone|色士風|萨克斯|色士風;萨克斯
music.djing|music|music_making|370|DJing|DJ 打碟|DJ 打碟|dj
music.music_production|music|music_making|371|Music Production|音樂製作|音乐制作|
music.songwriting|music|music_making|372|Songwriting|歌曲創作|歌曲创作|
music.concerts|music|music_making|373|Concerts & Live Music|演唱會與現場音樂|演唱会与现场音乐|演唱會;演唱会
music.vinyl|music|music_making|374|Vinyl Records|黑膠唱片|黑胶唱片|黑膠;黑胶
entertainment.documentaries|entertainment|screen|380|Documentaries|紀錄片|纪录片|紀錄片;纪录片
entertainment.comedy|entertainment|screen|381|Comedy|喜劇|喜剧|喜劇;喜剧
entertainment.horror|entertainment|screen|382|Horror Movies|恐怖電影|恐怖电影|恐怖片
entertainment.sci_fi|entertainment|screen|383|Science Fiction|科幻|科幻|sci-fi;科幻
entertainment.fantasy|entertainment|screen|384|Fantasy|奇幻|奇幻|奇幻
entertainment.action|entertainment|screen|385|Action Movies|動作電影|动作电影|動作片;动作片
entertainment.romance|entertainment|screen|386|Romance|愛情電影|爱情电影|愛情片;爱情片
entertainment.thriller|entertainment|screen|387|Thrillers|驚悚片|惊悚片|驚悚;惊悚
entertainment.crime|entertainment|screen|388|Crime Stories|犯罪故事|犯罪故事|犯罪
entertainment.animation|entertainment|screen|389|Animation|動畫|动画|動畫電影;动画电影
entertainment.musicals|entertainment|screen|390|Musicals|音樂劇|音乐剧|音樂劇;音乐剧
entertainment.independent_cinema|entertainment|screen|391|Independent Cinema|獨立電影|独立电影|indie film
entertainment.film_history|entertainment|screen|392|Film History|電影史|电影史|
entertainment.film_making|entertainment|screen|393|Filmmaking|電影製作|电影制作|電影製作;电影制作
entertainment.screenwriting|entertainment|screen|394|Screenwriting|編劇|编剧|
entertainment.webtoons|entertainment|anime_manga|400|Webtoons|網絡漫畫|网络漫画|網漫;网漫
entertainment.manhwa|entertainment|anime_manga|401|Manhwa|韓國漫畫|韩国漫画|韓漫;韩漫
entertainment.light_novels|entertainment|anime_manga|402|Light Novels|輕小說|轻小说|輕小說;轻小说
entertainment.cosplay|entertainment|anime_manga|403|Cosplay|角色扮演|角色扮演|角色扮演
entertainment.anime_figures|entertainment|anime_manga|404|Anime Figures|動漫模型|动漫手办|動漫模型;动漫手办
entertainment.ghibli|entertainment|anime_manga|405|Studio Ghibli|||吉卜力
entertainment.one_piece|entertainment|anime_manga|406|One Piece|||海賊王;航海王
entertainment.naruto|entertainment|anime_manga|407|Naruto|||火影忍者
entertainment.dragon_ball|entertainment|anime_manga|408|Dragon Ball|||龍珠;龙珠
entertainment.demon_slayer|entertainment|anime_manga|409|Demon Slayer|||鬼滅之刃;鬼灭之刃
entertainment.attack_on_titan|entertainment|anime_manga|410|Attack on Titan|||進擊的巨人;进击的巨人
entertainment.jujutsu_kaisen|entertainment|anime_manga|411|Jujutsu Kaisen|||咒術迴戰;咒术回战
entertainment.spy_x_family|entertainment|anime_manga|412|SPY x FAMILY|||間諜家家酒
entertainment.pokemon_anime|entertainment|anime_manga|413|Pokémon Anime|||寵物小精靈;宝可梦
entertainment.gundam|entertainment|anime_manga|414|Gundam|||高達;高达
entertainment.marvel|entertainment|pop_culture|420|Marvel|||漫威
entertainment.dc|entertainment|pop_culture|421|DC Comics|||
entertainment.star_wars|entertainment|pop_culture|422|Star Wars|||星球大戰;星球大战
entertainment.star_trek|entertainment|pop_culture|423|Star Trek|||
entertainment.harry_potter|entertainment|pop_culture|424|Harry Potter|||哈利波特
entertainment.lord_of_the_rings|entertainment|pop_culture|425|The Lord of the Rings|||lotr;魔戒
entertainment.disney|entertainment|pop_culture|426|Disney|||迪士尼
entertainment.pixar|entertainment|pop_culture|427|Pixar|||彼思;皮克斯
entertainment.k_drama|entertainment|pop_culture|428|K-Dramas|韓劇|韩剧|韓劇;韩剧
entertainment.c_drama|entertainment|pop_culture|429|Chinese Dramas|中國大陸劇集|中国大陆剧集|陸劇;陆剧
entertainment.j_drama|entertainment|pop_culture|430|Japanese Dramas|日劇|日剧|日劇;日剧
entertainment.reality_tv|entertainment|pop_culture|431|Reality TV|真人騷|真人秀|真人秀
entertainment.variety_shows|entertainment|pop_culture|432|Variety Shows|綜藝節目|综艺节目|綜藝;综艺''');

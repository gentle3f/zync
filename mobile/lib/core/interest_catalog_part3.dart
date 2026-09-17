import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart3 = parseInterestCatalogRows(r'''media.anime|entertainment|anime_manga|10|Anime|動畫|动漫|日本動畫;日本动漫
media.manga|entertainment|anime_manga|11|Manga|漫畫|漫画|
anime.jojo|entertainment|anime_manga|100|JoJo's Bizarre Adventure|JoJo的奇妙冒險|JoJo的奇妙冒险|jojo;ジョジョ
media.movies|entertainment|screen|12|Movies|電影|电影|film;cinema;戲劇電影
media.tv|entertainment|screen|13|TV Series|電視劇|电视剧|tv shows;series
music.pop|music|music_genres|16|Pop Music|流行音樂|流行音乐|pop
music.rock|music|music_genres|17|Rock Music|搖滾樂|摇滚乐|rock
music.classical|music|music_genres|18|Classical Music|古典音樂|古典音乐|classical
music.hip_hop|music|music_genres|330|Hip-Hop / Rap|||rap;嘻哈
music.r_and_b|music|music_genres|331|R&B|||
music.jazz|music|music_genres|332|Jazz|||爵士
music.blues|music|music_genres|333|Blues|||
music.metal|music|music_genres|334|Metal|||
music.punk|music|music_genres|335|Punk|||
music.indie|music|music_genres|336|Indie Music|||
music.alternative|music|music_genres|337|Alternative Music|||
music.electronic|music|music_genres|338|Electronic Music|||edm
music.house|music|music_genres|339|House Music|||
music.techno|music|music_genres|340|Techno|||
music.trance|music|music_genres|341|Trance|||
music.drum_and_bass|music|music_genres|342|Drum & Bass|||dnb
music.k_pop|music|music_genres|343|K-Pop|||韓國流行音樂;韩国流行音乐
music.j_pop|music|music_genres|344|J-Pop|||日本流行音樂;日本流行音乐
music.cantopop|music|music_genres|345|Cantopop|||廣東歌;广东歌
music.mandopop|music|music_genres|346|Mandopop|||華語流行音樂;华语流行音乐
music.city_pop|music|music_genres|347|City Pop|||
music.latin|music|music_genres|348|Latin Music|||
music.reggae|music|music_genres|349|Reggae|||
music.country|music|music_genres|350|Country Music|||
music.folk|music|music_genres|351|Folk Music|||
music.world_music|music|music_genres|352|World Music|||
music.soundtracks|music|music_genres|353|Film & Game Soundtracks|||ost
music.singing|music|music_making|360|Singing|||唱歌
music.karaoke|music|music_making|361|Karaoke|||卡拉OK
music.guitar|music|music_making|362|Guitar|||結他;吉他
music.piano|music|music_making|363|Piano|||鋼琴;钢琴
music.drums|music|music_making|364|Drums|||鼓
music.bass_guitar|music|music_making|365|Bass Guitar|||bass
music.violin|music|music_making|366|Violin|||小提琴
music.cello|music|music_making|367|Cello|||大提琴
music.ukulele|music|music_making|368|Ukulele|||夏威夷小結他
music.saxophone|music|music_making|369|Saxophone|||色士風;萨克斯
music.djing|music|music_making|370|DJing|||dj
music.music_production|music|music_making|371|Music Production|||
music.songwriting|music|music_making|372|Songwriting|||
music.concerts|music|music_making|373|Concerts & Live Music|||演唱會;演唱会
music.vinyl|music|music_making|374|Vinyl Records|||黑膠;黑胶
entertainment.documentaries|entertainment|screen|380|Documentaries|||紀錄片;纪录片
entertainment.comedy|entertainment|screen|381|Comedy|||喜劇;喜剧
entertainment.horror|entertainment|screen|382|Horror Movies|||恐怖片
entertainment.sci_fi|entertainment|screen|383|Science Fiction|||sci-fi;科幻
entertainment.fantasy|entertainment|screen|384|Fantasy|||奇幻
entertainment.action|entertainment|screen|385|Action Movies|||動作片;动作片
entertainment.romance|entertainment|screen|386|Romance|||愛情片;爱情片
entertainment.thriller|entertainment|screen|387|Thrillers|||驚悚;惊悚
entertainment.crime|entertainment|screen|388|Crime Stories|||犯罪
entertainment.animation|entertainment|screen|389|Animation|||動畫電影;动画电影
entertainment.musicals|entertainment|screen|390|Musicals|||音樂劇;音乐剧
entertainment.independent_cinema|entertainment|screen|391|Independent Cinema|||indie film
entertainment.film_history|entertainment|screen|392|Film History|||
entertainment.film_making|entertainment|screen|393|Filmmaking|||電影製作;电影制作
entertainment.screenwriting|entertainment|screen|394|Screenwriting|||
entertainment.webtoons|entertainment|anime_manga|400|Webtoons|||網漫;网漫
entertainment.manhwa|entertainment|anime_manga|401|Manhwa|||韓漫;韩漫
entertainment.light_novels|entertainment|anime_manga|402|Light Novels|||輕小說;轻小说
entertainment.cosplay|entertainment|anime_manga|403|Cosplay|||角色扮演
entertainment.anime_figures|entertainment|anime_manga|404|Anime Figures|||動漫模型;动漫手办
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
entertainment.k_drama|entertainment|pop_culture|428|K-Dramas|||韓劇;韩剧
entertainment.c_drama|entertainment|pop_culture|429|Chinese Dramas|||陸劇;陆剧
entertainment.j_drama|entertainment|pop_culture|430|Japanese Dramas|||日劇;日剧
entertainment.reality_tv|entertainment|pop_culture|431|Reality TV|||真人秀
entertainment.variety_shows|entertainment|pop_culture|432|Variety Shows|||綜藝;综艺''');

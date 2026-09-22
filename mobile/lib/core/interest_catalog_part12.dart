import 'interest_catalog_parser.dart';
import 'models.dart';

/// Everyday/offline breadth expansion: movement, dance, outdoors, making and
/// community interests chosen for icebreaking, Zync Now and future hobby-economy
/// use. Generic concepts only; branded/title affinities stay in rights-aware
/// partner policy paths.
final List<InterestDefinition> kInterestCatalogPart12 = parseInterestCatalogRows(r'''
wellness.barre|wellness|fitness|1100|Barre|芭蕾塑形|芭蕾塑形|barre workout;barre class
wellness.powerlifting|wellness|fitness|1101|Powerlifting|力量舉|力量举|power lifting
wellness.kettlebell_training|wellness|fitness|1102|Kettlebell Training|壺鈴訓練|壶铃训练|kettlebells;kettlebell workout
wellness.functional_training|wellness|fitness|1103|Functional Training|功能性訓練|功能性训练|functional fitness
wellness.tai_chi|wellness|mind_body|1105|Tai Chi|太極|太极|taiji;太極拳;太极拳
sports.obstacle_course_racing|sports|running|1110|Obstacle Course Racing|障礙賽跑|障碍赛跑|ocr;obstacle racing
sports.parkour|sports|fitness|1111|Parkour|跑酷|跑酷|parkour training
sports.freerunning|sports|fitness|1112|Freerunning|自由跑酷|自由跑酷|free running
sports.gymnastics|sports|fitness|1113|Gymnastics|體操|体操|gymnastic
sports.trampolining|sports|fitness|1114|Trampolining|彈床運動|蹦床运动|trampoline;trampoline sports
sports.cheerleading|sports|fitness|1115|Cheerleading|啦啦隊運動|啦啦队运动|cheer
sports.aikido|sports|combat|1116|Aikido|合氣道|合气道|合氣道;合气道
sports.capoeira|sports|combat|1117|Capoeira|卡波耶拉|卡波耶拉|capoeira martial art
sports.wushu|sports|combat|1118|Wushu|武術|武术|Chinese martial arts;武術;武术
sports.ultimate_frisbee|sports|disc_sports|1119|Ultimate Frisbee|極限飛盤|极限飞盘|ultimate;ultimate disc
sports.disc_golf|sports|disc_sports|1120|Disc Golf|飛盤高爾夫|飞盘高尔夫|frisbee golf
sports.water_polo|sports|team_ball|1121|Water Polo|水球|水球|waterpolo
sports.sepak_takraw|sports|team_ball|1122|Sepak Takraw|藤球|藤球|takraw
sports.floorball|sports|team_ball|1123|Floorball|地板球|地板球|floor ball
sports.horse_riding|sports|equestrian|1124|Horse Riding|騎馬|骑马|horseback riding;equestrian;馬術;马术
arts.salsa_dancing|arts|dance|1130|Salsa Dancing|莎莎舞|萨尔萨舞|salsa dance
arts.bachata_dancing|arts|dance|1131|Bachata Dancing|巴恰塔舞|巴恰塔舞|bachata dance
arts.ballroom_dancing|arts|dance|1132|Ballroom Dancing|交誼舞|交谊舞|ballroom dance
arts.swing_dancing|arts|dance|1133|Swing Dancing|搖擺舞|摇摆舞|swing dance
arts.hip_hop_dance|arts|dance|1134|Hip-Hop Dance|嘻哈舞|嘻哈舞|hip hop dancing;street dance
arts.ballet|arts|dance|1135|Ballet|芭蕾舞|芭蕾舞|ballet dancing
arts.contemporary_dance|arts|dance|1136|Contemporary Dance|當代舞|当代舞|contemporary dancing
arts.jazz_dance|arts|dance|1137|Jazz Dance|爵士舞|爵士舞|jazz dancing
arts.tap_dance|arts|dance|1138|Tap Dance|踢踏舞|踢踏舞|tap dancing
arts.line_dancing|arts|dance|1139|Line Dancing|排舞|排舞|line dance
arts.kpop_dance|arts|dance|1140|K-Pop Dance|K-Pop 舞蹈|K-Pop 舞蹈|kpop dance;k-pop dancing
arts.latin_dance|arts|dance|1141|Latin Dance|拉丁舞|拉丁舞|latin dancing
arts.belly_dance|arts|dance|1142|Belly Dance|肚皮舞|肚皮舞|belly dancing
arts.flamenco_dance|arts|dance|1143|Flamenco Dance|佛蘭明高舞|弗拉门戈舞|flamenco dancing
arts.pole_dance|arts|dance|1144|Pole Dance|鋼管舞|钢管舞|pole dancing
outdoors.nordic_walking|outdoors|hiking|1150|Nordic Walking|北歐健走|北欧健走|pole walking
outdoors.beachcombing|outdoors|hiking|1151|Beachcombing|海灘尋寶|海滩寻宝|beach combing
outdoors.tide_pooling|outdoors|water|1152|Tide Pooling|潮池探索|潮池探索|rock pooling;tide pools
outdoors.fishing|outdoors|water|1153|Fishing|釣魚|钓鱼|angling
outdoors.fly_fishing|outdoors|water|1154|Fly Fishing|飛蠅釣魚|飞蝇钓鱼|flyfishing
outdoors.rockhounding|outdoors|hiking|1155|Rockhounding|岩石礦物採集|岩石矿物采集|rock collecting in nature
outdoors.fossil_hunting|outdoors|hiking|1156|Fossil Hunting|尋找化石|寻找化石|fossil hunting outdoors
outdoors.forest_bathing|outdoors|hiking|1157|Forest Bathing|森林浴|森林浴|shinrin-yoku;forest therapy
outdoors.urban_exploration|outdoors|hiking|1158|Urban Exploration|城市探索|城市探索|urbex
outdoors.caving|outdoors|hiking|1159|Caving|洞穴探險|洞穴探险|spelunking;cave exploration
outdoors.whitewater_rafting|outdoors|water|1160|Whitewater Rafting|激流泛舟|激流漂流|rafting;white water rafting
outdoors.whitewater_kayaking|outdoors|water|1161|Whitewater Kayaking|激流獨木舟|激流皮划艇|white water kayaking
outdoors.boating|outdoors|water|1162|Boating|船艇活動|船艇活动|recreational boating
outdoors.jet_skiing|outdoors|water|1163|Jet Skiing|水上電單車|水上摩托|personal watercraft;pwc
outdoors.spearfishing|outdoors|water|1164|Spearfishing|魚叉潛水捕魚|鱼叉潜水捕鱼|spear fishing
arts.screen_printing|arts|visual_art|1170|Screen Printing|絲網印刷|丝网印刷|silkscreen;screenprint
arts.linocut|arts|visual_art|1171|Linocut|油氈版畫|油毡版画|linoleum print;linocut printmaking
arts.collage|arts|visual_art|1172|Collage|拼貼藝術|拼贴艺术|collage art
arts.mixed_media|arts|visual_art|1173|Mixed Media Art|混合媒材藝術|混合媒介艺术|mixed media
crafts.wood_carving|crafts|crafts|1174|Wood Carving|木雕|木雕|woodcarving
crafts.whittling|crafts|crafts|1175|Whittling|削木雕刻|削木雕刻|wood whittling
crafts.resin_art|crafts|crafts|1176|Resin Art|樹脂藝術|树脂艺术|epoxy resin art
crafts.perfume_making|crafts|crafts|1177|Perfume Making|調香與香水製作|调香与香水制作|perfume blending;fragrance making
crafts.bookbinding|crafts|crafts|1178|Bookbinding|手工書籍裝訂|手工书籍装订|book binding
crafts.paper_crafts|crafts|crafts|1179|Paper Crafts|紙藝|纸艺|papercraft;paper crafting
crafts.paper_quilling|crafts|crafts|1180|Paper Quilling|捲紙藝術|衍纸艺术|quilling;paper filigree
crafts.macrame|crafts|crafts|1181|Macrame|編結藝術|编结艺术|macramé;knotting craft
crafts.weaving|crafts|crafts|1182|Weaving|織布|织布|loom weaving
crafts.quilting|crafts|crafts|1183|Quilting|拼布|拼布|patchwork quilting
crafts.cross_stitch|crafts|crafts|1184|Cross Stitch|十字繡|十字绣|cross-stitch
crafts.needle_felting|crafts|crafts|1185|Needle Felting|羊毛氈|羊毛毡|wool felting;felting
crafts.beading|crafts|crafts|1186|Beading|串珠|串珠|beadwork;bead making
crafts.model_kit_building|crafts|crafts|1187|Model Kit Building|模型套件製作|拼装模型|model kits;plastic models
crafts.cosplay_making|crafts|crafts|1188|Cosplay Making|Cosplay 服裝製作|Cosplay 服装制作|cosplay crafting;costume making
fashion.fashion_design|fashion|fashion|1189|Fashion Design|時裝設計|时装设计|clothing design
fashion.pattern_making|fashion|fashion|1190|Pattern Making|紙樣製作|服装打版|sewing patterns;garment pattern making
crafts.upholstery|crafts|crafts|1191|Upholstery|傢俬包布與翻新|家具软包与翻新|furniture upholstery
learning.language_exchange|learning|languages|1200|Language Exchange|語言交換|语言交换|language swap;conversation exchange
sports.run_clubs|sports|running|1201|Run Clubs|跑步會|跑团|running club;run club
lifestyle.supper_clubs|lifestyle|social|1202|Supper Clubs|飯局與晚餐會|饭局与晚餐会|dinner clubs;dinner club;supper club
lifestyle.coffee_chats|lifestyle|social|1203|Coffee Chats|咖啡聊天|咖啡聊天|coffee chat;coffee meetup
lifestyle.open_mic_nights|lifestyle|social|1204|Open Mic Nights|開放咪之夜|开放麦之夜|open mic;open-mic night
lifestyle.poetry_slams|lifestyle|social|1205|Poetry Slams|詩歌擂台|诗歌朗诵赛|poetry slam;spoken word night
lifestyle.improv_comedy|lifestyle|social|1206|Improv Comedy|即興喜劇|即兴喜剧|improv;improvisational comedy
entertainment.theatre_going|entertainment|screen|1207|Theatre Going|睇舞台劇|看舞台剧|live theatre;theater going;stage plays;theatre;theater
business.coworking|business|business|1208|Coworking|共享工作|联合办公|co-working;coworking spaces;coworking events
lifestyle.digital_nomad_meetups|lifestyle|social|1209|Digital Nomad Meetups|數碼遊牧聚會|数字游民聚会|digital nomad meetup;nomad meetups
lifestyle.expat_meetups|lifestyle|social|1210|Expat Meetups|海外生活者聚會|外籍人士聚会|expat meetup;expat community
lifestyle.international_meetups|lifestyle|social|1211|International Meetups|國際交流聚會|国际交流聚会|international meetup;international social
lifestyle.cultural_exchange|lifestyle|social|1212|Cultural Exchange|文化交流|文化交流|cross-cultural exchange
lifestyle.charity_work|lifestyle|social|1213|Charity Work|慈善活動|慈善活动|charity;charitable work
lifestyle.community_gardening|lifestyle|social|1214|Community Gardening|社區園藝|社区园艺|community garden
lifestyle.animal_volunteering|lifestyle|social|1215|Animal Volunteering|動物義工|动物志愿服务|animal volunteer;animal shelter volunteering
lifestyle.environmental_volunteering|lifestyle|social|1216|Environmental Volunteering|環保義工|环保志愿服务|environment volunteer;conservation volunteering
lifestyle.beach_cleanups|lifestyle|social|1217|Beach Cleanups|淨灘|净滩|beach cleanup;coastal cleanup
wellness.foam_rolling|wellness|recovery|1220|Foam Rolling|泡沫軸放鬆|泡沫轴放松|foam roller;myofascial release
wellness.stress_management|wellness|mind_body|1221|Stress Management|壓力管理|压力管理|stress relief
wellness.sports_recovery|wellness|recovery|1222|Sports Recovery|運動恢復|运动恢复|athletic recovery;post-workout recovery
''');

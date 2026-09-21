import 'interest_catalog_parser.dart';
import 'models.dart';

/// Third everyday-breadth tranche: home/family life, performance, nature,
/// puzzles, mobility, creator skills, local community, learning and practical
/// finance. Brand-specific affinities remain outside this generic batch.
final List<InterestDefinition> kInterestCatalogPart14 = parseInterestCatalogRows(r'''
lifestyle.home_improvement|lifestyle|home|1420|Home Improvement|家居維修與改善|家居维修与改善|home diy;home improvement projects
lifestyle.diy_renovation|lifestyle|home|1421|DIY Renovation|DIY 裝修|DIY 装修|home renovation;renovating
lifestyle.decluttering|lifestyle|home|1422|Decluttering|斷捨離與整理|断舍离与整理|declutter;decluttering home
lifestyle.sustainable_living|lifestyle|home|1423|Sustainable Living|可持續生活|可持续生活|eco living;green living
lifestyle.zero_waste|lifestyle|home|1424|Zero Waste|零廢生活|零废生活|low waste;zero-waste living
lifestyle.composting|lifestyle|home|1425|Composting|堆肥|堆肥|home composting
lifestyle.balcony_gardening|lifestyle|home|1426|Balcony Gardening|露台園藝|阳台园艺|balcony garden
lifestyle.urban_gardening|lifestyle|home|1427|Urban Gardening|城市園藝|城市园艺|city gardening
lifestyle.hydroponics|lifestyle|home|1428|Hydroponics|水耕種植|水培种植|hydroponic gardening
lifestyle.furniture_restoration|lifestyle|home|1429|Furniture Restoration|傢俬修復|家具修复|furniture refinishing;furniture repair
lifestyle.upcycling|lifestyle|home|1430|Upcycling|升級再造|升级再造|creative reuse
lifestyle.thrift_flipping|lifestyle|shopping|1431|Thrift Flipping|二手改造|二手改造|thrift flip;upcycling clothes
fashion.barbering|fashion|fashion|1440|Barbering|理髮技巧|理发技巧|barber;barbering skills
fashion.mens_grooming|fashion|fashion|1441|Men's Grooming|男士儀容|男士护理|mens grooming;male grooming
fashion.personal_styling|fashion|fashion|1442|Personal Styling|個人造型|个人造型|personal stylist;styling outfits
fashion.color_analysis|fashion|fashion|1443|Color Analysis|個人色彩分析|个人色彩分析|colour analysis;personal color
fashion.tattoo_art|fashion|fashion|1444|Tattoo Art|紋身藝術|纹身艺术|tattoos;tattoo culture
fashion.piercings|fashion|fashion|1445|Piercings|穿環與穿孔|穿孔与穿环|body piercing;piercing culture
lifestyle.parenting|lifestyle|family|1450|Parenting|育兒|育儿|parenthood;raising kids
lifestyle.family_activities|lifestyle|family|1451|Family Activities|親子活動|亲子活动|family time;family outings
lifestyle.kids_activities|lifestyle|family|1452|Kids Activities|兒童活動|儿童活动|activities for kids
lifestyle.playgroups|lifestyle|family|1453|Playgroups|親子遊戲小組|亲子游戏小组|play group;parent child playgroup
lifestyle.parent_meetups|lifestyle|family|1454|Parent Meetups|家長聚會|家长聚会|parent groups;parents meetup
lifestyle.homeschooling|lifestyle|family|1455|Homeschooling|在家教育|在家教育|home education;homeschool
lifestyle.storytime|lifestyle|family|1456|Storytime|親子故事時間|亲子故事时间|story time;reading to kids
lifestyle.babywearing|lifestyle|family|1457|Babywearing|揹帶育兒|背带育儿|baby wearing;baby carrier
arts.acting|arts|performance|1470|Acting|演戲與表演|表演与演戏|theatre acting;stage acting;screen acting
arts.voice_acting|arts|performance|1471|Voice Acting|配音|配音|voice actor;voiceover acting
arts.magic_performance|arts|performance|1472|Magic Performance|魔術表演|魔术表演|magic tricks;magician
arts.juggling|arts|performance|1473|Juggling|雜耍|杂耍|juggler
arts.circus_arts|arts|performance|1474|Circus Arts|馬戲藝術|马戏艺术|circus skills
arts.puppetry|arts|performance|1475|Puppetry|木偶與布偶表演|木偶与布偶表演|puppet making;puppet theatre
arts.comedy_writing|arts|writing|1476|Comedy Writing|喜劇寫作|喜剧写作|writing comedy;comedy scripts
arts.stage_production|arts|performance|1477|Stage Production|舞台製作|舞台制作|theatre production;stagecraft
arts.musical_theatre|arts|performance|1478|Musical Theatre|音樂劇|音乐剧|musical theater
arts.storytelling|arts|performance|1479|Storytelling|說故事與故事演繹|讲故事与故事表演|oral storytelling;story teller
outdoors.wildlife_watching|outdoors|hiking|1490|Wildlife Watching|野生動物觀察|野生动物观察|wildlife spotting
outdoors.whale_watching|outdoors|water|1491|Whale Watching|賞鯨|观鲸|whalewatching
outdoors.dolphin_watching|outdoors|water|1492|Dolphin Watching|賞海豚|观海豚|dolphin spotting
outdoors.butterfly_watching|outdoors|hiking|1493|Butterfly Watching|賞蝶|观蝶|butterfly spotting
outdoors.mushroom_hunting|outdoors|hiking|1494|Mushroom Hunting|尋找野生菇菌|寻找野生蘑菇|mushroom foraging;mushroom spotting
science.mycology|science|science|1495|Mycology|真菌學|真菌学|fungi;fungus science
outdoors.beach_ecology|outdoors|water|1496|Beach Ecology|海岸生態|海岸生态|coastal ecology;shore ecology
outdoors.marine_life|outdoors|water|1497|Marine Life|海洋生物觀察|海洋生物观察|sea life;marine wildlife
arts.nature_journaling|arts|writing|1498|Nature Journaling|自然觀察日記|自然观察日记|nature journal
arts.nature_sketching|arts|visual_art|1499|Nature Sketching|自然速寫|自然速写|nature drawing;field sketching
outdoors.tree_identification|outdoors|hiking|1500|Tree Identification|樹木辨識|树木识别|tree id;identifying trees
outdoors.plant_identification|outdoors|hiking|1501|Plant Identification|植物辨識|植物识别|plant id;identifying plants
learning.jigsaw_puzzles|learning|knowledge|1510|Jigsaw Puzzles|拼圖|拼图|jigsaws;jigsaw puzzle
learning.logic_puzzles|learning|knowledge|1511|Logic Puzzles|邏輯謎題|逻辑谜题|logic games;logic puzzle
learning.puzzle_hunts|learning|knowledge|1512|Puzzle Hunts|謎題尋寶|谜题寻宝|puzzle hunt
gaming.escape_room_design|gaming|gaming_general|1513|Escape Room Design|密室設計|密室设计|designing escape rooms
gaming.game_streaming|gaming|gaming_general|1515|Game Streaming|遊戲直播|游戏直播|streaming games;game streamer
gaming.lan_parties|gaming|gaming_general|1516|LAN Parties|LAN 遊戲聚會|LAN 游戏聚会|lan party;local multiplayer parties
transport.urban_mobility|transport|cars|1530|Urban Mobility|城市出行|城市出行|city mobility;micromobility
transport.van_conversion|transport|cars|1531|Van Conversion|客貨車露營改裝|厢式车露营改装|camper conversion;van build
transport.car_camping|transport|cars|1532|Car Camping|車中露營|车中露营|sleeping in car;vehicle camping
transport.overlanding|transport|cars|1533|Overlanding|長途越野旅行|长途越野旅行|overland travel;overland driving
transport.pilot_training|transport|cars|1534|Pilot Training|飛行訓練|飞行训练|learning to fly;flight training
arts.motion_graphics|arts|media_creation|1550|Motion Graphics|動態圖像設計|动态图形设计|motion design
arts.animation_production|arts|media_creation|1551|Animation Production|動畫製作|动画制作|making animation;animation making
arts.fan_art|arts|visual_art|1552|Fan Art|粉絲創作與同人圖|粉丝创作与同人图|fanart;fan illustration
arts.character_design|arts|visual_art|1553|Character Design|角色設計|角色设计|character art
arts.webcomics|arts|media_creation|1554|Webcomics|網絡漫畫創作|网络漫画创作|web comics;webcomic creation
arts.zine_making|arts|media_creation|1555|Zine Making|Zine 小誌製作|独立小志制作|zines;indie magazine making
arts.sticker_making|arts|media_creation|1556|Sticker Making|貼紙設計製作|贴纸设计制作|sticker design;making stickers
arts.photo_retouching|arts|photography|1558|Photo Retouching|相片精修|照片精修|retouching photos;photo retouching
arts.sound_design|arts|media_creation|1559|Sound Design|聲音設計|声音设计|sound designer
arts.audio_editing|arts|media_creation|1560|Audio Editing|音訊剪輯|音频剪辑|sound editing;audio editor
arts.voiceover|arts|media_creation|1561|Voiceover|旁白錄音|旁白录音|voice over;narration recording
arts.online_video_creation|arts|media_creation|1562|Online Video Creation|網上影片創作|在线视频创作|youtube creation;online videos creator
arts.short_form_video|arts|media_creation|1563|Short-form Video|短影片創作|短视频创作|short form video;reels creation;vertical video
lifestyle.local_community|lifestyle|social|1581|Local Community|本地社群|本地社群|neighborhood community;local groups
lifestyle.community_organizing|lifestyle|social|1582|Community Organizing|社區組織|社区组织|community building;organising community
learning.mentoring|learning|knowledge|1583|Mentoring|導師交流|导师交流|mentorship;being a mentor
learning.peer_learning|learning|knowledge|1584|Peer Learning|同儕學習|同伴学习|learning together;peer education
learning.skill_sharing|learning|knowledge|1585|Skill Sharing|技能交流|技能分享|skill swap;teach each other
learning.study_groups|learning|knowledge|1586|Study Groups|溫習小組|学习小组|study group;revision group
business.founder_meetups|business|business|1587|Founder Meetups|創業者聚會|创业者聚会|founder meetup;entrepreneur meetup
business.startup_meetups|business|business|1588|Startup Meetups|初創聚會|创业聚会|startup meetup;startup community
business.tech_meetups|business|business|1589|Tech Meetups|科技聚會|科技聚会|technology meetup;developer meetup
lifestyle.book_swaps|lifestyle|social|1590|Book Swaps|換書|换书|book exchange;book swap
lifestyle.clothing_swaps|lifestyle|social|1591|Clothing Swaps|換衫活動|换衣活动|clothes swap;clothing exchange
lifestyle.repair_workshops|lifestyle|social|1592|Repair Workshops|維修工作坊|维修工作坊|repair meetup;fix-it workshop
technology.makerspaces|technology|hardware|1593|Makerspaces|創客空間|创客空间|maker space;hackerspace
wellness.sleep_tracking|wellness|mind_body|1610|Sleep Tracking|睡眠追蹤|睡眠追踪|sleep tracker;sleep data
wellness.walking_groups|wellness|fitness|1611|Walking Groups|步行小組|步行小组|walking club;walking group
wellness.mindful_walking|wellness|mind_body|1612|Mindful Walking|正念步行|正念步行|walking meditation
wellness.posture_training|wellness|fitness|1613|Posture Training|姿勢訓練|姿势训练|posture correction;posture exercises
learning.brain_teasers|learning|knowledge|1630|Brain Teasers|腦筋急轉彎|脑筋急转弯|brainteasers
learning.memory_training|learning|knowledge|1631|Memory Training|記憶訓練|记忆训练|memory techniques
learning.speed_reading|learning|knowledge|1632|Speed Reading|速讀|速读|fast reading
learning.note_taking|learning|knowledge|1633|Note Taking|筆記方法|笔记方法|note-taking;notes system
learning.study_skills|learning|knowledge|1634|Study Skills|學習方法|学习方法|study techniques;learning skills
learning.math_puzzles|learning|knowledge|1635|Math Puzzles|數學謎題|数学谜题|mathematical puzzles
learning.philosophy_discussions|learning|knowledge|1636|Philosophy Discussions|哲學討論|哲学讨论|philosophy group;philosophy talks
learning.science_communication|learning|knowledge|1637|Science Communication|科普傳播|科普传播|science outreach;popular science communication
learning.museum_learning|learning|knowledge|1638|Museum Learning|博物館學習|博物馆学习|museum education
business.value_investing|business|business|1650|Value Investing|價值投資|价值投资|value investor
business.dividend_investing|business|business|1651|Dividend Investing|股息投資|股息投资|dividend stocks
business.index_investing|business|business|1652|Index Investing|指數投資|指数投资|index funds;passive investing
business.real_estate_investing|business|business|1653|Real Estate Investing|房地產投資|房地产投资|property investing;real estate investor
business.budgeting|business|business|1654|Budgeting|理財預算|理财预算|personal budgeting;budget planning
business.saving_money|business|business|1655|Saving Money|儲蓄|储蓄|saving;money saving
business.financial_independence|business|business|1656|Financial Independence|財務自由|财务自由|financial freedom
business.fire_movement|business|business|1657|FIRE Movement|FIRE 財務自由|FIRE 财务自由|financial independence retire early;fire
food.cooking_classes|food|cooking|1670|Cooking Classes|烹飪班|烹饪课|cooking class;cookery classes
food.baking_classes|food|cooking|1671|Baking Classes|烘焙班|烘焙课|baking class
food.potlucks|food|food/dining|1672|Potlucks|百樂餐與自帶菜聚會|百乐餐与自带菜聚会|potluck;bring a dish
food.recipe_swaps|food|cooking|1673|Recipe Swaps|食譜交流|食谱交流|recipe exchange;sharing recipes
food.omakase|food|food/dining|1674|Omakase|廚師發辦|日式无菜单料理|omakase dining
travel.walking_tours|travel|travel/styles|1690|Walking Tours|步行導賞|步行导览|walking tour
travel.architecture_tours|travel|travel/styles|1691|Architecture Tours|建築導賞|建筑导览|architecture tour
travel.heritage_walks|travel|travel/styles|1692|Heritage Walks|古蹟漫步|历史文化步行|heritage walking;heritage tour
travel.local_food_tours|travel|travel/styles|1693|Local Food Tours|本地美食導賞|本地美食导览|food walking tour;local food tour
lifestyle.museum_hopping|lifestyle|social|1694|Museum Hopping|博物館巡遊|博物馆巡游|museum crawl;museums hopping
lifestyle.gallery_hopping|lifestyle|social|1695|Gallery Hopping|畫廊巡遊|画廊巡游|gallery crawl;art gallery hopping
travel.street_art_tours|travel|travel/styles|1696|Street Art Tours|街頭藝術導賞|街头艺术导览|street art tour
arts.photo_walks|arts|photography|1697|Photo Walks|攝影散步|摄影散步|photo walk;photowalk
travel.history_walks|travel|travel/styles|1698|History Walks|歷史導賞步行|历史步行导览|historical walk;history tour
travel.temple_visits|travel|travel/styles|1699|Temple Visits|寺廟參觀|寺庙参观|temple hopping;visiting temples
lifestyle.cultural_festivals|lifestyle|social|1700|Cultural Festivals|文化節慶|文化节庆|culture festivals;heritage festival
lifestyle.craft_markets|lifestyle|social|1701|Craft Markets|手作市集|手作市集|craft fair;makers market
lifestyle.art_fairs|lifestyle|social|1702|Art Fairs|藝術博覽會|艺术博览会|art fair
''');

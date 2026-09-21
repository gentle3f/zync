import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart9 = List.unmodifiable([
  ...parseInterestFamily(
    idPrefix: 'music.style',
    category: 'music',
    cluster: 'music/styles',
    rankStart: 3100,
    raw: r'''
Alternative Rock|另類搖滾|另类摇滚
Indie Rock|獨立搖滾|独立摇滚
Indie Pop|獨立流行|独立流行
Dream Pop|夢幻流行|dreamy pop|梦幻流行
Shoegaze|瞪鞋搖滾|盯鞋摇滚
Britpop|英倫搖滾|英伦摇滚
Grunge|垃圾搖滾|垃圾摇滚
Post-Grunge|後垃圾搖滾|后垃圾摇滚
Post-Rock|後搖滾|后摇滚
Progressive Rock|前衛搖滾|前卫摇滚
Art Rock|藝術搖滾|艺术摇滚
Psychedelic Rock|迷幻搖滾|迷幻摇滚
Garage Rock|車庫搖滾|车库摇滚
Hard Rock|硬搖滾|硬摇滚
Classic Rock|經典搖滾|经典摇滚
Southern Rock|南方搖滾|南方摇滚
Glam Rock|華麗搖滾|华丽摇滚
Arena Rock|競技場搖滾|竞技场摇滚
Math Rock|數學搖滾|数学摇滚
Noise Rock|噪音搖滾|噪音摇滚
Space Rock|太空搖滾|太空摇滚
Surf Rock|衝浪搖滾|冲浪摇滚
Rockabilly|洛卡比里搖滾|洛卡比里摇滚
Punk Rock|龐克搖滾|朋克摇滚
Hardcore Punk|硬核龐克|硬核朋克
Pop Punk|流行龐克|流行朋克
Post-Punk|後龐克|后朋克
New Wave|新浪潮音樂|新浪潮音乐
Emo|情緒搖滾|情绪摇滚
Emo Pop|情緒流行|情绪流行
Screamo|嘶吼情緒搖滾|嘶吼情绪摇滚
Goth Rock|哥德搖滾|哥特摇滚
Industrial Rock|工業搖滾|工业摇滚
Metalcore|金屬核|金属核
Deathcore|死核|死核
Heavy Metal|重金屬|重金属
Thrash Metal|鞭擊金屬|激流金属
Death Metal|死亡金屬|死亡金属
Black Metal|黑金屬|黑金属
Doom Metal|厄運金屬|厄运金属
Power Metal|力量金屬|力量金属
Symphonic Metal|交響金屬|交响金属
Progressive Metal|前衛金屬|前卫金属
Nu Metal|新金屬|新金属
Alternative Metal|另類金屬|另类金属
Folk Metal|民謠金屬|民谣金属
Viking Metal|維京金屬|维京金属
Glam Metal|華麗金屬|华丽金属
Metal Ballads|金屬抒情曲|金属抒情曲
Power Pop|強力流行|强力流行
Synthpop|合成器流行|合成器流行
Electropop|電子流行|电子流行
Hyperpop|超流行|超流行
Bedroom Pop|臥室流行|卧室流行
Chamber Pop|室內流行樂|室内流行乐
Baroque Pop|巴洛克流行|巴洛克流行
Art Pop|藝術流行|艺术流行
Teen Pop|青少年流行|青少年流行
Dance Pop|舞曲流行|舞曲流行
Indie Folk|獨立民謠|独立民谣
Folk Rock|民謠搖滾|民谣摇滚
Singer-Songwriter|創作歌手|创作歌手
Americana|美國根源音樂|美国根源音乐
Bluegrass|藍草音樂|蓝草音乐
Contemporary Country|當代鄉村音樂|当代乡村音乐
Alt-Country|另類鄉村音樂|另类乡村音乐
Country Pop|鄉村流行|乡村流行
Country Rock|鄉村搖滾|乡村摇滚
Honky-Tonk|酒館鄉村音樂|酒馆乡村音乐
Old-Time Music|美國傳統民間音樂|美国传统民间音乐
Delta Blues|三角洲藍調|三角洲布鲁斯
Chicago Blues|芝加哥藍調|芝加哥布鲁斯
Electric Blues|電藍調|电布鲁斯
Blues Rock|藍調搖滾|布鲁斯摇滚
Soul Blues|靈魂藍調|灵魂布鲁斯
Traditional R&B|傳統節奏藍調|传统节奏布鲁斯
Contemporary R&B|當代 R&B|当代 R&B
Alternative R&B|另類 R&B|另类 R&B
Neo Soul|新靈魂樂|新灵魂乐
Motown|摩城音樂|摩城音乐
Funk|放克|放克
P-Funk|P-Funk 放克|P-Funk 放克
Disco|的士高|迪斯科
Boogie|布吉音樂|布吉音乐
Quiet Storm|Quiet Storm 都市靈魂樂|Quiet Storm 都市灵魂乐
New Jack Swing|新傑克搖擺|新杰克摇摆
Old-School Hip-Hop|老派嘻哈|老派嘻哈
Golden Age Hip-Hop|黃金年代嘻哈|黄金年代嘻哈
East Coast Hip-Hop|東岸嘻哈|东岸嘻哈
West Coast Hip-Hop|西岸嘻哈|西岸嘻哈
Southern Hip-Hop|美國南方嘻哈|美国南方嘻哈
Trap|Trap 嘻哈|Trap 嘻哈
Drill|Drill 饒舌|Drill 说唱
Boom Bap|Boom Bap 嘻哈|Boom Bap 嘻哈
Conscious Hip-Hop|意識嘻哈|意识嘻哈
Alternative Hip-Hop|另類嘻哈|另类嘻哈
Jazz Rap|爵士饒舌|爵士说唱
Lo-Fi Hip-Hop|低傳真嘻哈|低保真嘻哈
Cloud Rap|雲端饒舌|云说唱
Grime|Grime 英倫饒舌|Grime 英伦说唱
UK Garage|英國車庫電子音樂|英国车库电子音乐
Afrobeats|非洲節拍流行|非洲节拍流行
Amapiano|阿瑪皮亞諾|阿玛皮亚诺
Reggaeton|雷鬼頓|雷鬼顿
Latin Pop|拉丁流行|拉丁流行
Latin Trap|拉丁 Trap|拉丁 Trap
Salsa|莎莎音樂|莎莎音乐
Bachata|巴恰塔|巴恰塔
Merengue|梅倫格|梅伦格
Bossa Nova|巴薩諾瓦|波萨诺瓦
Samba|森巴|桑巴
MPB|巴西流行音樂|巴西流行音乐
Tango|探戈|探戈
Flamenco|佛蘭明高|弗拉明戈
Reggae|雷鬼|雷鬼
Roots Reggae|根源雷鬼|根源雷鬼
Dub|Dub 雷鬼|Dub 雷鬼
Dancehall|舞廳雷鬼|舞厅雷鬼
Ska|斯卡|斯卡
Rocksteady|穩拍雷鬼|稳拍雷鬼
Jazz|爵士|爵士
Bebop|咆勃爵士|比博普爵士
Hard Bop|硬咆勃爵士|硬博普爵士
Cool Jazz|冷爵士|冷爵士
Modal Jazz|調式爵士|调式爵士
Free Jazz|自由爵士|自由爵士
Jazz Fusion|融合爵士|融合爵士
Smooth Jazz|輕柔爵士|轻柔爵士
Latin Jazz|拉丁爵士|拉丁爵士
Big Band|大樂隊爵士|大乐队爵士
Swing Jazz|搖擺爵士|摇摆爵士
Vocal Jazz|爵士演唱|爵士演唱
Contemporary Jazz|當代爵士|当代爵士
Acid Jazz|酸爵士|酸爵士
Classical Crossover|古典跨界|古典跨界
Baroque Music|巴洛克音樂|巴洛克音乐
Classical Period|古典主義時期音樂|古典主义时期音乐
Romantic Classical|浪漫主義古典音樂|浪漫主义古典音乐
Modern Classical|現代古典音樂|现代古典音乐
Contemporary Classical|當代古典音樂|当代古典音乐
Minimalism|極簡主義音樂|极简主义音乐
Opera|歌劇|歌剧
Choral Music|合唱音樂|合唱音乐
Chamber Music|室內樂|室内乐
Orchestral Music|管弦樂|管弦乐
Piano Classical|古典鋼琴|古典钢琴
Violin Classical|古典小提琴|古典小提琴
Film Scores|電影配樂|电影配乐
Video Game Music|遊戲配樂|vgm|游戏配乐
Anime Soundtracks|動漫配樂|动漫配乐
Musical Theatre Songs|音樂劇歌曲|音乐剧歌曲
Ambient|氛圍音樂|氛围音乐
Dark Ambient|黑暗氛圍音樂|黑暗氛围音乐
Drone Music|持續音音樂|持续音音乐
New Age|新世紀音樂|新世纪音乐
Downtempo|慢拍電子音樂|慢速电子音乐
Trip-Hop|神遊舞曲|神游舞曲
Chillout|放鬆電子音樂|放松电子音乐
Lounge Music|沙發音樂|沙发音乐
IDM|智能舞曲|智能舞曲
Breakbeat|碎拍|碎拍
Jungle|叢林舞曲|丛林舞曲
Liquid Drum & Bass|液態鼓打貝斯|液态鼓打贝斯
Neurofunk|神經放克|神经放克
Dubstep|Dubstep 貝斯音樂|Dubstep 贝斯音乐
Future Bass|未來貝斯|未来贝斯
Trap EDM|Trap 電子舞曲|Trap 电子舞曲
Electro House|電子浩室|电子浩室
Progressive House|漸進浩室|渐进浩室
Deep House|深度浩室|深度浩室
Tech House|科技浩室|科技浩室
French House|法式浩室|法式浩室
Disco House|的士高浩室|迪斯科浩室
Acid House|酸浩室|酸浩室
Chicago House|芝加哥浩室|芝加哥浩室
Detroit Techno|底特律 Techno|底特律 Techno
Minimal Techno|極簡 Techno|极简 Techno
Hard Techno|硬核 Techno|硬核 Techno
Melodic Techno|旋律 Techno|旋律 Techno
Progressive Trance|漸進 Trance|渐进 Trance
Psytrance|迷幻 Trance|迷幻 Trance
Goa Trance|果阿 Trance|果阿 Trance
Hardstyle|硬派舞曲|硬派舞曲
Gabber|Gabber 硬核舞曲|Gabber 硬核舞曲
UK Hardcore|英國硬核舞曲|英国硬核舞曲
Synthwave|合成器浪潮|合成器浪潮
Vaporwave|蒸汽波|蒸汽波
Chillwave|馳放潮音樂|驰放潮音乐
Future Funk|未來放克|未来放克
Electro Swing|電子搖擺|电子摇摆
K-Pop Girl Groups|K-Pop 女子團體|K-Pop 女子团体
K-Pop Boy Groups|K-Pop 男子團體|K-Pop 男子团体
Korean Indie|韓國獨立音樂|韩国独立音乐
Korean R&B|韓國 R&B|韩国 R&B
Korean Hip-Hop|韓國嘻哈|韩国嘻哈
Korean Ballads|韓國抒情歌|韩国抒情歌
J-Rock|日本搖滾|日本摇滚
Japanese Indie|日本獨立音樂|日本独立音乐
Japanese City Pop|日本 City Pop|日本 City Pop
Japanese Jazz|日本爵士|日本爵士
Japanese Hip-Hop|日本嘻哈|日本嘻哈
Japanese Alternative|日本另類音樂|日本另类音乐
Vocaloid|Vocaloid 虛擬歌聲|Vocaloid 虚拟歌声
Anisong|動漫歌曲|动漫歌曲
Visual Kei|視覺系|视觉系
Shibuya-kei|澀谷系|涩谷系
Cantopop Classics|經典廣東歌|经典粤语流行
Modern Cantopop|現代廣東歌|现代粤语流行
Hong Kong Indie|香港獨立音樂|香港独立音乐
Hong Kong Rock|香港搖滾|香港摇滚
Mandopop Ballads|華語抒情歌|华语抒情歌
Mandopop Rock|華語搖滾|华语摇滚
Taiwan Indie|台灣獨立音樂|台湾独立音乐
Chinese Rock|中國搖滾|中国摇滚
Chinese Hip-Hop|華語嘻哈|华语嘻哈
Chinese Folk|華語民謠|华语民谣
C-Pop Idol Music|華語偶像音樂|华语偶像音乐
World Music|世界音樂|世界音乐
Celtic Music|凱爾特音樂|凯尔特音乐
African Music|非洲音樂|非洲音乐
Highlife|Highlife 西非流行音樂|Highlife 西非流行音乐
Fela Kuti / Afrobeat|Afrobeat 非洲節拍|Afrobeat 非洲节拍
Middle Eastern Music|中東音樂|中东音乐
Indian Classical Music|印度古典音樂|印度古典音乐
Hindustani Classical|北印度古典音樂|北印度古典音乐
Carnatic Classical|南印度古典音樂|南印度古典音乐
Bollywood Music|寶萊塢音樂|宝莱坞音乐
Qawwali|卡瓦利音樂|卡瓦利音乐
Ghazal|加扎勒詩歌音樂|加扎勒诗歌音乐
Japanese Traditional Music|日本傳統音樂|日本传统音乐
Chinese Traditional Music|中國傳統音樂|中国传统音乐
Chinese Opera Music|中國戲曲音樂|中国戏曲音乐
Cantonese Opera|粵劇|粤剧
Guzheng Music|古箏音樂|古筝音乐
Erhu Music|二胡音樂|二胡音乐
Taiko|太鼓|太鼓
Korean Traditional Music|韓國傳統音樂|韩国传统音乐
Lo-Fi Beats|低傳真節拍|低保真节拍
Study Music|學習音樂|学习音乐
Workout Music|運動音樂|运动音乐
Sleep Music|睡眠音樂|睡眠音乐
Meditation Music|冥想音樂|冥想音乐
Road Trip Music|自駕旅行音樂|公路旅行音乐
Acoustic Covers|不插電翻唱|不插电翻唱
Live Albums|現場專輯|现场专辑
Unplugged Music|不插電音樂|不插电音乐
Vinyl Listening|黑膠聆聽|黑胶聆听
Audiophile Music|發燒音樂|发烧音乐
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'music.global_artist',
    category: 'music',
    cluster: 'music/artists_global',
    rankStart: 3400,
    raw: r'''
The Beatles
The Rolling Stones
Led Zeppelin
Pink Floyd
Queen
David Bowie
Elton John
Fleetwood Mac
The Beach Boys
The Doors
The Who
The Kinks
Creedence Clearwater Revival
Eagles
Aerosmith
AC/DC
Black Sabbath
Deep Purple
Rush
Genesis
Yes
King Crimson
Dire Straits
U2
R.E.M.
The Cure
Depeche Mode
New Order
Joy Division
The Smiths
Talking Heads
The Police
Duran Duran
Pet Shop Boys
Tears for Fears
Nirvana
Pearl Jam
Soundgarden
Alice in Chains
Red Hot Chili Peppers
Foo Fighters
Radiohead
Oasis
Blur
Pulp
Suede
The Stone Roses
Arctic Monkeys
Muse
Coldplay
The Killers
The Strokes
The White Stripes
Franz Ferdinand
Tame Impala
Vampire Weekend
The National
Bon Iver
Arcade Fire
Florence + the Machine
Paramore
Fall Out Boy
My Chemical Romance
Green Day
Blink-182
Linkin Park
System of a Down
Slipknot
Metallica
Iron Maiden
Judas Priest
Megadeth
Slayer
Tool
Nine Inch Nails
Rammstein
Evanescence
Bring Me the Horizon
Taylor Swift
Beyoncé
Rihanna
Lady Gaga
Adele
Ariana Grande
Billie Eilish
Dua Lipa
Olivia Rodrigo
Sabrina Carpenter
Lana Del Rey
Lorde
Miley Cyrus
Katy Perry
Britney Spears
Christina Aguilera
Madonna
Whitney Houston
Mariah Carey
Celine Dion
Janet Jackson
Michael Jackson
Prince
Stevie Wonder
Aretha Franklin
Marvin Gaye
Diana Ross
Donna Summer
Earth, Wind & Fire
Bee Gees
ABBA
Bruno Mars
The Weeknd
Frank Ocean
SZA
Daniel Caesar
H.E.R.
Alicia Keys
Usher
Justin Timberlake
Justin Bieber
Ed Sheeran
Harry Styles
One Direction
Backstreet Boys
Spice Girls
NSYNC
Doja Cat
Tyler, the Creator
Kendrick Lamar
Drake
J. Cole
Kanye West
Jay-Z
Nas
Eminem
2Pac
The Notorious B.I.G.
Snoop Dogg
Dr. Dre
Wu-Tang Clan
OutKast
A Tribe Called Quest
Public Enemy
Lauryn Hill
Missy Elliott
Nicki Minaj
Cardi B
Travis Scott
Future
Post Malone
Mac Miller
Childish Gambino
Anderson .Paak
Daft Punk
The Chemical Brothers
The Prodigy
Massive Attack
Portishead
Aphex Twin
Boards of Canada
Kraftwerk
Moby
Fatboy Slim
Justice
Calvin Harris
Avicii
Deadmau5
Skrillex
Disclosure
Fred again..
Charli xcx
Chappell Roan
Phoebe Bridgers
Boygenius
Mitski
Clairo
Beabadoobee
Laufey
Hozier
Noah Kahan
Zach Bryan
Chris Stapleton
Dolly Parton
Johnny Cash
Willie Nelson
Shania Twain
Kacey Musgraves
Bob Dylan
Joni Mitchell
Neil Young
Simon & Garfunkel
Leonard Cohen
Carole King
James Taylor
Tracy Chapman
Norah Jones
Amy Winehouse
Nina Simone
Ella Fitzgerald
Billie Holiday
Louis Armstrong
Miles Davis
John Coltrane
Chet Baker
Herbie Hancock
Chick Corea
Pat Metheny
Duke Ellington
Count Basie
Dave Brubeck
Oscar Peterson
B.B. King
Muddy Waters
Eric Clapton
Carlos Santana
Bob Marley
Buju Banton
Sean Paul
Bad Bunny
J Balvin
Karol G
Shakira
Rosalía
Daddy Yankee
Luis Miguel
Juanes
Caetano Veloso
João Gilberto
Antonio Carlos Jobim
Fela Kuti
Burna Boy
Wizkid
Tems
Stromae
Christine and the Queens
Phoenix
Air
Måneskin
Andrea Bocelli
Ennio Morricone
Hans Zimmer
John Williams
Joe Hisaishi|久石讓|久石譲|久石让
Ryuichi Sakamoto|坂本龍一|坂本龍一|坂本龙一
Yiruma
Ludovico Einaudi
Max Richter
Ólafur Arnalds
Nils Frahm
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'music.kpop_artist',
    category: 'music',
    cluster: 'music/kpop_artists',
    rankStart: 3800,
    raw: r'''
BTS
BLACKPINK
TWICE
EXO
SEVENTEEN
Stray Kids
NewJeans
IVE
aespa
LE SSERAFIM
(G)I-DLE
Red Velvet
Girls' Generation|SNSD
SHINee
BIGBANG
2NE1
Super Junior
TVXQ
Wonder Girls
KARA
2PM
f(x)
Apink
MAMAMOO
GOT7
MONSTA X
NCT
NCT 127
NCT Dream
WayV
ATEEZ
TXT
ENHYPEN
TREASURE
ZEROBASEONE
RIIZE
BOYNEXTDOOR
TWS
ILLIT
BABYMONSTER
ITZY
NMIXX
STAYC
KISS OF LIFE
Dreamcatcher
LOONA
tripleS
fromis_9
OH MY GIRL
GFRIEND
IU
Taeyeon
BoA
Sunmi
HyunA
Chungha
Heize
BIBI
Dean
Crush
Zion.T
Epik High
Dynamic Duo
Zico
Jay Park
DPR IAN
DPR LIVE
LeeHi
AKMU
DAY6
The Rose
Xdinary Heroes
CNBLUE
FTIsland
Jannabi
Nell
HYUKOH
NewJeans Members
BTS Solo Projects
BLACKPINK Solo Projects
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'music.jp_artist',
    category: 'music',
    cluster: 'music/japanese_artists',
    rankStart: 3950,
    raw: r'''
Utada Hikaru|宇多田光
Ayumi Hamasaki|濱崎步|浜崎あゆみ|滨崎步
Namie Amuro|安室奈美惠
Kenshi Yonezu|米津玄師|米津玄師|米津玄师
YOASOBI
Ado
LiSA
Aimyon|愛繆|あいみょん|爱缪
Mrs. GREEN APPLE
Official HIGE DANdism|Official髭男dism
King Gnu
back number
RADWIMPS
BUMP OF CHICKEN
ONE OK ROCK
MAN WITH A MISSION
Asian Kung-Fu Generation
L'Arc-en-Ciel
GLAY
X Japan
Luna Sea
B'z
Mr.Children
Southern All Stars
Spitz
The Blue Hearts
Number Girl
Fishmans
Cornelius
Pizzicato Five
Perfume
Kyary Pamyu Pamyu
Sakanaction
Supercar
YMO|Yellow Magic Orchestra
Mariya Takeuchi|竹內瑪莉亞|竹内まりや|竹内玛利亚
Tatsuro Yamashita|山下達郎|山下達郎|山下达郎
Anri|杏里
Miki Matsubara|松原美紀|松原みき|松原美纪
Taeko Ohnuki|大貫妙子
Haruomi Hosono|細野晴臣
Eve
Vaundy
Fujii Kaze|藤井風|藤井風|藤井风
Creepy Nuts
Atarashii Gakko!|新しい学校のリーダーズ
Babymetal
Band-Maid
SCANDAL
Maximum the Hormone
Ling Tosite Sigure
TK from Ling Tosite Sigure
Aimer
milet
ReoNa
ClariS
Kalafina
Yuki Kajiura|梶浦由記
Hiroyuki Sawano|澤野弘之|澤野弘之|泽野弘之
Linked Horizon
FLOW
Porno Graffitti
Orange Range
KANA-BOON
Ikimonogakari
ZUTOMAYO|ずっと真夜中でいいのに。
yorushika|ヨルシカ
Mafumafu|まふまふ
Hatsune Miku|初音未來|初音ミク|初音未来
Vocaloid Producers
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'music.hk_artist',
    category: 'music',
    cluster: 'music/hk_cantopop',
    rankStart: 4100,
    raw: r'''
Leslie Cheung|張國榮|張國榮|张国荣
Anita Mui|梅艷芳|梅艷芳|梅艳芳
Beyond
Danny Chan|陳百強|陳百強|陈百强
Alan Tam|譚詠麟|譚詠麟|谭咏麟
Roman Tam|羅文|羅文|罗文
George Lam|林子祥|林子祥
Paula Tsui|徐小鳳|徐小鳳|徐小凤
Sam Hui|許冠傑|許冠傑|许冠杰
Priscilla Chan|陳慧嫻|陳慧嫻|陈慧娴
Sandy Lam|林憶蓮|林憶蓮|林忆莲
Faye Wong|王菲
Jacky Cheung|張學友|張學友|张学友
Andy Lau|劉德華|劉德華|刘德华
Leon Lai|黎明
Aaron Kwok|郭富城
Eason Chan|陳奕迅|陳奕迅|陈奕迅
Joey Yung|容祖兒|容祖兒|容祖儿
Hacken Lee|李克勤
Kelly Chen|陳慧琳|陳慧琳|陈慧琳
Miriam Yeung|楊千嬅|楊千嬅|杨千嬅
Sammi Cheng|鄭秀文|鄭秀文|郑秀文
Nicholas Tse|謝霆鋒|謝霆鋒|谢霆锋
Leo Ku|古巨基
Edmond Leung|梁漢文|梁漢文|梁汉文
Janice Vidal|衛蘭|衛蘭|卫兰
Ivana Wong|王菀之
Kay Tse|謝安琪|謝安琪|谢安琪
Hins Cheung|張敬軒|張敬軒|张敬轩
Pakho Chau|周柏豪
Dear Jane
RubberBand
Supper Moment
C AllStar
My Little Airport
The Pancakes
Chochukmo
GDJYB|雞蛋蒸肉餅
ToNick
Kolor
Nowhere Boys
Mirror
Anson Lo|盧瀚霆|卢瀚霆
Keung To|姜濤|姜涛
Edan Lui|呂爵安|吕爵安
Jer Lau|柳應廷|柳应廷
Ian Chan|陳卓賢|陈卓贤
MC Cheung Tinfu|張天賦|张天赋
Terence Lam|林家謙|林家谦
Jay Fung|馮允謙|冯允谦
Kaho Hung|洪嘉豪
Cloud Wan|雲浩影|云浩影
Jace Chan|陳凱詠|陈凯咏
Serrini
moon tang
Gareth.T
Tyson Yoshi
Novel Fergus
JB
Lolly Talk
COLLAR
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'music.mando_artist',
    category: 'music',
    cluster: 'music/mandopop_artists',
    rankStart: 4250,
    raw: r'''
Jay Chou|周杰倫|周杰伦
JJ Lin|林俊傑|林俊杰
Mayday|五月天
Sodagreen|蘇打綠|苏打绿
Stefanie Sun|孫燕姿|孙燕姿
Jolin Tsai|蔡依林
A-Mei|張惠妹|张惠妹
David Tao|陶喆
Leehom Wang|王力宏
Fish Leong|梁靜茹|梁静茹
Rainie Yang|楊丞琳|杨丞琳
Hebe Tien|田馥甄
S.H.E
F.I.R.
Cheer Chen|陳綺貞|陈绮贞
Deserts Chang|張懸|张悬
Crowd Lu|盧廣仲|卢广仲
Wu Bai|伍佰
Lo Ta-yu|羅大佑|Tayu Lo|罗大佑
Jonathan Lee|李宗盛
Teresa Teng|鄧麗君|邓丽君
Fei Yu-ching|費玉清|费玉清
Wakin Chau|周華健|周华健
Richie Jen|任賢齊|任贤齐
Jeff Chang|張信哲|张信哲
Eric Moo|巫啟賢|巫启贤
Karen Mok|莫文蔚
Na Ying|那英
Faye Wong Mandarin|王菲國語歌|王菲国语歌
Eason Chan Mandarin|陳奕迅國語歌|陈奕迅国语歌
Li Ronghao|李榮浩|李荣浩
Hua Chenyu|華晨宇|华晨宇
Zhou Shen|周深
Mao Buyi|毛不易
Joker Xue|薛之謙|薛之谦
G.E.M.|鄧紫棋|邓紫棋
Accusefive|告五人
No Party For Cao Dong|草東沒有派對|草东没有派对
Sunset Rollercoaster|落日飛車|落日飞车
Elephant Gym|大象體操
The Chairs|椅子樂團|椅子乐团
Cosmos People|宇宙人
EggPlantEgg|茄子蛋
Fire EX.|滅火器|灭火器
Omnipotent Youth Society|萬能青年旅店|万能青年旅店
New Pants|新褲子|新裤子
Miserable Faith|痛仰
Second Hand Rose|二手玫瑰
Carsick Cars
The Big Wave|大波浪
Hedgehog|刺猬
Faye Wong Classics|王菲經典|王菲经典
''',
  ),
]);

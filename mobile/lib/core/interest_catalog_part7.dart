import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart7 = List.unmodifiable([
  ...parseInterestFamily(
    idPrefix: 'entertainment.movie_subgenre',
    category: 'entertainment',
    cluster: 'movies/subgenres',
    rankStart: 900,
    raw: r'''
Action Epic|動作史詩片|动作史诗片
Adventure Epic|冒險史詩片|冒险史诗片
Alien Invasion|外星入侵片|外星入侵片
Animal Adventure|動物冒險片|动物冒险片
B-Movie Action|B 級動作片|B 级动作片
Body Horror|身體恐怖片|身体恐怖片
Buddy Comedy|拍檔喜劇|搭档喜剧
Buddy Cop|拍檔警匪片|搭档警匪片
Caper|劫案片|劫案片
Car Action|汽車動作片|汽车动作片
Conspiracy Thriller|陰謀驚悚片|阴谋惊悚片
Costume Drama|古裝劇情片|古装剧情片
Cozy Mystery|輕鬆推理|轻松推理
Crime Documentary|犯罪紀錄片|犯罪纪录片
Cyber Thriller|網絡驚悚片|网络惊悚片
Cyberpunk|賽博朋克|赛博朋克
Dark Comedy|黑色喜劇|黑色喜剧
Dark Fantasy|黑暗奇幻|黑暗奇幻
Dark Romance|黑暗愛情|黑暗爱情
Desert Adventure|沙漠冒險片|沙漠冒险片
Dinosaur Adventure|恐龍冒險片|恐龙冒险片
Disaster Movies|災難片|灾难片
Docudrama|劇情式紀錄片|剧情式纪录片
Dystopian Sci-Fi|反烏托邦科幻|反乌托邦科幻
Epic Cinema|史詩電影|史诗电影
Erotic Thriller|情色驚悚片|情色惊悚片
Fairy Tale|童話電影|童话电影
Film Noir|黑色電影|黑色电影
Financial Drama|金融劇情片|金融剧情片
Folk Horror|民俗恐怖片|民俗恐怖片
Found Footage Horror|偽紀錄式恐怖片|伪纪录式恐怖片
Gangster Movies|黑幫電影|黑帮电影
Giallo|意式鉛黃驚悚片|意式铅黄惊悚片
Globetrotting Adventure|環球冒險片|环球冒险片
Gun Fu|槍鬥術電影|枪斗术电影
Hard-boiled Detective|硬漢偵探片|硬汉侦探片
Heist Movies|劫案電影|劫案电影
High-Concept Comedy|高概念喜劇|高概念喜剧
Historical Epic|歷史史詩片|历史史诗片
Holiday Movies|節日電影|节日电影
Jukebox Musical|流行金曲音樂劇電影|流行金曲音乐剧电影
Jungle Adventure|叢林冒險片|丛林冒险片
Kaiju|怪獸電影|怪兽电影
Kung Fu Movies|功夫片|功夫片
Legal Drama|法律劇情片|法律剧情片
Legal Thriller|法律驚悚片|法律惊悚片
Martial Arts Movies|武術片|武术片
Medical Drama|醫療劇情片|医疗剧情片
Mockumentary|偽紀錄片|伪纪录片
Monster Horror|怪物恐怖片|怪物恐怖片
Mountain Adventure|山岳冒險片|山地冒险片
Music Documentary|音樂紀錄片|音乐纪录片
Nature Documentary|自然紀錄片|自然纪录片
Parody Movies|惡搞電影|恶搞电影
Period Drama|時代劇情片|年代剧情片
Police Procedural|警務程序片|警察程序片
Political Drama|政治劇情片|政治剧情片
Political Thriller|政治驚悚片|政治惊悚片
Prison Drama|監獄劇情片|监狱剧情片
Psychological Drama|心理劇情片|心理剧情片
Psychological Horror|心理恐怖片|心理恐怖片
Psychological Thriller|心理驚悚片|心理惊悚片
Quest Adventure|任務冒險片|任务冒险片
Quirky Comedy|怪趣喜劇|怪趣喜剧
Road Movies|公路電影|公路电影
Romantic Comedy|愛情喜劇|romcom|爱情喜剧
Romantic Epic|愛情史詩片|爱情史诗片
Samurai Cinema|武士電影|武士电影
Satire|諷刺電影|讽刺电影
Sci-Fi Epic|科幻史詩片|科幻史诗片
Screwball Comedy|神經喜劇|神经喜剧
Sea Adventure|海上冒險片|海上冒险片
Serial Killer Thriller|連環殺手驚悚片|连环杀手惊悚片
Slapstick|鬧劇喜劇|滑稽喜剧
Slasher Horror|砍殺恐怖片|砍杀恐怖片
Space Sci-Fi|太空科幻|太空科幻
Spaghetti Western|意大利西部片|意大利西部片
Splatter Horror|血腥恐怖片|血腥恐怖片
Spy Movies|間諜片|间谍片
Steampunk|蒸汽朋克|蒸汽朋克
Superhero Movies|超級英雄電影|超级英雄电影
Supernatural Fantasy|超自然奇幻|超自然奇幻
Supernatural Horror|超自然恐怖片|超自然恐怖片
Survival Movies|生存電影|生存电影
Swashbuckler|劍客冒險片|剑客冒险片
Sword and Sandal|劍與涼鞋片|剑与凉鞋片
Sword and Sorcery|劍與魔法|剑与魔法
Teen Comedy|青春喜劇|青春喜剧
Teen Drama|青春劇情片|青春剧情片
Teen Fantasy|青春奇幻|青春奇幻
Teen Horror|青春恐怖片|青春恐怖片
Teen Romance|青春愛情片|青春爱情片
Time Travel Movies|時間旅行電影|时间旅行电影
Tragedy|悲劇|悲剧
Tragic Romance|悲劇愛情片|悲剧爱情片
True Crime Documentary|真實犯罪紀錄片|真实犯罪纪录片
Urban Adventure|城市冒險片|城市冒险片
Vampire Horror|吸血鬼恐怖片|吸血鬼恐怖片
War Epic|戰爭史詩片|战争史诗片
Werewolf Horror|狼人恐怖片|狼人恐怖片
Western Epic|西部史詩片|西部史诗片
Whodunit|誰是兇手式推理|谁是凶手式推理
Witch Horror|女巫恐怖片|女巫恐怖片
Workplace Drama|職場劇情片|职场剧情片
Wuxia Movies|武俠片|武俠片|武侠片
Zombie Horror|喪屍恐怖片|丧尸恐怖片
Coming-of-Age Movies|成長電影|成长电影
Sports Drama|體育劇情片|体育剧情片
Courtroom Drama|法庭劇情片|法庭剧情片
Biographical Drama|傳記劇情片|biopic|传记剧情片
Dance Movies|舞蹈電影|舞蹈电影
Food Movies|美食電影|美食电影
Music Biopics|音樂人傳記片|音乐人传记片
Road Trip Comedy|公路喜劇|公路喜剧
Family Adventure|家庭冒險片|家庭冒险片
Creature Features|怪獸類型片|怪兽类型片
Home Invasion Thriller|入屋驚悚片|入室惊悚片
Techno Thriller|科技驚悚片|科技惊悚片
Eco Thriller|生態驚悚片|生态惊悚片
Neo-Noir|新黑色電影|新黑色电影
Mystery Thriller|懸疑驚悚片|悬疑惊悚片
Revenge Thriller|復仇驚悚片|复仇惊悚片
Survival Thriller|生存驚悚片|生存惊悚片
Romantic Fantasy|愛情奇幻|爱情奇幻
Urban Fantasy|都市奇幻|都市奇幻
Science Fantasy|科學奇幻|科学奇幻
Military Sci-Fi|軍事科幻|军事科幻
Space Opera|太空歌劇|太空歌剧
Post-Apocalyptic Movies|末日後電影|末日后电影
Alternate History|架空歷史|架空历史
Historical Romance|歷史愛情|历史爱情
Holiday Romance|節日愛情|节日爱情
Feel-Good Movies|療癒電影|治愈电影
Slice-of-Life Movies|日常系電影|日常系电影
Art House Cinema|藝術電影|艺术电影
Experimental Cinema|實驗電影|实验电影
Silent Cinema|默片|默片
Black-and-White Cinema|黑白電影|黑白电影
Hong Kong Action Cinema|港產動作片|港產動作片|港产动作片
Hong Kong New Wave|香港新浪潮|香港新浪潮|香港新浪潮
Japanese Cinema|日本電影|日本电影
Korean Cinema|韓國電影|韓国映画|韩国电影
Chinese Cinema|華語電影|中国映画|华语电影
French New Wave|法國新浪潮|法国新浪潮
Italian Neorealism|意大利新寫實主義|意大利新现实主义
Bollywood|寶萊塢電影|宝莱坞电影
Indian Cinema|印度電影|印度电影
Latin American Cinema|拉丁美洲電影|拉丁美洲电影
Nordic Noir Film|北歐黑色電影|北欧黑色电影
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'entertainment.classic_film',
    category: 'entertainment',
    cluster: 'movies/classics',
    rankStart: 1050,
    raw: r'''
The Godfather
The Godfather Part II
Casablanca
Citizen Kane
12 Angry Men
Seven Samurai|七武士
Rashomon|羅生門|羅生門|罗生门
Tokyo Story|東京物語
Ikiru|生きる
Yojimbo|用心棒
Sanjuro|椿三十郎
High and Low|天國與地獄|天國與地獄|天国与地狱
2001: A Space Odyssey
A Clockwork Orange
Dr. Strangelove
The Shining
Barry Lyndon
Lawrence of Arabia
The Bridge on the River Kwai
Doctor Zhivago
Gone with the Wind
Singin' in the Rain
The Wizard of Oz
It's a Wonderful Life
Roman Holiday
Sunset Boulevard
Double Indemnity
The Apartment
Some Like It Hot
Rear Window
Vertigo
Psycho
North by Northwest
Rebecca
The Birds
Chinatown
Taxi Driver
Raging Bull
Goodfellas
Mean Streets
Once Upon a Time in America
The French Connection
Dog Day Afternoon
Network
One Flew Over the Cuckoo's Nest
The Deer Hunter
Apocalypse Now
Platoon
Full Metal Jacket
Paths of Glory
The Great Escape
The Good, the Bad and the Ugly
Once Upon a Time in the West
A Fistful of Dollars
For a Few Dollars More
High Noon
The Searchers
Rio Bravo
Butch Cassidy and the Sundance Kid
Bonnie and Clyde
Cool Hand Luke
Easy Rider
The Graduate
Midnight Cowboy
Annie Hall
Manhattan
Cinema Paradiso
8½|8 1/2
La Dolce Vita
Bicycle Thieves
The 400 Blows
Breathless
Jules and Jim
La Haine
Amélie
The Seventh Seal
Wild Strawberries
Persona
Fanny and Alexander
Stalker
Solaris
Andrei Rublev
Battleship Potemkin
Metropolis
M
Nosferatu
The Cabinet of Dr. Caligari
City Lights
Modern Times
The Great Dictator
The Gold Rush
Sherlock Jr.
The General
Sunrise: A Song of Two Humans
The Passion of Joan of Arc
The Rules of the Game
Children of Paradise
The Third Man
Brief Encounter
A Matter of Life and Death
The Red Shoes
Black Narcissus
The Maltese Falcon
The Big Sleep
Touch of Evil
The Night of the Hunter
All About Eve
On the Waterfront
A Streetcar Named Desire
Rebel Without a Cause
East of Eden
Giant
Ben-Hur
Spartacus
Cleopatra
The Ten Commandments
The Sound of Music
West Side Story
My Fair Lady
Mary Poppins
The Exorcist
Rosemary's Baby
The Omen
Halloween
Alien
Aliens
The Thing
Blade Runner
The Terminator
Terminator 2: Judgment Day
RoboCop
Predator
E.T. the Extra-Terrestrial
Close Encounters of the Third Kind
Jaws
Raiders of the Lost Ark
Indiana Jones and the Last Crusade
Back to the Future
Ghostbusters
Die Hard
Lethal Weapon
Top Gun
Rocky
Rocky II
Rambo: First Blood
The Karate Kid
The Breakfast Club
Ferris Bueller's Day Off
Stand by Me
When Harry Met Sally...
Pretty Woman
Dirty Dancing
Rain Man
Dead Poets Society
The Shawshank Redemption
Forrest Gump
Pulp Fiction
Reservoir Dogs
The Silence of the Lambs
Heat
Se7en
The Usual Suspects
L.A. Confidential
Good Will Hunting
The Truman Show
Saving Private Ryan
Fight Club
The Sixth Sense
American Beauty
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'entertainment.modern_film',
    category: 'entertainment',
    cluster: 'movies/modern_evergreen',
    rankStart: 1250,
    raw: r'''
The Matrix
The Matrix Reloaded
Gladiator
Memento
Mulholland Drive
Spirited Away|千與千尋|千と千尋の神隠し|千与千寻
Howl's Moving Castle|哈爾移動城堡|ハウルの動く城|哈尔的移动城堡
Princess Mononoke|幽靈公主|もののけ姫|幽灵公主
My Neighbor Totoro|龍貓|となりのトトロ|龙猫
Grave of the Fireflies|再見螢火蟲|火垂るの墓|萤火虫之墓
Oldboy|原罪犯|올드보이|老男孩
Memories of Murder|殺人回憶|살인의 추억|杀人回忆
The Host|韓流怪嚇|괴물|汉江怪物
Parasite|上流寄生族|기생충|寄生虫
Decision to Leave|分手的決心|헤어질 결심|分手的决心
Train to Busan|屍殺列車|부산행|釜山行
Infernal Affairs|無間道|無間道|无间道
In the Mood for Love|花樣年華|花樣年華|花样年华
Chungking Express|重慶森林|重慶森林|重庆森林
Fallen Angels|墮落天使|墮落天使|堕落天使
Happy Together|春光乍洩|春光乍洩|春光乍泄
A Better Tomorrow|英雄本色|英雄本色
Hard Boiled|辣手神探|辣手神探
Police Story|警察故事|警察故事
Drunken Master|醉拳|醉拳
Crouching Tiger, Hidden Dragon|臥虎藏龍|臥虎藏龍|卧虎藏龙
Hero|英雄
House of Flying Daggers|十面埋伏
Kung Fu Hustle|功夫
Shaolin Soccer|少林足球
Ip Man|葉問|葉問|叶问
The Grandmaster|一代宗師|一代宗師|一代宗师
A Separation
The Lives of Others
Pan's Labyrinth
City of God
Amores Perros
Y Tu Mamá También
The Motorcycle Diaries
No Country for Old Men
There Will Be Blood
The Departed
The Prestige
Children of Men
Little Miss Sunshine
Brokeback Mountain
Eternal Sunshine of the Spotless Mind
Lost in Translation
Kill Bill: Vol. 1
Kill Bill: Vol. 2
Sin City
V for Vendetta
300
The Dark Knight
Batman Begins
The Dark Knight Rises
Iron Man
Captain America: The Winter Soldier
Guardians of the Galaxy
Avengers: Infinity War
Avengers: Endgame
Black Panther
Spider-Man 2
Spider-Man: Into the Spider-Verse
Spider-Man: Across the Spider-Verse
Logan
Deadpool
X-Men: Days of Future Past
Wonder Woman
Joker
The Batman
Man of Steel
Watchmen
Inception
Interstellar
Dunkirk
Oppenheimer
Tenet
Arrival
Blade Runner 2049
Ex Machina
Her
District 9
Moon
Gravity
The Martian
Dune
Dune: Part Two
Mad Max: Fury Road
Furiosa: A Mad Max Saga
Edge of Tomorrow
Snowpiercer
Everything Everywhere All at Once
Get Out
Us
Nope
Hereditary
Midsommar
The Witch
The Lighthouse
The Babadook
It Follows
A Quiet Place
The Conjuring
Insidious
Saw
28 Days Later
Zombieland
Shaun of the Dead
Hot Fuzz
Superbad
Bridesmaids
The Hangover
Mean Girls
Legally Blonde
The Devil Wears Prada
La La Land
Whiplash
Black Swan
Birdman
The Social Network
Moneyball
The Big Short
Spotlight
Argo
12 Years a Slave
Moonlight
Call Me by Your Name
Portrait of a Lady on Fire
The Handmaiden|下女誘罪|아가씨|小姐
Drive My Car|駕駛我的車|ドライブ・マイ・カー|驾驶我的车
Shoplifters|小偷家族|万引き家族
Perfect Days
Your Name.|你的名字|君の名は。|你的名字
Weathering with You|天氣之子|天気の子|天气之子
Suzume|鈴芽之旅|すずめの戸締まり|铃芽之旅
A Silent Voice|聲之形|聲の形|声之形
The Boy and the Heron|蒼鷺與少年|君たちはどう生きるか|你想活出怎样的人生
RRR
3 Idiots
Dangal
Lagaan
Slumdog Millionaire
The Lunchbox
Barfi!
Bajrangi Bhaijaan
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'entertainment.tv_drama',
    category: 'entertainment',
    cluster: 'tv/drama',
    rankStart: 1500,
    raw: r'''
Breaking Bad
Better Call Saul
The Sopranos
The Wire
Mad Men
Succession
Game of Thrones
House of the Dragon
The Last of Us
Chernobyl
Band of Brothers
The Pacific
Rome
Deadwood
Boardwalk Empire
Peaky Blinders
Sons of Anarchy
Justified
Yellowstone
True Detective
Fargo
Mindhunter
Ozark
Narcos
Narcos: Mexico
Money Heist|La Casa de Papel
Dark
1899
The Crown
Downton Abbey
The Gilded Age
The Queen's Gambit
The Handmaid's Tale
Killing Eve
Big Little Lies
Sharp Objects
Mare of Easttown
Normal People
One Day
Euphoria
Skins
Sex Education
Heartstopper
The Bear
Shōgun|幕府將軍|将軍
Tokyo Vice
Pachinko
Squid Game|魷魚遊戲|오징어 게임|鱿鱼游戏
Crash Landing on You|愛的迫降|사랑의 불시착|爱的迫降
Reply 1988|請回答1988|응답하라 1988|请回答1988
My Mister|我的大叔|나의 아저씨|我的大叔
Hospital Playlist|機智醫生生活|슬기로운 의사생활|机智医生生活
Prison Playbook|機智牢房生活|슬기로운 감빵생활|机智牢房生活
Signal|信號|시그널|信号
Stranger|秘密森林|비밀의 숲|秘密森林
Kingdom|李屍朝鮮|킹덤|王国
Vincenzo|黑道律師文森佐|빈센조|文森佐
Itaewon Class|梨泰院Class|이태원 클라쓰|梨泰院Class
Extraordinary Attorney Woo|非常律師禹英禑|이상한 변호사 우영우|非常律师禹英禑
Twenty-Five Twenty-One|二十五，二十一|스물다섯 스물하나|二十五二十一
Goblin|孤單又燦爛的神－鬼怪|도깨비|孤单又灿烂的神鬼怪
Descendants of the Sun|太陽的後裔|태양의 후예|太阳的后裔
Moon Lovers: Scarlet Heart Ryeo|月之戀人－步步驚心：麗|달의 연인 - 보보경심 려|步步惊心丽
Alchemy of Souls|還魂|환혼|还魂
Mr. Sunshine|陽光先生|미스터 션샤인|阳光先生
Moving|Moving 異能|무빙|超异能族
Weak Hero Class 1|弱美男英雄Class 1|약한영웅 Class 1|弱小英雄
The Glory|黑暗榮耀|더 글로리|黑暗荣耀
Queen of Tears|淚之女王|눈물의 여왕|泪之女王
Lovely Runner|背著善宰跑|선재 업고 튀어|背着善宰跑
Nirvana in Fire|琅琊榜
The Untamed|陳情令|陈情令
Joy of Life|慶餘年|庆余年
Story of Yanxi Palace|延禧攻略
Empresses in the Palace|甄嬛傳|甄嬛传
Reset|開端|开端
The Longest Day in Chang'an|長安十二時辰|长安十二时辰
The Bad Kids|隱秘的角落|隐秘的角落
Minning Town|山海情
Three-Body|三體|三体
Meet Yourself|去有風的地方|去有风的地方
A Lifelong Journey|人世間|人世间
Blossoms Shanghai|繁花
Someday or One Day|想見你|想见你
The Victims' Game|誰是被害者|谁是被害者
Copycat Killer|模仿犯
The World Between Us|我們與惡的距離|我们与恶的距离
Wave Makers|人選之人—造浪者|人选之人
Legal High|リーガル・ハイ
Hanzawa Naoki|半澤直樹|半沢直樹|半泽直树
Unnatural|非自然死亡|アンナチュラル
MIU404
The Full-Time Wife Escapist|逃避雖可恥但有用|逃げるは恥だが役に立つ|逃避虽可耻但有用
First Love|First Love 初戀|First Love 初恋
Alice in Borderland|今際之國的闖關者|今際の国のアリス|弥留之国的爱丽丝
Brush Up Life|重啟人生|ブラッシュアップライフ|重启人生
Silent|silent
VIVANT
Gannibal|噬亡村|ガンニバル
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'entertainment.tv_comedy',
    category: 'entertainment',
    cluster: 'tv/comedy_variety',
    rankStart: 1700,
    raw: r'''
Friends
Seinfeld
The Office (US)
The Office (UK)
Parks and Recreation
Brooklyn Nine-Nine
Community
30 Rock
Arrested Development
Modern Family
How I Met Your Mother
The Big Bang Theory
Schitt's Creek
Ted Lasso
Abbott Elementary
Fleabag
Derry Girls
The IT Crowd
Black Books
Peep Show
Only Fools and Horses
Frasier
Cheers
Curb Your Enthusiasm
It's Always Sunny in Philadelphia
Veep
Silicon Valley
Master of None
Atlanta
Barry
What We Do in the Shadows
The Good Place
Superstore
New Girl
Gilmore Girls
Sex and the City
Desperate Housewives
Ugly Betty
Jane the Virgin
Fresh Off the Boat
Kim's Convenience
Reservation Dogs
Never Have I Ever
The Marvelous Mrs. Maisel
BoJack Horseman
Rick and Morty
South Park
The Simpsons
Futurama
Family Guy
Bob's Burgers
Archer
Saturday Night Live|SNL
Taskmaster
The Great British Bake Off|GBBO
MasterChef
Survivor
The Amazing Race
RuPaul's Drag Race
Queer Eye
Terrace House
Running Man|런닝맨
Knowing Bros|아는 형님
Infinite Challenge|무한도전
2 Days & 1 Night|1박 2일
I Live Alone|나 혼자 산다
Physical: 100|피지컬: 100
Street Woman Fighter
Produce 101
Single's Inferno|솔로지옥
Transit Love|환승연애
Heart Signal|하트시그널
Busted!|범인은 바로 너!
Keep Running|奔跑吧
Who's the Murderer|明星大偵探|明星大侦探
Back to Field|嚮往的生活|向往的生活
Divas Hit the Road|花兒與少年|花儿与少年
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'entertainment.anime_title',
    category: 'entertainment',
    cluster: 'anime/title',
    rankStart: 1850,
    raw: r'''
Fullmetal Alchemist: Brotherhood|鋼之鍊金術師|鋼の錬金術師|钢之炼金术师
Cowboy Bebop|星際牛仔|カウボーイビバップ|星际牛仔
Neon Genesis Evangelion|新世紀福音戰士|新世紀エヴァンゲリオン|新世纪福音战士
Steins;Gate|命運石之門|シュタインズ・ゲート|命运石之门
Death Note|死亡筆記|デスノート|死亡笔记
Hunter x Hunter|全職獵人|ハンター×ハンター|全职猎人
Bleach|死神|BLEACH|死神
Yu Yu Hakusho|幽遊白書|幽☆遊☆白書|幽游白书
Slam Dunk|男兒當入樽|SLAM DUNK|灌篮高手
Haikyuu!!|排球少年!!|ハイキュー!!|排球少年
Kuroko's Basketball|黑子的籃球|黒子のバスケ|黑子的篮球
Blue Lock|BLUE LOCK 藍色監獄|ブルーロック|蓝色监狱
Hajime no Ippo|第一神拳|はじめの一歩|第一神拳
Initial D|頭文字D|頭文字D|头文字D
Captain Tsubasa|足球小將|キャプテン翼|足球小将
Detective Conan|名偵探柯南|名探偵コナン|名侦探柯南
Sailor Moon|美少女戰士|美少女戦士セーラームーン|美少女战士
Cardcaptor Sakura|百變小櫻|カードキャプターさくら|百变小樱
Revolutionary Girl Utena|少女革命|少女革命ウテナ|少女革命
Puella Magi Madoka Magica|魔法少女小圓|魔法少女まどか☆マギカ|魔法少女小圆
Fruits Basket|生肖奇緣|フルーツバスケット|水果篮子
Ouran High School Host Club|櫻蘭高校男公關部|桜蘭高校ホスト部|樱兰高校男公关部
Nana|NANA 世上的另一個我|NANA|娜娜
Paradise Kiss|天堂之吻|Paradise Kiss|天堂之吻
Violet Evergarden|紫羅蘭永恆花園|ヴァイオレット・エヴァーガーデン|紫罗兰永恒花园
Clannad
Toradora!|TIGER×DRAGON！|とらドラ！|龙与虎
Kaguya-sama: Love Is War|輝夜姬想讓人告白|かぐや様は告らせたい|辉夜大小姐想让我告白
My Dress-Up Darling|戀上換裝娃娃|その着せ替え人形は恋をする|更衣人偶坠入爱河
Horimiya|堀與宮村|ホリミヤ|堀与宫村
Oshi no Ko|【我推的孩子】|【推しの子】|我推的孩子
Bocchi the Rock!|孤獨搖滾！|ぼっち・ざ・ろっく！|孤独摇滚
K-On!|K-ON！輕音部|けいおん！|轻音少女
Sound! Euphonium|吹響吧！上低音號|響け！ユーフォニアム|吹响吧上低音号
Your Lie in April|四月是你的謊言|四月は君の嘘|四月是你的谎言
March Comes in Like a Lion|3月的獅子|3月のライオン|三月的狮子
Chihayafuru|花牌情緣|ちはやふる|花牌情缘
A Place Further Than the Universe|比宇宙更遠的地方|宇宙よりも遠い場所|比宇宙更远的地方
Frieren: Beyond Journey's End|葬送的芙莉蓮|葬送のフリーレン|葬送的芙莉莲
Delicious in Dungeon|迷宮飯|ダンジョン飯|迷宫饭
Made in Abyss|來自深淵|メイドインアビス|来自深渊
Mushishi|蟲師|蟲師|虫师
Natsume's Book of Friends|夏目友人帳|夏目友人帳|夏目友人帐
Mononoke|怪化貓|モノノ怪|怪化猫
Odd Taxi|奇巧計程車|オッドタクシー|奇巧计程车
Monster|MONSTER 怪物|MONSTER|怪物
Pluto|PLUTO 冥王|PLUTO|冥王
Vinland Saga|冰海戰記|ヴィンランド・サガ|冰海战记
Berserk|烙印勇士|ベルセルク|剑风传奇
Kingdom (Anime)|王者天下|キングダム|王者天下
Golden Kamuy|黃金神威|ゴールデンカムイ|黄金神威
Dr. Stone|Dr.STONE 新石紀|Dr.STONE|石纪元
Mob Psycho 100|路人超能100|モブサイコ100|灵能百分百
One Punch Man|一拳超人|ワンパンマン|一拳超人
Chainsaw Man|鏈鋸人|チェンソーマン|电锯人
Hell's Paradise|地獄樂|地獄楽|地狱乐
Kaiju No. 8|怪獸8號|怪獣8号|怪兽8号
My Hero Academia|我的英雄學院|僕のヒーローアカデミア|我的英雄学院
Black Clover|黑色五葉草|ブラッククローバー|黑色五叶草
Fairy Tail|FAIRY TAIL 魔導少年|FAIRY TAIL|妖精的尾巴
Soul Eater|噬魂者|ソウルイーター|噬魂师
Fire Force|炎炎消防隊|炎炎ノ消防隊|炎炎消防队
Gintama|銀魂|銀魂|银魂
The Disastrous Life of Saiki K.|齊木楠雄的災難|斉木楠雄のΨ難|齐木楠雄的灾难
Nichijou|日常|日常|日常
Daily Lives of High School Boys|男子高中生的日常|男子高校生の日常|男子高中生的日常
Konosuba|為美好的世界獻上祝福！|この素晴らしい世界に祝福を！|为美好的世界献上祝福
Re:Zero|Re：從零開始的異世界生活|Re:ゼロから始める異世界生活|Re从零开始的异世界生活
Sword Art Online|刀劍神域|ソードアート・オンライン|刀剑神域
That Time I Got Reincarnated as a Slime|關於我轉生變成史萊姆這檔事|転生したらスライムだった件|关于我转生变成史莱姆这档事
Overlord|OVERLORD 不死者之王|オーバーロード|不死者之王
No Game No Life|NO GAME NO LIFE 遊戲人生|ノーゲーム・ノーライフ|游戏人生
The Rising of the Shield Hero|盾之勇者成名錄|盾の勇者の成り上がり|盾之勇者成名录
Mushoku Tensei|無職轉生|無職転生|无职转生
86 Eighty-Six|86－不存在的戰區－|86―エイティシックス―|86不存在的战区
Code Geass|Code Geass 反叛的魯路修|コードギアス 反逆のルルーシュ|反叛的鲁路修
Psycho-Pass|PSYCHO-PASS 心靈判官|PSYCHO-PASS|心理测量者
Ghost in the Shell: Stand Alone Complex|攻殼機動隊 S.A.C.|攻殻機動隊 STAND ALONE COMPLEX|攻壳机动队
Akira|阿基拉|AKIRA|阿基拉
Serial Experiments Lain|玲音|serial experiments lain|玲音
Ergo Proxy|死亡代理人|Ergo Proxy|死亡代理人
Trigun|槍神|TRIGUN|枪神
Samurai Champloo|混沌武士|サムライチャンプルー|混沌武士
Rurouni Kenshin|浪客劍心|るろうに剣心|浪客剑心
Dororo|多羅羅|どろろ|多罗罗
The Apothecary Diaries|藥師少女的獨語|薬屋のひとりごと|药屋少女的呢喃
Heavenly Delusion|天國大魔境|天国大魔境|天国大魔境
Cyberpunk: Edgerunners|電馭叛客：邊緣行者|サイバーパンク エッジランナーズ|赛博浪客
Arcane
Castlevania
Blue Eye Samurai
''',
  ),
]);

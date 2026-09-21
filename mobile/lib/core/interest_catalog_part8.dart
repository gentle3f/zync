import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart8 = List.unmodifiable([
  ...parseInterestFamily(
    idPrefix: 'gaming.subgenre',
    category: 'gaming',
    cluster: 'gaming/subgenres',
    rankStart: 2100,
    raw: r'''
Action RPG|動作角色扮演遊戲|动作角色扮演游戏
Action Roguelike|動作 Roguelike 遊戲|动作 Roguelike 游戏
Action RTS|動作即時戰略遊戲|动作即时战略游戏
Action-Adventure Games|動作冒險遊戲|动作冒险游戏
Arena Shooter|競技場射擊遊戲|竞技场射击游戏
Auto Battler|自走棋|自走棋
Automation Games|自動化遊戲|自动化游戏
Base Building Games|基地建設遊戲|基地建设游戏
Battle Royale|大逃殺遊戲|大逃杀游戏
Beat 'em Up|清版動作遊戲|清版动作游戏
Boomer Shooter|復古快節奏射擊遊戲|复古快节奏射击游戏
Bullet Hell|彈幕射擊遊戲|弹幕射击游戏
Bullet Heaven|反向彈幕生存遊戲|反向弹幕生存游戏
Card Battler|卡牌戰鬥遊戲|卡牌战斗游戏
Character Action Games|角色動作遊戲|角色动作游戏
City Builder|城市建設遊戲|城市建设游戏
Co-op Campaign Games|合作戰役遊戲|合作战役游戏
Colony Sim|殖民地模擬遊戲|殖民地模拟游戏
Combat Racing|戰鬥賽車遊戲|战斗赛车游戏
Creature Collector|生物收集遊戲|生物收集游戏
CRPG|電腦角色扮演遊戲|电脑角色扮演游戏
Deckbuilding Games|牌庫構築遊戲|牌库构筑游戏
Detective Games|偵探遊戲|侦探游戏
Dungeon Crawler|地城探索遊戲|地牢探索游戏
Extraction Shooter|撤離射擊遊戲|撤离射击游戏
Farming Sim|農場模擬遊戲|农场模拟游戏
First-Person Adventure|第一身冒險遊戲|第一人称冒险游戏
Grand Strategy|大戰略遊戲|大战略游戏
Hack and Slash|砍殺遊戲|砍杀游戏
Hero Shooter|英雄射擊遊戲|英雄射击游戏
Hidden Object Games|尋物遊戲|寻物游戏
Immersive Sim|沉浸式模擬遊戲|沉浸式模拟游戏
Interactive Fiction|互動小說|互动小说
Life Sim|生活模擬遊戲|生活模拟游戏
Looter Shooter|刷寶射擊遊戲|刷宝射击游戏
Management Games|經營管理遊戲|经营管理游戏
Match-3 Games|三消遊戲|三消游戏
Metroidvania|類銀河戰士惡魔城遊戲|类银河战士恶魔城游戏
Military Games|軍事遊戲|军事游戏
MMORPG|大型多人線上角色扮演遊戲|大型多人在线角色扮演游戏
MOBA|多人線上戰術競技遊戲|多人在线战术竞技游戏
Mystery Dungeon|隨機迷宮探索遊戲|随机迷宫探索游戏
Open World Games|開放世界遊戲|开放世界游戏
Open World Survival Craft|開放世界生存建造遊戲|开放世界生存建造游戏
Party Games|派對遊戲|派对游戏
Party-Based RPG|隊伍制角色扮演遊戲|队伍制角色扮演游戏
Platformers|平台跳躍遊戲|平台跳跃游戏
Point-and-Click Adventure|點擊式冒險遊戲|点击式冒险游戏
Precision Platformer|高精度平台跳躍遊戲|高精度平台跳跃游戏
Programming Games|編程遊戲|编程游戏
Puzzle Platformer|解謎平台遊戲|解谜平台游戏
Real-Time Tactics|即時戰術遊戲|即时战术游戏
Rhythm Action Games|節奏動作遊戲|节奏动作游戏
Roguelite|Roguelite 遊戲|Roguelite 游戏
Roguelike Deckbuilder|Roguelike 牌庫構築遊戲|Roguelike 牌库构筑游戏
RTS|即時戰略遊戲|即时战略游戏
Sandbox Games|沙盒遊戲|沙盒游戏
Shoot 'Em Up|卷軸射擊遊戲|卷轴射击游戏
Social Deduction Games|社交推理遊戲|社交推理游戏
Soulslike|魂系遊戲|魂系游戏
Space Sim|太空模擬遊戲|太空模拟游戏
Stealth Games|潛行遊戲|潜行游戏
Strategy RPG|策略角色扮演遊戲|策略角色扮演游戏
Survival Horror|生存恐怖遊戲|生存恐怖游戏
Tactical RPG|戰術角色扮演遊戲|战术角色扮演游戏
Third-Person Shooter|第三人稱射擊遊戲|第三人称射击游戏
Tower Defense|塔防遊戲|塔防游戏
Traditional Roguelike|傳統 Roguelike 遊戲|传统 Roguelike 游戏
Turn-Based Combat|回合制戰鬥|回合制战斗
Turn-Based Strategy|回合制策略遊戲|回合制策略游戏
Turn-Based Tactics|回合制戰術遊戲|回合制战术游戏
Twin-Stick Shooter|雙搖桿射擊遊戲|双摇杆射击游戏
Walking Simulator|步行模擬遊戲|步行模拟游戏
4X Strategy|4X 策略遊戲|4X 策略游戏
Cozy Games|療癒系遊戲|治愈系游戏
Story-Rich Games|劇情豐富遊戲|剧情丰富游戏
Choices-Matter Games|選擇影響劇情遊戲|选择影响剧情游戏
Multiple-Ending Games|多結局遊戲|多结局游戏
Lore-Rich Games|世界觀豐富遊戲|世界观丰富游戏
Narrative Games|敘事遊戲|叙事游戏
Exploration Games|探索遊戲|探索游戏
Crafting Games|製作建造遊戲|制作建造游戏
Resource Management Games|資源管理遊戲|资源管理游戏
Economy Games|經濟模擬遊戲|经济模拟游戏
Political Sim|政治模擬遊戲|政治模拟游戏
God Games|上帝模擬遊戲|上帝模拟游戏
Job Simulators|職業模擬遊戲|职业模拟游戏
Shopkeeper Games|店舖經營遊戲|店铺经营游戏
Medical Sim|醫療模擬遊戲|医疗模拟游戏
Train Sim|火車模擬遊戲|火车模拟游戏
Flight Sim|飛行模擬遊戲|飞行模拟游戏
Automobile Sim|汽車模擬遊戲|汽车模拟游戏
Truck Sim|貨車模擬遊戲|卡车模拟游戏
Hunting Games|狩獵遊戲|狩猎游戏
Fishing Games|釣魚遊戲|钓鱼游戏
Skateboarding Games|滑板遊戲|滑板游戏
Snowboarding Games|單板滑雪遊戲|单板滑雪游戏
Skiing Games|滑雪遊戲|滑雪游戏
Golf Games|高爾夫遊戲|高尔夫游戏
Tennis Games|網球遊戲|网球游戏
Boxing Games|拳擊遊戲|拳击游戏
Wrestling Games|摔跤遊戲|摔跤游戏
Football Games|足球遊戲|足球游戏
Basketball Games|籃球遊戲|篮球游戏
Baseball Games|棒球遊戲|棒球游戏
Motorsport Games|賽車運動遊戲|赛车运动游戏
Naval Games|海戰遊戲|海战游戏
Tank Games|坦克遊戲|坦克游戏
Mech Games|機甲遊戲|机甲游戏
Space Combat Games|太空戰鬥遊戲|太空战斗游戏
Pirate Games|海盜遊戲|海盗游戏
Ninja Games|忍者遊戲|忍者游戏
Samurai Games|武士遊戲|武士游戏
Martial Arts Games|武術遊戲|武术游戏
Cyberpunk Games|賽博朋克遊戲|赛博朋克游戏
Post-Apocalyptic Games|末日後遊戲|末日后游戏
Lovecraftian Games|洛夫克拉夫特式遊戲|洛夫克拉夫特式游戏
Vampire Games|吸血鬼遊戲|吸血鬼游戏
Zombie Games|喪屍遊戲|丧尸游戏
Dinosaur Games|恐龍遊戲|恐龙游戏
Mythology Games|神話遊戲|神话游戏
Historical Games|歷史遊戲|历史游戏
Alternate-History Games|架空歷史遊戲|架空历史游戏
World War II Games|二戰遊戲|二战游戏
Cold War Games|冷戰遊戲|冷战游戏
Medieval Games|中世紀遊戲|中世纪游戏
Western Games|西部遊戲|西部游戏
Superhero Games|超級英雄遊戲|超级英雄游戏
Anime Games|動漫遊戲|动漫游戏
Otome Games|乙女遊戲|乙女游戏
Dating Sims|戀愛模擬遊戲|恋爱模拟游戏
Visual Novel Mystery|推理視覺小說|推理视觉小说
Escape-Room Games|密室逃脫遊戲|密室逃脱游戏
Trivia Games|問答遊戲|问答游戏
Word Games|文字遊戲|文字游戏
Typing Games|打字遊戲|打字游戏
Chess Games|國際象棋遊戲|国际象棋游戏
Mahjong Games|麻雀遊戲|麻将游戏
Poker Games|撲克遊戲|扑克游戏
Pinball Games|彈珠台遊戲|弹珠台游戏
Incremental Games|增量遊戲|增量游戏
Idle Games|放置遊戲|放置游戏
Collectathons|收集型遊戲|收集型游戏
Speedrunning|速通|速通
Modding Games|遊戲模組製作|game modding;mods|游戏模组制作
Level Editors|關卡編輯器|关卡编辑器
Game Creation Tools|遊戲製作工具|游戏制作工具
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'gaming.franchise',
    category: 'gaming',
    cluster: 'gaming/franchises',
    rankStart: 2300,
    raw: r'''
Baldur's Gate
The Witcher
Cyberpunk 2077
Mass Effect
Dragon Age
The Elder Scrolls
Skyrim
Fallout
Starfield
Diablo
World of Warcraft
Warcraft
StarCraft
Overwatch
Hearthstone
Destiny
Halo
Gears of War
Forza Horizon
Forza Motorsport
Age of Empires
Microsoft Flight Simulator
Sea of Thieves
Fable
DOOM
Quake
Wolfenstein
Dishonored
Prey
The Last of Us
Uncharted
God of War
Horizon
Ghost of Tsushima
Bloodborne
Demon's Souls
Ratchet & Clank
Gran Turismo
Shadow of the Colossus
The Last Guardian
LittleBigPlanet
Astro Bot
Persona
Shin Megami Tensei
Yakuza / Like a Dragon|yakuza;ryu ga gotoku
Kingdom Hearts
NieR
Dragon Quest
Chrono Trigger
Xenoblade Chronicles
Fire Emblem
Metroid
Kirby
Donkey Kong
Super Smash Bros.
Pikmin
Bayonetta
Xenogears
Octopath Traveler
Bravely Default
Tales Series
Ys Series
Trails / Kiseki
Suikoden
Mana Series
SaGa Series
Ace Attorney
Professor Layton
Phoenix Wright
Danganronpa
Zero Escape
AI: The Somnium Files
13 Sentinels: Aegis Rim
Metal Gear Solid
Death Stranding
Silent Hill
Resident Evil
Devil May Cry
Street Fighter
Tekken
Mortal Kombat
Soulcalibur
Guilty Gear
BlazBlue
King of Fighters
Fatal Fury
Monster Rancher
Digimon Games
Yo-kai Watch
Rune Factory
Story of Seasons
Harvest Moon
Stardew Valley
Terraria
Don't Starve
Subnautica
ARK: Survival Evolved
Rust
DayZ
Valheim
Palworld
No Man's Sky
Outer Wilds
The Outer Worlds
Portal
Half-Life
Left 4 Dead
Team Fortress 2
Garry's Mod
Apex Legends
PUBG
Call of Duty
Battlefield
Rainbow Six Siege
Escape from Tarkov
Warframe
Helldivers
Borderlands
BioShock
Far Cry
Assassin's Creed
Prince of Persia
Watch Dogs
Tom Clancy's Splinter Cell
Hitman
Tomb Raider
Just Cause
Saints Row
Red Dead Redemption
Max Payne
Mafia
Sleeping Dogs
L.A. Noire
Deathloop
Control
Alan Wake
Quantum Break
Remedy Connected Universe
Hades
Hollow Knight
Celeste
Dead Cells
Cuphead
Ori
Undertale
Deltarune
Disco Elysium
Inscryption
Slay the Spire
Balatro
Vampire Survivors
Enter the Gungeon
The Binding of Isaac
Risk of Rain
Spelunky
FTL: Faster Than Light
Into the Breach
Factorio
Satisfactory
Dyson Sphere Program
RimWorld
Dwarf Fortress
Oxygen Not Included
Kerbal Space Program
Cities: Skylines
SimCity
RollerCoaster Tycoon
Planet Coaster
Two Point Hospital
Theme Hospital
Zoo Tycoon
Planet Zoo
Anno
Crusader Kings
Europa Universalis
Hearts of Iron
Stellaris
Total War
XCOM
Command & Conquer
Company of Heroes
Homeworld
Warcraft III
Heroes of Might and Magic
Civilization VI
Sid Meier's Alpha Centauri
Football Manager Series
EA Sports FC|fifa games
NBA 2K
Madden NFL
MLB The Show
WWE 2K
Rocket League
Trackmania
Need for Speed
Burnout
Mario Kart
F-Zero
Wipeout
Assetto Corsa
iRacing
Gran Turismo 7
Forza Motorsport Series
Dirt Rally
F1 Games
Microsoft Train Simulator
Euro Truck Simulator
American Truck Simulator
The Sims 4
Animal Well
Dave the Diver
Dredge
Cult of the Lamb
Spiritfarer
A Short Hike
Unpacking
PowerWash Simulator
House Flipper
Cooking Mama
Overcooked
Moving Out
Human: Fall Flat
Gang Beasts
Fall Guys
Among Us
Jackbox Party Pack
Keep Talking and Nobody Explodes
Phasmophobia
Lethal Company
Dead by Daylight
Five Nights at Freddy's
Amnesia
Outlast
SOMA
Layers of Fear
Little Nightmares
Until Dawn
The Quarry
Life is Strange
Detroit: Become Human
Heavy Rain
The Walking Dead by Telltale
Telltale Games
Minecraft Dungeons
Minecraft Legends
Roblox Experiences
Fortnite Creative
Genshin Impact Characters
Honkai Impact 3rd
Zenless Zone Zero
Wuthering Waves
Arknights
Azur Lane
Fate/Grand Order
Blue Archive
Nikke
Uma Musume
Granblue Fantasy
Final Fantasy XIV|ffxiv
Final Fantasy VII
Final Fantasy X
Final Fantasy XVI
World of Final Fantasy
Pokémon Scarlet and Violet
Pokémon Legends
Pokémon Go
Pokémon Unite
Pokémon Mystery Dungeon
The Legend of Zelda: Breath of the Wild|botw
The Legend of Zelda: Tears of the Kingdom|totk
Ocarina of Time
Majora's Mask
Super Mario Odyssey
Super Mario Galaxy
Super Mario Bros. Wonder
Paper Mario
Mario Party
Luigi's Mansion
Splatoon 3
Animal Crossing: New Horizons
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'gaming.tabletop_style',
    category: 'gaming',
    cluster: 'tabletop/categories_mechanics',
    rankStart: 2700,
    raw: r'''
Abstract Strategy Games|抽象策略桌遊|抽象策略桌游
Area Control Games|區域控制桌遊|区域控制桌游
Auction Games|拍賣機制桌遊|拍卖机制桌游
Bluffing Games|虛張聲勢桌遊|虚张声势桌游
Campaign Board Games|戰役式桌遊|战役式桌游
Card Drafting Games|卡牌輪抽桌遊|卡牌轮抽桌游
City-Building Board Games|城市建設桌遊|城市建设桌游
Civilization Board Games|文明發展桌遊|文明发展桌游
Cooperative Board Games|合作桌遊|合作桌游
Deck-Building Board Games|牌庫構築桌遊|牌库构筑桌游
Deduction Games|推理桌遊|推理桌游
Dexterity Games|手部技巧桌遊|手部技巧桌游
Dice Games|骰子遊戲|骰子游戏
Economic Board Games|經濟桌遊|经济桌游
Engine-Building Games|引擎構築桌遊|引擎构筑桌游
Eurogames|德式桌遊|德式桌游
Hidden-Traitor Games|隱藏叛徒桌遊|隐藏叛徒桌游
Legacy Board Games|傳承式桌遊|传承式桌游
Miniature Wargames|微縮模型戰棋|微缩模型战棋
Negotiation Games|談判桌遊|谈判桌游
Party Board Games|派對桌遊|派对桌游
Push-Your-Luck Games|風險押注桌遊|风险押注桌游
Racing Board Games|競速桌遊|竞速桌游
Roll-and-Write Games|擲骰填寫遊戲|掷骰填写游戏
Set Collection Games|套組收集桌遊|套组收集桌游
Social Deduction Board Games|社交推理桌遊|社交推理桌游
Storytelling Board Games|故事敘述桌遊|故事叙述桌游
Tile-Laying Games|拼板放置桌遊|拼板放置桌游
Trading Games|交易桌遊|交易桌游
Train Board Games|鐵路桌遊|铁路桌游
Worker Placement Games|工人放置桌遊|工人放置桌游
Wargames|戰棋遊戲|战棋游戏
Word Board Games|文字桌遊|文字桌游
Escape-Room Board Games|密室逃脫桌遊|密室逃脱桌游
Living Card Games|LCG 成長式卡牌遊戲|LCG 成长式卡牌游戏
Collectible Card Games|收藏式卡牌遊戲|收藏式卡牌游戏
Trading Card Games|集換式卡牌遊戲|集换式卡牌游戏
Role-Playing Board Games|角色扮演桌遊|角色扮演桌游
Dungeon-Crawl Board Games|地城探索桌遊|地牢探索桌游
Adventure Board Games|冒險桌遊|冒险桌游
Horror Board Games|恐怖桌遊|恐怖桌游
Science-Fiction Board Games|科幻桌遊|科幻桌游
Fantasy Board Games|奇幻桌遊|奇幻桌游
Historical Board Games|歷史桌遊|历史桌游
Nature Board Games|自然主題桌遊|自然主题桌游
Cozy Board Games|輕鬆療癒桌遊|轻松治愈桌游
Two-Player Board Games|雙人桌遊|双人桌游
Solo Board Games|單人桌遊|单人桌游
Family Board Games|家庭桌遊|家庭桌游
Heavy Strategy Board Games|重度策略桌遊|重度策略桌游
Light Strategy Board Games|輕度策略桌遊|轻度策略桌游
Print-and-Play Games|自印桌遊|自印桌游
Board Game Design|桌遊設計|桌游设计
Board Game Cafes|桌遊咖啡店|桌游咖啡店
Board Game Conventions|桌遊展會|桌游展会
Miniature Painting|模型塗裝|模型涂装
Terrain Building|地形模型製作|地形模型制作
Role-Playing Miniatures|角色扮演模型|角色扮演模型
Dice Collecting|骰子收藏|骰子收藏
Card Sleeving|卡牌套保護|卡牌套保护
Board Game Organizing|桌遊收納|桌游收纳
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'gaming.boardgame_title',
    category: 'gaming',
    cluster: 'tabletop/boardgame_titles',
    rankStart: 2800,
    raw: r'''
Pandemic
Pandemic Legacy
Wingspan
Terraforming Mars
Brass: Birmingham
Brass: Lancashire
Ark Nova
Dune: Imperium
Dune: Imperium Uprising
Spirit Island
Scythe
Root
Oath
Pax Pamir
Twilight Struggle
Twilight Imperium
Eclipse
Gaia Project
Terra Mystica
Agricola
Caverna
A Feast for Odin
Viticulture
Concordia
Puerto Rico
Power Grid
Castles of Burgundy
Grand Austria Hotel
Great Western Trail
Arkham Horror
Eldritch Horror
Mansions of Madness
Marvel Champions
The Lord of the Rings: The Card Game
Netrunner
Dominion
Ascension
Star Realms
Hero Realms
Race for the Galaxy
7 Wonders
7 Wonders Duel
Splendor
Azul
Sagrada
Patchwork
Codenames
Decrypto
Just One
Dixit
Wavelength
The Resistance
Avalon
Secret Hitler
Blood on the Clocktower
Werewolf
Coup
Love Letter
Exploding Kittens
Sushi Go!
King of Tokyo
Small World
Stone Age
Lords of Waterdeep
Betrayal at House on the Hill
Dead of Winter
Nemesis
Zombicide
Mage Knight
Descent
HeroQuest
Mice and Mystics
Clank!
Clank! Catacombs
The Crew
The Mind
Hanabi
Skull
Santorini
Onitama
Hive
Quoridor
Blokus
Go Board Game
Shogi
Xiangqi Board Game
Backgammon
Checkers
Carrom
Crokinole
Monopoly
Risk
Cluedo / Clue
Scrabble
Boggle
Pictionary
Trivial Pursuit
Uno
Rummikub
Sequence
Ticket to Ride Europe
Carcassonne: Hunters and Gatherers
Catan: Cities & Knights
Catan: Seafarers
Munchkin
BANG!
Citadels
Power Plants
Heat: Pedal to the Metal
Flamme Rouge
Formula D
Memoir '44
Commands & Colors
War of the Ring
Star Wars: Rebellion
Star Wars: Imperial Assault
Disney Villainous
Horrified
Everdell
Cascadia
Calico
Parks
Meadow
Forest Shuffle
Earth
Photosynthesis
Takenoko
Tokaido
Jaipur
Lost Cities
Watergate
Radlands
Air, Land & Sea
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'gaming.ttrpg',
    category: 'gaming',
    cluster: 'tabletop/ttrpg',
    rankStart: 3000,
    raw: r'''
Pathfinder
Pathfinder 2e
Call of Cthulhu RPG
Cyberpunk RED
Shadowrun
Vampire: The Masquerade
Werewolf: The Apocalypse
World of Darkness
Warhammer Fantasy Roleplay
Warhammer 40K Roleplay
Star Wars Roleplaying Games
Blades in the Dark
Fate Core
Powered by the Apocalypse
Monster of the Week
Masks: A New Generation
Dungeon World
Kids on Bikes
Mörk Borg
Cairn
Old-School Essentials
OSR Roleplaying
Traveller RPG
Delta Green
Lancer RPG
Numenera
Genesys RPG
Legend of the Five Rings RPG
The One Ring RPG
Alien RPG
Vaesen
Tales from the Loop RPG
Mouse Guard RPG
Fabula Ultima
Final Fantasy XIV TTRPG
Critical Role
Dimension 20
Actual Play RPG Shows
Dungeon Mastering
Game Mastering
RPG Worldbuilding
RPG Miniatures
RPG Dice
RPG Map Making
''',
  ),
]);

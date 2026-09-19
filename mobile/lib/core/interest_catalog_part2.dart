import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart2 = parseInterestCatalogRows(r'''gaming.video|gaming|gaming_general|14|Video Games|電子遊戲|电子游戏|gaming;games;電玩
gaming.board|gaming|tabletop|15|Board Games|桌上遊戲|桌游|boardgames;桌遊
gaming.pc_gaming|gaming|gaming_general|245|PC Gaming|PC 遊戲|PC 游戏|
gaming.console_gaming|gaming|gaming_general|246|Console Gaming|主機遊戲|主机游戏|
gaming.mobile_gaming|gaming|gaming_general|247|Mobile Gaming|手機遊戲|手机游戏|
gaming.retro_gaming|gaming|gaming_general|248|Retro Gaming|復古遊戲|复古游戏|
gaming.indie_games|gaming|gaming_general|249|Indie Games|獨立遊戲|独立游戏|
gaming.vr_gaming|gaming|gaming_general|250|VR Gaming|VR 遊戲|VR 游戏|
gaming.game_development|gaming|gaming_general|251|Game Development|遊戲開發|游戏开发|gamedev
gaming.esports|gaming|gaming_general|252|Esports|電子競技|电子竞技|電競;电竞
gaming.rpg|gaming|game_genres|260|RPGs|角色扮演遊戲|角色扮演游戏|role playing games
gaming.jrpg|gaming|game_genres|261|JRPGs|日式角色扮演遊戲|日式角色扮演游戏|
gaming.fps|gaming|game_genres|262|FPS Games|第一身射擊遊戲|第一人称射击游戏|first person shooters
gaming.strategy|gaming|game_genres|263|Strategy Games|策略遊戲|策略游戏|
gaming.simulation|gaming|game_genres|264|Simulation Games|模擬遊戲|模拟游戏|
gaming.racing_games|gaming|game_genres|265|Racing Games|賽車遊戲|赛车游戏|
gaming.fighting_games|gaming|game_genres|266|Fighting Games|格鬥遊戲|格斗游戏|
gaming.sports_games|gaming|game_genres|267|Sports Games|體育遊戲|体育游戏|
gaming.puzzle_games|gaming|game_genres|268|Puzzle Games|益智遊戲|益智游戏|
gaming.horror_games|gaming|game_genres|269|Horror Games|恐怖遊戲|恐怖游戏|
gaming.survival_games|gaming|game_genres|270|Survival Games|生存遊戲|生存游戏|
gaming.sandbox_games|gaming|game_genres|271|Sandbox Games|沙盒遊戲|沙盒游戏|
gaming.roguelikes|gaming|game_genres|272|Roguelikes|Roguelike 遊戲|Roguelike 游戏|
gaming.visual_novels|gaming|game_genres|273|Visual Novels|視覺小說|视觉小说|
gaming.rhythm_games|gaming|game_genres|274|Rhythm Games|音樂節奏遊戲|音乐节奏游戏|
gaming.minecraft|gaming|game_titles|280|Minecraft|||
gaming.roblox|gaming|game_titles|281|Roblox|||
gaming.fortnite|gaming|game_titles|282|Fortnite|||
gaming.league_of_legends|gaming|game_titles|283|League of Legends|||lol
gaming.valorant|gaming|game_titles|284|VALORANT|||
gaming.counter_strike|gaming|game_titles|285|Counter-Strike|||cs2;csgo
gaming.dota_2|gaming|game_titles|286|Dota 2|||
gaming.genshin_impact|gaming|game_titles|287|Genshin Impact|||原神
gaming.honkai_star_rail|gaming|game_titles|288|Honkai: Star Rail|||崩壞星穹鐵道;崩坏星穹铁道
gaming.pokemon_games|gaming|game_titles|289|Pokémon Games|寶可夢遊戲|宝可梦游戏|pokemon
gaming.zelda|gaming|game_titles|290|The Legend of Zelda|||zelda
gaming.mario|gaming|game_titles|291|Mario|||
gaming.animal_crossing|gaming|game_titles|292|Animal Crossing|||
gaming.splatoon|gaming|game_titles|293|Splatoon|||
gaming.final_fantasy|gaming|game_titles|294|Final Fantasy|||ff
gaming.monster_hunter|gaming|game_titles|295|Monster Hunter|||
gaming.elden_ring|gaming|game_titles|296|Elden Ring|||
gaming.dark_souls|gaming|game_titles|297|Dark Souls|||
gaming.grand_theft_auto|gaming|game_titles|298|Grand Theft Auto|||gta
gaming.the_sims|gaming|game_titles|299|The Sims|||
gaming.civilization|gaming|game_titles|300|Civilization|||
gaming.football_manager|gaming|game_titles|301|Football Manager|||
gaming.dungeons_and_dragons|gaming|tabletop|310|Dungeons & Dragons|||dnd;d&d
gaming.tabletop_rpg|gaming|tabletop|311|Tabletop RPGs|桌上角色扮演遊戲|桌上角色扮演游戏|ttrpg
gaming.warhammer|gaming|tabletop|312|Warhammer|||
gaming.magic_the_gathering|gaming|tabletop|313|Magic: The Gathering|||mtg
gaming.pokemon_tcg|gaming|tabletop|314|Pokémon TCG|||
gaming.yu_gi_oh|gaming|tabletop|315|Yu-Gi-Oh!|||
gaming.catan|gaming|tabletop|316|Catan|||
gaming.ticket_to_ride|gaming|tabletop|317|Ticket to Ride|||
gaming.carcassonne|gaming|tabletop|318|Carcassonne|||
gaming.gloomhaven|gaming|tabletop|319|Gloomhaven|||''');

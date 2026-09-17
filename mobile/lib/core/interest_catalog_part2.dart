import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart2 = parseInterestCatalogRows(r'''gaming.video|gaming|gaming_general|14|Video Games|電子遊戲|电子游戏|gaming;games;電玩
gaming.board|gaming|tabletop|15|Board Games|桌上遊戲|桌游|boardgames;桌遊
gaming.pc_gaming|gaming|gaming_general|245|PC Gaming|||
gaming.console_gaming|gaming|gaming_general|246|Console Gaming|||
gaming.mobile_gaming|gaming|gaming_general|247|Mobile Gaming|||
gaming.retro_gaming|gaming|gaming_general|248|Retro Gaming|||
gaming.indie_games|gaming|gaming_general|249|Indie Games|||
gaming.vr_gaming|gaming|gaming_general|250|VR Gaming|||
gaming.game_development|gaming|gaming_general|251|Game Development|||gamedev
gaming.esports|gaming|gaming_general|252|Esports|||電競;电竞
gaming.rpg|gaming|game_genres|260|RPGs|||role playing games
gaming.jrpg|gaming|game_genres|261|JRPGs|||
gaming.fps|gaming|game_genres|262|FPS Games|||first person shooters
gaming.strategy|gaming|game_genres|263|Strategy Games|||
gaming.simulation|gaming|game_genres|264|Simulation Games|||
gaming.racing_games|gaming|game_genres|265|Racing Games|||
gaming.fighting_games|gaming|game_genres|266|Fighting Games|||
gaming.sports_games|gaming|game_genres|267|Sports Games|||
gaming.puzzle_games|gaming|game_genres|268|Puzzle Games|||
gaming.horror_games|gaming|game_genres|269|Horror Games|||
gaming.survival_games|gaming|game_genres|270|Survival Games|||
gaming.sandbox_games|gaming|game_genres|271|Sandbox Games|||
gaming.roguelikes|gaming|game_genres|272|Roguelikes|||
gaming.visual_novels|gaming|game_genres|273|Visual Novels|||
gaming.rhythm_games|gaming|game_genres|274|Rhythm Games|||
gaming.minecraft|gaming|game_titles|280|Minecraft|||
gaming.roblox|gaming|game_titles|281|Roblox|||
gaming.fortnite|gaming|game_titles|282|Fortnite|||
gaming.league_of_legends|gaming|game_titles|283|League of Legends|||lol
gaming.valorant|gaming|game_titles|284|VALORANT|||
gaming.counter_strike|gaming|game_titles|285|Counter-Strike|||cs2;csgo
gaming.dota_2|gaming|game_titles|286|Dota 2|||
gaming.genshin_impact|gaming|game_titles|287|Genshin Impact|||原神
gaming.honkai_star_rail|gaming|game_titles|288|Honkai: Star Rail|||崩壞星穹鐵道;崩坏星穹铁道
gaming.pokemon_games|gaming|game_titles|289|Pokémon Games|||pokemon
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
gaming.tabletop_rpg|gaming|tabletop|311|Tabletop RPGs|||ttrpg
gaming.warhammer|gaming|tabletop|312|Warhammer|||
gaming.magic_the_gathering|gaming|tabletop|313|Magic: The Gathering|||mtg
gaming.pokemon_tcg|gaming|tabletop|314|Pokémon TCG|||
gaming.yu_gi_oh|gaming|tabletop|315|Yu-Gi-Oh!|||
gaming.catan|gaming|tabletop|316|Catan|||
gaming.ticket_to_ride|gaming|tabletop|317|Ticket to Ride|||
gaming.carcassonne|gaming|tabletop|318|Carcassonne|||
gaming.gloomhaven|gaming|tabletop|319|Gloomhaven|||''');

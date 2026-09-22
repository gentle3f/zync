import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart16 = parseInterestCatalogRows(r'''sports.american_football_fandom|sports|fandom|620|American Football Fandom|||
sports.basketball_fandom|sports|fandom|638|Basketball Fandom|||
sports.baseball_fandom|sports|fandom|656|Baseball Fandom|||
sports.ice_hockey_fandom|sports|fandom|674|Ice Hockey Fandom|||Hockey Fandom
sports.soccer_fandom|sports|fandom|692|Soccer Fandom|||
sports.college_sports|sports|fandom|710|College Sports|||
sports.college_football|sports|fandom|728|College Football|||
sports.college_basketball|sports|fandom|746|College Basketball|||
sports.fantasy_sports|sports|fandom|764|Fantasy Sports|||
sports.fantasy_football|sports|fandom|782|Fantasy Football|||
sports.fantasy_baseball|sports|fandom|800|Fantasy Baseball|||
sports.fantasy_basketball|sports|fandom|818|Fantasy Basketball|||
sports.tailgating|sports|fandom|836|Tailgating|||
sports.sports_watch_parties|sports|fandom|854|Sports Watch Parties|||Super Bowl Parties
sports.recreational_sports_leagues|sports|community_sports|872|Recreational Sports Leagues|||
sports.intramural_sports|sports|community_sports|890|Intramural Sports|||
sports.kickball|sports|team_ball|908|Kickball|||
sports.flag_football|sports|team_ball|926|Flag Football|||
sports.cornhole|sports|precision|944|Cornhole|||
sports.bocce|sports|precision|962|Bocce|||
sports.shuffleboard|sports|precision|980|Shuffleboard|||
sports.axe_throwing|sports|precision|998|Axe Throwing|||
lifestyle.block_parties|lifestyle|social|900|Block Parties|||
lifestyle.community_cleanups|lifestyle|social|912|Community Cleanups|||
lifestyle.game_nights|lifestyle|social|924|Game Nights|||
lifestyle.puzzle_nights|lifestyle|social|936|Puzzle Nights|||
lifestyle.craft_nights|lifestyle|social|948|Craft Nights|||
lifestyle.coffee_walks|lifestyle|social|960|Coffee Walks|||
lifestyle.silent_discos|lifestyle|social|972|Silent Discos|||
lifestyle.dance_socials|lifestyle|social|984|Dance Socials|||
lifestyle.estate_sales|lifestyle|shopping|996|Estate Sales|||
lifestyle.garage_and_yard_sales|lifestyle|shopping|1008|Garage & Yard Sales|||
lifestyle.record_store_browsing|lifestyle|shopping|1020|Record Store Browsing|||
lifestyle.bookstore_browsing|lifestyle|shopping|1032|Bookstore Browsing|||
lifestyle.library_events|lifestyle|social|1044|Library Events|||
lifestyle.plant_shop_browsing|lifestyle|shopping|1056|Plant Shop Browsing|||
food.food_trucks|food|food/dining|1068|Food Trucks|||
food.american_diners|food|food/dining|1080|American Diners|||
lifestyle.county_and_state_fairs|lifestyle|social|1092|County & State Fairs|||
lifestyle.renaissance_fairs|lifestyle|social|1104|Renaissance Fairs|||
lifestyle.food_festivals|lifestyle|social|1116|Food Festivals|||
lifestyle.art_festivals|lifestyle|social|1128|Art Festivals|||
lifestyle.street_festivals|lifestyle|social|1140|Street Festivals|||
lifestyle.parades|lifestyle|social|1152|Parades|||
lifestyle.neighborhood_exploration|lifestyle|social|1164|Neighborhood Exploration|||
outdoors.state_parks|outdoors|parks|820|State Parks|||
travel.scenic_drives|travel|travel_styles|832|Scenic Drives|||
travel.cabin_getaways|travel|travel_styles|844|Cabin Getaways|||
outdoors.lake_life|outdoors|water|856|Lake Life|||
outdoors.beach_days|outdoors|water|868|Beach Days|||
outdoors.river_tubing_and_float_trips|outdoors|water|880|River Tubing & Float Trips|||River Tubing;Float Trips;Floating the River
outdoors.bass_fishing|outdoors|water|892|Bass Fishing|||
outdoors.ice_fishing|outdoors|winter|904|Ice Fishing|||
outdoors.atv_riding|outdoors|motorized_recreation|916|ATV Riding|||
outdoors.utv_riding|outdoors|motorized_recreation|928|UTV Riding|||
outdoors.dirt_biking|outdoors|motorized_recreation|940|Dirt Biking|||Dirt Bikes
motorsport.motocross|motorsport|motorsport|952|Motocross|||
outdoors.snowmobiling|outdoors|winter|964|Snowmobiling|||
outdoors.rv_life|outdoors|camping|976|RV Life|||
transport.pickup_trucks|transport|cars|760|Pickup Trucks|||Truck Culture
transport.muscle_cars|transport|cars|774|Muscle Cars|||
transport.car_meets|transport|cars|788|Car Meets|||
transport.car_shows|transport|cars|802|Car Shows|||
transport.car_restoration|transport|cars|816|Car Restoration|||
learning.greek_life|learning|campus|760|Greek Life|||Fraternity Life;Sorority Life
learning.student_government|learning|campus|774|Student Government|||
learning.dorm_life|learning|campus|788|Dorm Life|||
learning.campus_life|learning|campus|802|Campus Life|||
learning.homecoming|learning|campus|816|Homecoming|||
learning.spring_break|learning|campus|830|Spring Break|||
learning.school_spirit|learning|campus|844|School Spirit|||
learning.career_fairs|learning|campus|858|Career Fairs|||
learning.internships|learning|campus|872|Internships|||
lifestyle.new_parents|lifestyle|family|860|New Parents|||
lifestyle.playdates|lifestyle|family|874|Playdates|||
lifestyle.toddler_activities|lifestyle|family|888|Toddler Activities|||
lifestyle.family_game_nights|lifestyle|family|902|Family Game Nights|||
lifestyle.family_movie_nights|lifestyle|family|916|Family Movie Nights|||
lifestyle.date_nights|lifestyle|family|930|Date Nights|||
lifestyle.youth_sports|lifestyle|family|944|Youth Sports|||
lifestyle.youth_baseball|lifestyle|family|958|Youth Baseball|||
lifestyle.summer_camp|lifestyle|family|972|Summer Camp|||
pets.dog_parks|pets|pets|940|Dog Parks|||
pets.pet_adoption|pets|pets|954|Pet Adoption|||
pets.dog_sports|pets|pets|968|Dog Sports|||
pets.pet_sitting|pets|pets|982|Pet Sitting|||
sports.horse_shows|sports|equestrian|996|Horse Shows|||
sports.rodeo|sports|equestrian|1010|Rodeo|||
sports.western_riding|sports|equestrian|1024|Western Riding|||
lifestyle.lawn_care|lifestyle|home|980|Lawn Care|||
lifestyle.online_communities|lifestyle|social|760|Online Communities|||
entertainment.memes|entertainment|pop_culture|774|Memes|||
entertainment.internet_culture|entertainment|pop_culture|788|Internet Culture|||
entertainment.true_crime_podcasts|entertainment|audio|802|True Crime Podcasts|||
learning.newsletter_reading|learning|books|816|Newsletter Reading|||
career.software_engineering|career|technology_careers|820|Software Engineering|||
career.journalism|career|media|836|Journalism|||
career.hospitality|career|hospitality|852|Hospitality|||
career.construction|career|trades|868|Construction|||
career.skilled_trades|career|trades|884|Skilled Trades|||
career.social_work|career|social_services|900|Social Work|||
career.physiotherapy|career|healthcare|916|Physiotherapy|||
career.veterinary_medicine|career|healthcare|932|Veterinary Medicine|||
career.ai_and_machine_learning_engineering|career|technology_careers|948|AI & Machine Learning Engineering|||
career.culinary_profession|career|hospitality|964|Culinary Profession|||
wellness.hot_yoga|wellness|fitness|780|Hot Yoga|||
wellness.reformer_pilates|wellness|fitness|796|Reformer Pilates|||
lifestyle.slow_living|lifestyle|home|812|Slow Living|||
lifestyle.alcohol_free_socials|lifestyle|social|828|Alcohol-Free Socials|||
entertainment.film_festivals|entertainment|screen|844|Film Festivals|||
entertainment.anime_conventions|entertainment|anime_manga|860|Anime Conventions|||
gaming.city_building_games|gaming|gaming/subgenres|876|City-Building Games|||
arts.visual_arts|arts|visual_art|900|Visual Arts|||Art Club
arts.dance|arts|dance|910|Dance|||Dance Team
lifestyle.study_cafes|lifestyle|social|900|Study Cafes|||Cafe Studying;Study Cafe
arts.painting_socials|arts|visual_art|920|Painting Socials|||Art Jamming;Social Painting
lifestyle.pop_up_markets|lifestyle|shopping|940|Pop-up Markets|||Pop-up Market;Popup Markets
lifestyle.photo_booths|lifestyle|social|980|Photo Booths|||Photo Booth;Self Photo Studio
food.late_night_eats|food|food/dining|900|Late-night Eats|||Late-night Dining;Late Night Food''');

final Set<String> kInterestCatalogPart16Ids =
    Set.unmodifiable(kInterestCatalogPart16.map((item) => item.id));

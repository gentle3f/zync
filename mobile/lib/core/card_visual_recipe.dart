import 'cardverse_models.dart';
import 'interest_entity_metadata.dart';

class CardCategoryKitDefinition {
  const CardCategoryKitDefinition({
    required this.id,
    required this.paletteCount,
    required this.defaultSceneGrammar,
  });

  final String id;
  final int paletteCount;
  final String defaultSceneGrammar;
}

class CardVisualRecipe {
  const CardVisualRecipe({
    required this.interestId,
    required this.artSystemVersion,
    required this.visualSeed,
    required this.categoryKit,
    required this.visualFamily,
    required this.iconKey,
    required this.sceneGrammar,
    required this.paletteSlot,
    required this.artPolicy,
  });

  final String interestId;
  final int artSystemVersion;
  final String visualSeed;
  final String categoryKit;
  final String visualFamily;
  final String iconKey;
  final String sceneGrammar;
  final int paletteSlot;
  final CardArtPolicy artPolicy;
}

class CardVisualRecipeResolver {
  const CardVisualRecipeResolver._();

  static const int artSystemVersion = 1;

  static const categoryKits = <String, CardCategoryKitDefinition>{
    'sports': CardCategoryKitDefinition(
      id: 'sports',
      paletteCount: 8,
      defaultSceneGrammar: 'sports_motion_field',
    ),
    'outdoors': CardCategoryKitDefinition(
      id: 'outdoors',
      paletteCount: 7,
      defaultSceneGrammar: 'outdoors_layered_terrain',
    ),
    'food': CardCategoryKitDefinition(
      id: 'food',
      paletteCount: 8,
      defaultSceneGrammar: 'food_table_stamp',
    ),
    'travel': CardCategoryKitDefinition(
      id: 'travel',
      paletteCount: 7,
      defaultSceneGrammar: 'travel_route_stamp',
    ),
    'entertainment': CardCategoryKitDefinition(
      id: 'entertainment',
      paletteCount: 7,
      defaultSceneGrammar: 'cinema_frame_light',
    ),
    'music': CardCategoryKitDefinition(
      id: 'music',
      paletteCount: 8,
      defaultSceneGrammar: 'music_rhythm_stage',
    ),
    'gaming': CardCategoryKitDefinition(
      id: 'gaming',
      paletteCount: 8,
      defaultSceneGrammar: 'gaming_grid_world',
    ),
    'learning': CardCategoryKitDefinition(
      id: 'learning',
      paletteCount: 6,
      defaultSceneGrammar: 'learning_page_layers',
    ),
    'arts': CardCategoryKitDefinition(
      id: 'arts',
      paletteCount: 8,
      defaultSceneGrammar: 'arts_layered_canvas',
    ),
    'crafts': CardCategoryKitDefinition(
      id: 'crafts',
      paletteCount: 8,
      defaultSceneGrammar: 'crafts_cut_paper',
    ),
    'technology': CardCategoryKitDefinition(
      id: 'technology',
      paletteCount: 7,
      defaultSceneGrammar: 'technology_node_grid',
    ),
    'wellness': CardCategoryKitDefinition(
      id: 'wellness',
      paletteCount: 7,
      defaultSceneGrammar: 'wellness_radial_balance',
    ),
    'nature': CardCategoryKitDefinition(
      id: 'nature',
      paletteCount: 7,
      defaultSceneGrammar: 'nature_organic_layers',
    ),
    'motorsport': CardCategoryKitDefinition(
      id: 'motorsport',
      paletteCount: 7,
      defaultSceneGrammar: 'motorsport_speed_track',
    ),
    'collecting': CardCategoryKitDefinition(
      id: 'collecting',
      paletteCount: 7,
      defaultSceneGrammar: 'collecting_display_grid',
    ),
  };

  static const sceneGrammarByFamily = <String, String>{
    'sports_racket': 'court_arc',
    'sports_team_ball': 'team_ball_trajectory',
    'sports_running': 'track_stride',
    'outdoors_trail': 'trail_ridge',
    'outdoors_climbing': 'climbing_facets',
    'outdoors_water': 'water_motion',
    'food_drink': 'drink_rings_stamp',
    'food_cooking': 'cooking_utensil_layers',
    'arts_photography': 'camera_frame_walk',
    'entertainment_cinema': 'cinema_frame_light',
    'music_genre': 'music_rhythm_stage',
    'gaming_general': 'gaming_grid_world',
    'learning_books': 'learning_page_layers',
    'crafts_diy': 'crafts_cut_paper',
    'wellness_mind_body': 'wellness_radial_balance',
    'motorsport_racing': 'motorsport_speed_track',
    'collecting_building': 'collecting_build_grid',
    'outdoors_camp': 'campfire_horizon',
    'nature_night_sky': 'night_sky_orbit',
    'nature_wildlife': 'wildlife_observation',
    'travel_route': 'travel_route_stamp',
    'travel_destination': 'travel_destination_layers',
    'travel_roadtrip': 'travel_road_ribbon',
    'travel_food': 'travel_food_stamp',
    'technology_ai': 'technology_node_grid',
    'technology_code': 'technology_code_grid',
    'technology_robotics': 'technology_mechanical_nodes',
    'technology_hardware': 'technology_hardware_grid',
    'wellness_fitness': 'wellness_energy_rings',
    'arts_visual': 'arts_layered_canvas',
    'arts_ceramics': 'arts_ceramic_form',
    'food_cuisine': 'food_plate_stamp',
    'music_instrument': 'music_keys',
    'music_live': 'music_stage_lights',
    'gaming_tabletop': 'gaming_board_grid',
    'gaming_strategy': 'gaming_strategy_nodes',
    'learning_languages': 'learning_language_cards',
    'learning_history': 'learning_timeline',
    'crafts_textile': 'crafts_thread_weave',
  };

  static const proofInterestIds = <String>[
    'sports.badminton',
    'sports.basketball',
    'outdoors.bouldering',
    'food.coffee',
    'food.cooking',
    'wellness.yoga',
    'photography.general',
    'media.movies',
    'music.pop',
    'gaming.video',
    'books.reading',
    'crafts.diy',
  ];

  static const expandedProofInterestIds = <String>[
    ...proofInterestIds,
    'sports.tennis',
    'sports.running',
    'sports.hiking',
    'collecting.lego',
    'motorsport.formula1',
    'sports.table_tennis',
    'sports.pickleball',
    'outdoors.swimming',
    'photography.street',
    'travel.general',
    'travel.japan',
    'travel.roadtrip',
    'travel.food_travel',
    'technology.ai',
    'technology.programming',
    'technology.robotics',
    'technology.mechanical_keyboards',
    'outdoors.camping',
    'outdoors.surfing',
    'outdoors.stargazing',
    'outdoors.birdwatching',
    'wellness.pilates',
    'wellness.meditation',
    'sports.gym',
    'arts.drawing',
    'arts.watercolor',
    'arts.ceramics',
    'food.japanese',
    'food.dim_sum',
    'food.sushi',
    'music.rock',
    'music.piano',
    'music.concerts',
    'gaming.board',
    'gaming.strategy',
    'learning.languages',
    'history.general',
    'crafts.knitting',
  ];

  static CardVisualRecipe? resolve(String interestId) {
    final metadata = InterestEntityMetadataRegistry.byInterestId(interestId);
    final card = metadata?.card;
    if (card == null ||
        !card.collectible ||
        card.artPolicy == CardArtPolicy.notCollectible ||
        card.visualFamily.trim().isEmpty ||
        card.iconKey.trim().isEmpty ||
        card.categoryKit.trim().isEmpty) {
      return null;
    }

    final kit = categoryKits[card.categoryKit];
    if (kit == null) return null;

    final seed = CardVisualIdentity.seedFor(
      interestId: interestId,
      artSystemVersion: artSystemVersion,
    );
    final paletteHash = int.parse(seed.substring(0, 8), radix: 16);
    final sceneGrammar =
        sceneGrammarByFamily[card.visualFamily] ??
        kit.defaultSceneGrammar;

    return CardVisualRecipe(
      interestId: interestId,
      artSystemVersion: artSystemVersion,
      visualSeed: seed,
      categoryKit: kit.id,
      visualFamily: card.visualFamily,
      iconKey: card.iconKey,
      sceneGrammar: sceneGrammar,
      paletteSlot: paletteHash % kit.paletteCount,
      artPolicy: card.artPolicy,
    );
  }

  static List<CardVisualRecipe> proofBatch() =>
      _resolveBatch(proofInterestIds, label: 'visual');

  static List<CardVisualRecipe> expandedProofBatch() =>
      _resolveBatch(expandedProofInterestIds, label: 'expanded');

  static List<CardVisualRecipe> _resolveBatch(
    List<String> interestIds, {
    required String label,
  }) {
    final recipes = <CardVisualRecipe>[];
    for (final interestId in interestIds) {
      final recipe = resolve(interestId);
      if (recipe == null) {
        throw StateError(
          'Missing Cardverse $label proof recipe for $interestId',
        );
      }
      recipes.add(recipe);
    }
    return List.unmodifiable(recipes);
  }
}

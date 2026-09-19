import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/card_interest_bridge.dart';
import 'package:zync/core/models.dart';

void main() {
  test('new card discovery can add canonical interest as Want to Try', () {
    final result = CardInterestIntentBridge.upsertWantToTry(
      existing: const [],
      interestId: 'outdoors.bouldering',
    );

    expect(result, hasLength(1));
    expect(result.single.id, 'outdoors.bouldering');
    expect(result.single.strength, InterestStrength.wantToTry);
  });

  test('Want to Try never downgrades an existing Like', () {
    final result = CardInterestIntentBridge.upsertWantToTry(
      existing: const [
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.like,
        ),
      ],
      interestId: 'sports.badminton',
    );

    expect(result.single.strength, InterestStrength.like);
  });

  test('Want to Try never downgrades an existing Love', () {
    final result = CardInterestIntentBridge.upsertWantToTry(
      existing: const [
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.love,
        ),
      ],
      interestId: 'sports.badminton',
    );

    expect(result.single.strength, InterestStrength.love);
  });

  test('removing Want to Try does not remove Like or Love interests', () {
    final result = CardInterestIntentBridge.removeWantToTry(
      existing: const [
        SelectedInterest(
          id: 'outdoors.bouldering',
          strength: InterestStrength.wantToTry,
        ),
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.like,
        ),
        SelectedInterest(
          id: 'food.coffee',
          strength: InterestStrength.love,
        ),
      ],
      interestId: 'sports.badminton',
    );

    expect(result, hasLength(3));
    expect(
      result.firstWhere((item) => item.id == 'sports.badminton').strength,
      InterestStrength.like,
    );
  });

  test('removing a real Want to Try entry removes only that entry', () {
    final result = CardInterestIntentBridge.removeWantToTry(
      existing: const [
        SelectedInterest(
          id: 'outdoors.bouldering',
          strength: InterestStrength.wantToTry,
        ),
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.like,
        ),
      ],
      interestId: 'outdoors.bouldering',
    );

    expect(result.map((item) => item.id), ['sports.badminton']);
  });

  test('non-canonical card interest cannot enter Interest DNA', () {
    expect(
      () => CardInterestIntentBridge.wantToTry('fake.interest'),
      throwsArgumentError,
    );
  });
}

part of 'badge.dart';

enum BadgesStatus {
  locked('0'),
  unlocked('1'),
  rewardUnlocked('2')
  ;

  const BadgesStatus(this.value);

  final String value;

  static BadgesStatus fromString(String value) => BadgesStatus.values
      .firstWhere((e) => e.value == value, orElse: () => BadgesStatus.locked);
}

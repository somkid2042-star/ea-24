part 'badge_status_enum.dart';

final class Badges {
  const Badges({
    required this.id,
    required this.type,
    required this.badgeReward,
    required this.badgeIcon,
    required this.badgeCounter,
    required this.status,
  });

  Badges.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String? ?? '',
      type = json['type'] as String? ?? '',
      badgeReward = json['badge_reward'] as String? ?? '',
      badgeIcon = json['badge_icon'] as String? ?? '',
      badgeCounter = json['badge_counter'] as String? ?? '',
      status = BadgesStatus.fromString(json['status'] as String? ?? '0');

  final String id;
  final String type;
  final String badgeReward;
  final String badgeIcon;
  final String badgeCounter;
  final BadgesStatus status;

  Badges updateBadgeStatus(BadgesStatus updatedStatus) {
    return Badges(
      id: id,
      type: type,
      badgeReward: badgeReward,
      badgeIcon: badgeIcon,
      badgeCounter: badgeCounter,
      status: updatedStatus,
    );
  }
}

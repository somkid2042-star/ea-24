final class Contests {
  const Contests({
    required this.live,
    required this.past,
    required this.upcoming,
  });

  Contests.fromJson(Map<String, dynamic> json)
    : live = Contest.fromJson(json['live_contest'] as Map<String, dynamic>),
      past = Contest.fromJson(json['past_contest'] as Map<String, dynamic>),
      upcoming = Contest.fromJson(
        json['upcoming_contest'] as Map<String, dynamic>,
      );

  final Contest past;
  final Contest live;
  final Contest upcoming;
}

final class Contest {
  const Contest({required this.contestDetails, required this.errorMessage});

  Contest.fromJson(Map<String, dynamic> json)
    : errorMessage = json['error'] as bool ? json['message'] as String : '',
      contestDetails = json['error'] as bool
          ? <ContestDetails>[]
          : (json['data'] as List)
                .cast<Map<String, dynamic>>()
                .map(ContestDetails.fromJson)
                .toList(growable: false);

  final String errorMessage;
  final List<ContestDetails> contestDetails;
}

final class ContestDetails {
  ContestDetails({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
    this.description,
    this.image,
    this.entry,
    this.prizeStatus,
    this.dateCreated,
    this.status,
    this.points,
    this.topUsers,
    this.participants,
    this.showDescription = false,
  });

  ContestDetails.fromJson(Map<String, dynamic> json)
    : showDescription = false,
      id = json['id'] as String?,
      name = json['name'] as String?,
      startDate = json['start_date'] as String?,
      endDate = json['end_date'] as String?,
      description = json['description'] as String?,
      image = json['image'] as String?,
      entry = json['entry'] as String?,
      prizeStatus = json['prize_status'] as String?,
      dateCreated = json['date_created'] as String?,
      status = json['status'] as String?,
      points = (json['points'] as List?)?.cast<Map<String, dynamic>>(),
      topUsers = json['top_users'] as String?,
      participants = json['participants'] as String?;

  final String? id;
  final String? name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String? image;
  final String? entry;
  final String? prizeStatus;
  final String? dateCreated;
  final String? status;
  final List<Map<String, dynamic>>? points;
  final String? topUsers;
  final String? participants;
  bool? showDescription;
}

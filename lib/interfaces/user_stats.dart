class UserNameStat {
  String id;
  String userName;
  String? profilePicture;

  UserNameStat({required this.id, required this.userName, this.profilePicture});

  factory UserNameStat.fromJson(Map<String, dynamic> json) {
    return UserNameStat(
      id: json['id'] as String,
      userName: json['username'] as String,
      profilePicture: json['profilePicture'],
    );
  }
}

class SubscriberAge {
  double under18;
  double between18And25;
  double between26And40;
  double over40;

  SubscriberAge({required this.under18, required this.between18And25, required this.between26And40, required this.over40});

  factory SubscriberAge.fromJson(Map<String, dynamic> json) {
    return SubscriberAge(
      under18: json['under18'] as double,
      between18And25: json['between18And25'] as double,
      between26And40: json['between26And40'] as double,
      over40: json['over40'] as double,
    );
  }
}


class UserStats {
  final int subscriberLength;
  final List<UserNameStat> subscribersOrFollowers;
  final Map<String, double> gender;
  final SubscriberAge age;

  UserStats({
    required this.subscriberLength,
    required this.subscribersOrFollowers,
    required this.gender,
    required this.age
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      subscriberLength: json['subscriberLength'],
      subscribersOrFollowers: json['subscribersOrFollowers'] != null?
          (json['subscribersOrFollowers'] as List)
              .map((e) => UserNameStat.fromJson(e))
              .toList() : [],
      gender: Map<String, double>.from(json['gender']),
      age: SubscriberAge.fromJson(json['subscriberAge']),
    );
  }
}

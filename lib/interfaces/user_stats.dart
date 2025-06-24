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

class Gender {
  int autre;
  int femme;
  int homme;

  Gender({required this.autre, required this.femme, required this.homme});
}

class UserStats {
  final int subscriberLength;
  final List<UserNameStat> subscribers;
  final Map<String, double> gender;

  UserStats({
    required this.subscriberLength,
    required this.subscribers,
    required this.gender,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      subscriberLength: json['subscriberLength'],
      subscribers: json['subscribers'] != null?
          (json['subscribers'] as List)
              .map((e) => UserNameStat.fromJson(e))
              .toList() : [],
      gender: Map<String, double>.from(json['gender']),
    );
  }
}

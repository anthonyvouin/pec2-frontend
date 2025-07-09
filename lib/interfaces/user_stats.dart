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

class LastPost {
  String name;
  String pictureUrl;

  LastPost({required this.name, required this.pictureUrl});

  factory LastPost.fromJson(Map<String, dynamic> json) {
    return LastPost(
      name: json['name'] as String,
      pictureUrl: json['pictureUrl'],
    );
  }
}

class SubscriberAge {
  double under18;
  double between18And25;
  double between26And40;
  double over40;

  SubscriberAge({
    required this.under18,
    required this.between18And25,
    required this.between26And40,
    required this.over40,
  });

  factory SubscriberAge.fromJson(Map<String, dynamic> json) {
    double round(val) => double.parse(val.toStringAsFixed(2));
    return SubscriberAge(
      under18:  round(json['under18']),
      between18And25: round(json['between18And25']),
      between26And40: round(json['between26And40']),
      over40:  round(json['over40']),
    );
  }
}

class MostLiked {
  String name;
  String pictureUrl;
  String description;
  int likeCount;

  MostLiked({
    required this.name,
    required this.pictureUrl,
    required this.description,
    required this.likeCount,
  });

  factory MostLiked.fromJson(Map<String, dynamic> json) {
    return MostLiked(
      name: json['name'] as String,
      pictureUrl: json['pictureUrl'] as String,
      description: json['description'] as String,
      likeCount: json['likeCount'] as int,
    );
  }
}

class MostCommented {
  String name;
  String pictureUrl;
  String description;
  int commentCount;

  MostCommented({
    required this.name,
    required this.pictureUrl,
    required this.description,
    required this.commentCount,
  });

  factory MostCommented.fromJson(Map<String, dynamic> json) {
    return MostCommented(
      name: json['name'] as String,
      pictureUrl: json['pictureUrl'] as String,
      description: json['description'] as String,
      commentCount: json['commentCount'] as int,
    );
  }
}

class CreatorGeneralStats {
  final int subscriberLength;
  final List<UserNameStat> subscribersOrFollowers;
  final Map<String, double> gender;
  final SubscriberAge age;
  final MostLiked mostLiked;
  final MostCommented mostCommented;
  final List<LastPost> threeLastPost;

  CreatorGeneralStats({
    required this.subscriberLength,
    required this.subscribersOrFollowers,
    required this.gender,
    required this.age,
    required this.mostLiked,
    required this.mostCommented,
    required this.threeLastPost,
  });

  factory CreatorGeneralStats.fromJson(Map<String, dynamic> json) {
    return CreatorGeneralStats(
      subscriberLength: json['subscriberLength'],
      subscribersOrFollowers:
          json['subscribersOrFollowers'] != null
              ? (json['subscribersOrFollowers'] as List)
                  .map((e) => UserNameStat.fromJson(e))
                  .toList()
              : [],
      gender: Map<String, double>.from(json['gender']),
      age: SubscriberAge.fromJson(json['subscriberAge']),
      mostLiked: MostLiked.fromJson(json['mostLikedPost']),
      mostCommented: MostCommented.fromJson(json['mostCommentedPost']),
      threeLastPost:
      json['threeLastPost'] != null
          ? (json['threeLastPost'] as List)
          .map((e) => LastPost.fromJson(e))
          .toList()
          : [],
    );
  }
}

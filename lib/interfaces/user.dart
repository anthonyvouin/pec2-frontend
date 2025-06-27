class User {
  String? id;
  String email;
  String userName;
  String role;
  String bio;
  String profilePicture;
  DateTime? emailVerifiedAt;
  String firstName;
  String lastName;
  DateTime birthDayDate;
  String sexe;
  bool commentEnabled;
  bool messageEnabled;
  bool subscriptionEnabled;

  User({
    required this.email,
    required this.userName,
    required this.role,
    required this.bio,
    required this.profilePicture,
    required this.firstName,
    required this.lastName,
    required this.birthDayDate,
    required this.sexe,
    this.emailVerifiedAt,
    this.id,
    this.commentEnabled = true,
    this.messageEnabled = true,
    this.subscriptionEnabled = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      userName: json['userName'],
      role: json['role'],
      bio: json['bio'],
      profilePicture: json['profilePicture'] ?? "",
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDayDate: DateTime.parse(json["birthDayDate"]),
      sexe: json['sexe'],
      commentEnabled: json['commentsEnable'] ?? true,
      messageEnabled: json['messageEnable'] ?? true,
      subscriptionEnabled: json['subscriptionEnable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'userName': userName,
      'role': role,
      'bio': bio,
      'profilePicture': profilePicture,
      'firstName': firstName,
      'lastName': lastName,
      'birthDayDate': birthDayDate.toIso8601String(),
      'sexe': sexe,
      'commentsEnable': commentEnabled,
      'messageEnable': messageEnabled,
      'subscriptionEnable': subscriptionEnabled,
    };
  }
}

class PostCreatorUser {
  final String id;
  final String userName;
  final String profilePicture;

  PostCreatorUser({
    required this.id,
    required this.userName,
    this.profilePicture = "",
  });

  factory PostCreatorUser.fromJson(Map<String, dynamic> json) {
    return PostCreatorUser(
      id: json['id'],
      userName: json['userName'],
      profilePicture: json['profilePicture'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'userName': userName, 'profilePicture': profilePicture};
  }
}

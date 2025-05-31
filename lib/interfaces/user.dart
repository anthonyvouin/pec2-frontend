class User {
  String? id;
  String email;
  String userName;
  String role;
  String bio;
  String profilePicture;
  String? stripeCustomerId;
  DateTime? emailVerifiedAt;
  String firstName;
  String lastName;
  DateTime birthDayDate;
  String sexe;

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
    this.stripeCustomerId,
    this.emailVerifiedAt,
    this.id
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      userName: json['userName'],
      role: json['role'],
      bio: json['bio'],
      profilePicture: json['profilePicture'] ?? "",
      stripeCustomerId: json['stripeCustomerId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDayDate: DateTime.parse(json["birthDayDate"]),
      sexe: json['sexe'],
    );
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
    return {
      'id': id,
      'userName': userName,
      'profilePicture': profilePicture,
    };
  }
}
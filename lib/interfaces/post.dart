import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/interfaces/comment.dart';
import 'package:firstflutterapp/interfaces/user.dart';

class Post {
  final String id;
  final String name;
  final String pictureUrl;
  final bool isFree;
  final bool enable;
  final List<Category> categories;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final PostCreatorUser user;
  int likesCount;
  final int commentsCount;
  final int reportsCount;
  List<Comment> comments;
  final bool commentEnabled;
  
  Post({
    required this.id,
    required this.name,
    required this.pictureUrl,
    required this.user,
    this.isFree = false,
    this.enable = true,
    this.categories = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.comments = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.reportsCount = 0,
    this.commentEnabled = true, // Valeur par défaut à true
  });
  
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      name: json['name'],
      pictureUrl: json['pictureUrl'],
      isFree: json['isFree'] ?? false,
      enable: json['enable'] ?? true,
      user: PostCreatorUser.fromJson(json['user']),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((category) => Category.fromJson(category))
          .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => Comment.fromJson(comment))
          .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      reportsCount: json['reportsCount'] ?? 0,
      commentEnabled: json['commentEnabled'] ?? true, // Récupération depuis le JSON
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pictureUrl': pictureUrl,
      'isFree': isFree,
      'enable': enable,
      'user': user.toJson(),
      'categories': categories.map((category) => category.toJson()).toList(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'reportsCount': reportsCount,
      'commentEnabled': commentEnabled,
    };
  }
}
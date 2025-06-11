import 'dart:io';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/interfaces/pagination.dart';
import 'package:firstflutterapp/interfaces/paginated_response.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class PostsListingService {
  final ApiService _apiService = ApiService();
  Future<PaginatedResponse<Post>> loadPosts({int page = 1, int limit = 10}) async {
    final response = await _apiService.request(
      method: 'get',
      endpoint: '/posts?page=$page&limit=$limit',
      withAuth: false,
    );
   
    if (response.success) {
      return PaginatedResponse<Post>.fromJson(
        response.data,
        (post) => Post.fromJson(post),
      );
    }

    throw Exception('Échec du chargement des posts: ${response.error}');
  }
  Future<Post> loadPostById(String postId) async {
    final response = await _apiService.request(
      method: 'get',
      endpoint: '/posts/$postId',
      withAuth: false,
    );
   
    if (response.success) {
      return Post.fromJson(response.data);
    }

    throw Exception('Échec du chargement du post: ${response.error}');
  }

}
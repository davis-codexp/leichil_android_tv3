import '../models/home_content_model.dart';
import 'api_service.dart';

class ContentService {
  ContentService._();

  static Future<ApiResponse> getMovies() {
    return ApiService.get('/api/v1/app/contents/home/list?content-type=MOVIE');
  }

  static Future<ApiResponse> getSeries() {
    return ApiService.get('/api/v1/app/contents/home/list?content-type=SERIES');
  }

  static Future<ApiResponse> getContent(int contentId) {
    return ApiService.get('/api/v1/app/contents/$contentId');
  }

  static Future<ApiResponse> verifySubscription() {
    return ApiService.get('/api/v1/app/subscriptions/verify');
  }

  static Future<HomeContentResponse?> loadMoviesHome() async {
    return _parseHomeResponse(await getMovies());
  }

  static Future<HomeContentResponse?> loadSeriesHome() async {
    return _parseHomeResponse(await getSeries());
  }

  static HomeContentResponse? _parseHomeResponse(ApiResponse response) {
    if (response.statusCode != 200 ||
        response.data is! Map ||
        response.data['success'] != true) {
      return null;
    }

    final result = response.data['result'];

    if (result is! Map) {
      return null;
    }

    return HomeContentResponse.fromJson(Map<String, dynamic>.from(result));
  }
}

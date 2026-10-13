import '../../../../core/network/api_client.dart';

class SearchRemoteDataSource {
  final ApiClient _apiClient;

  SearchRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> searchGlobal(String query) async {
    return _apiClient.get('/v1/search', queryParameters: {'q': query});
  }
}

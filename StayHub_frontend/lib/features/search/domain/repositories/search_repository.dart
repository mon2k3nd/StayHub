import '../../data/models/search_result_model.dart';

abstract class SearchRepository {
  Future<GlobalSearchResponse> searchGlobal(String query);
}

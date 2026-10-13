import '../../data/datasources/search_remote_data_source.dart';
import '../../data/models/search_result_model.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remoteDataSource;

  SearchRepositoryImpl(this._remoteDataSource);

  @override
  Future<GlobalSearchResponse> searchGlobal(String query) async {
    final res = await _remoteDataSource.searchGlobal(query);
    return GlobalSearchResponse.fromJson(res);
  }
}

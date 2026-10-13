import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/branch_rule_model.dart';
import '../../../core/providers/core_providers.dart';

part 'branch_rule_provider.g.dart';

@riverpod
class BranchRuleNotifier extends _$BranchRuleNotifier {
  @override
  FutureOr<List<BranchRule>> build(int branchId) async {
    return _fetchRules(branchId);
  }

  Future<List<BranchRule>> _fetchRules(int branchId) async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/v1/branch-rules/branch/$branchId');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => BranchRule.fromJson(e)).toList();
    } else {
      throw Exception('L?i t?i n?i quy');
    }
  }

  Future<void> addRule(BranchRule rule) async {
    final dio = ref.read(dioProvider);
    final response = await dio.post('/v1/branch-rules', data: rule.toJson());
    if (response.statusCode == 200) {
      final newRule = BranchRule.fromJson(response.data);
      final previousState = await future;
      state = AsyncData([...previousState, newRule]);
    }
  }

  Future<void> updateRule(BranchRule rule) async {
    final dio = ref.read(dioProvider);
    final response = await dio.put(
      '/v1/branch-rules/${rule.id}',
      data: rule.toJson(),
    );
    if (response.statusCode == 200) {
      final updatedRule = BranchRule.fromJson(response.data);
      final previousState = await future;
      state = AsyncData(
        previousState
            .map((e) => e.id == updatedRule.id ? updatedRule : e)
            .toList(),
      );
    }
  }

  Future<void> deleteRule(int id) async {
    final dio = ref.read(dioProvider);
    final response = await dio.delete('/v1/branch-rules/$id');
    if (response.statusCode == 200) {
      final previousState = await future;
      state = AsyncData(previousState.where((e) => e.id != id).toList());
    }
  }
}

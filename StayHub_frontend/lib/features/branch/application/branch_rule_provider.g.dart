// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_rule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BranchRuleNotifier)
final branchRuleProvider = BranchRuleNotifierFamily._();

final class BranchRuleNotifierProvider
    extends $AsyncNotifierProvider<BranchRuleNotifier, List<BranchRule>> {
  BranchRuleNotifierProvider._({
    required BranchRuleNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'branchRuleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$branchRuleNotifierHash();

  @override
  String toString() {
    return r'branchRuleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BranchRuleNotifier create() => BranchRuleNotifier();

  @override
  bool operator ==(Object other) {
    return other is BranchRuleNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$branchRuleNotifierHash() =>
    r'10753b1be59760e20443fcde03cb8e4f63437c49';

final class BranchRuleNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BranchRuleNotifier,
          AsyncValue<List<BranchRule>>,
          List<BranchRule>,
          FutureOr<List<BranchRule>>,
          int
        > {
  BranchRuleNotifierFamily._()
    : super(
        retry: null,
        name: r'branchRuleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BranchRuleNotifierProvider call(int branchId) =>
      BranchRuleNotifierProvider._(argument: branchId, from: this);

  @override
  String toString() => r'branchRuleProvider';
}

abstract class _$BranchRuleNotifier extends $AsyncNotifier<List<BranchRule>> {
  late final _$args = ref.$arg as int;
  int get branchId => _$args;

  FutureOr<List<BranchRule>> build(int branchId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BranchRule>>, List<BranchRule>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BranchRule>>, List<BranchRule>>,
              AsyncValue<List<BranchRule>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

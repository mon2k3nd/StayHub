// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_group_chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BranchGroupChatState)
final branchGroupChatStateProvider = BranchGroupChatStateFamily._();

final class BranchGroupChatStateProvider
    extends
        $NotifierProvider<BranchGroupChatState, List<Map<String, dynamic>>> {
  BranchGroupChatStateProvider._({
    required BranchGroupChatStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'branchGroupChatStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$branchGroupChatStateHash();

  @override
  String toString() {
    return r'branchGroupChatStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BranchGroupChatState create() => BranchGroupChatState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Map<String, dynamic>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BranchGroupChatStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$branchGroupChatStateHash() =>
    r'2f2c3aaadd28d84e5f328a61fadfb8f82148a1e3';

final class BranchGroupChatStateFamily extends $Family
    with
        $ClassFamilyOverride<
          BranchGroupChatState,
          List<Map<String, dynamic>>,
          List<Map<String, dynamic>>,
          List<Map<String, dynamic>>,
          String
        > {
  BranchGroupChatStateFamily._()
    : super(
        retry: null,
        name: r'branchGroupChatStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BranchGroupChatStateProvider call(String branchId) =>
      BranchGroupChatStateProvider._(argument: branchId, from: this);

  @override
  String toString() => r'branchGroupChatStateProvider';
}

abstract class _$BranchGroupChatState
    extends $Notifier<List<Map<String, dynamic>>> {
  late final _$args = ref.$arg as String;
  String get branchId => _$args;

  List<Map<String, dynamic>> build(String branchId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<List<Map<String, dynamic>>, List<Map<String, dynamic>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<Map<String, dynamic>>,
                List<Map<String, dynamic>>
              >,
              List<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

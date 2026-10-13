// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DisputeChatNotifier)
final disputeChatProvider = DisputeChatNotifierFamily._();

final class DisputeChatNotifierProvider
    extends $NotifierProvider<DisputeChatNotifier, List<Map<String, dynamic>>> {
  DisputeChatNotifierProvider._({
    required DisputeChatNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'disputeChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$disputeChatNotifierHash();

  @override
  String toString() {
    return r'disputeChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DisputeChatNotifier create() => DisputeChatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Map<String, dynamic>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DisputeChatNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$disputeChatNotifierHash() =>
    r'59cbfc0078da7357bf7b5a6bbdba581fec7fe402';

final class DisputeChatNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DisputeChatNotifier,
          List<Map<String, dynamic>>,
          List<Map<String, dynamic>>,
          List<Map<String, dynamic>>,
          int
        > {
  DisputeChatNotifierFamily._()
    : super(
        retry: null,
        name: r'disputeChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DisputeChatNotifierProvider call(int billId) =>
      DisputeChatNotifierProvider._(argument: billId, from: this);

  @override
  String toString() => r'disputeChatProvider';
}

abstract class _$DisputeChatNotifier
    extends $Notifier<List<Map<String, dynamic>>> {
  late final _$args = ref.$arg as int;
  int get billId => _$args;

  List<Map<String, dynamic>> build(int billId);
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

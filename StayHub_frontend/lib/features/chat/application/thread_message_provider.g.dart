// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThreadMessageNotifier)
final threadMessageProvider = ThreadMessageNotifierFamily._();

final class ThreadMessageNotifierProvider
    extends $NotifierProvider<ThreadMessageNotifier, ThreadMessageState> {
  ThreadMessageNotifierProvider._({
    required ThreadMessageNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'threadMessageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$threadMessageNotifierHash();

  @override
  String toString() {
    return r'threadMessageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ThreadMessageNotifier create() => ThreadMessageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThreadMessageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThreadMessageState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ThreadMessageNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$threadMessageNotifierHash() =>
    r'559e4761c2a0d03a1447f6a13c7b6f8cf1cf3865';

final class ThreadMessageNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ThreadMessageNotifier,
          ThreadMessageState,
          ThreadMessageState,
          ThreadMessageState,
          int
        > {
  ThreadMessageNotifierFamily._()
    : super(
        retry: null,
        name: r'threadMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ThreadMessageNotifierProvider call(int threadId) =>
      ThreadMessageNotifierProvider._(argument: threadId, from: this);

  @override
  String toString() => r'threadMessageProvider';
}

abstract class _$ThreadMessageNotifier extends $Notifier<ThreadMessageState> {
  late final _$args = ref.$arg as int;
  int get threadId => _$args;

  ThreadMessageState build(int threadId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThreadMessageState, ThreadMessageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThreadMessageState, ThreadMessageState>,
              ThreadMessageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

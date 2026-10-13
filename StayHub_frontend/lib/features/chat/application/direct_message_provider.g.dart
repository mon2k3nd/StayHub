// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for direct messages between owner and tenant via SSE on /v1/messages/stream/{roomId}

@ProviderFor(DirectMessageNotifier)
final directMessageProvider = DirectMessageNotifierFamily._();

/// Provider for direct messages between owner and tenant via SSE on /v1/messages/stream/{roomId}
final class DirectMessageNotifierProvider
    extends $NotifierProvider<DirectMessageNotifier, DirectMessageState> {
  /// Provider for direct messages between owner and tenant via SSE on /v1/messages/stream/{roomId}
  DirectMessageNotifierProvider._({
    required DirectMessageNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'directMessageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$directMessageNotifierHash();

  @override
  String toString() {
    return r'directMessageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DirectMessageNotifier create() => DirectMessageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectMessageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectMessageState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DirectMessageNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$directMessageNotifierHash() =>
    r'4e296bce8d2336ab68a8296fc1c6309b2c9fecb4';

/// Provider for direct messages between owner and tenant via SSE on /v1/messages/stream/{roomId}

final class DirectMessageNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DirectMessageNotifier,
          DirectMessageState,
          DirectMessageState,
          DirectMessageState,
          int
        > {
  DirectMessageNotifierFamily._()
    : super(
        retry: null,
        name: r'directMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for direct messages between owner and tenant via SSE on /v1/messages/stream/{roomId}

  DirectMessageNotifierProvider call(int roomId) =>
      DirectMessageNotifierProvider._(argument: roomId, from: this);

  @override
  String toString() => r'directMessageProvider';
}

/// Provider for direct messages between owner and tenant via SSE on /v1/messages/stream/{roomId}

abstract class _$DirectMessageNotifier extends $Notifier<DirectMessageState> {
  late final _$args = ref.$arg as int;
  int get roomId => _$args;

  DirectMessageState build(int roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DirectMessageState, DirectMessageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DirectMessageState, DirectMessageState>,
              DirectMessageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

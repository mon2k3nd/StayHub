// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_room_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StaffRoomNotifier)
final staffRoomProvider = StaffRoomNotifierProvider._();

final class StaffRoomNotifierProvider
    extends $NotifierProvider<StaffRoomNotifier, StaffRoomState> {
  StaffRoomNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffRoomProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffRoomNotifierHash();

  @$internal
  @override
  StaffRoomNotifier create() => StaffRoomNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaffRoomState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaffRoomState>(value),
    );
  }
}

String _$staffRoomNotifierHash() => r'4c5d1a9c0d83e498f3cd59f7b8f70fd6b94b8f05';

abstract class _$StaffRoomNotifier extends $Notifier<StaffRoomState> {
  StaffRoomState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StaffRoomState, StaffRoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StaffRoomState, StaffRoomState>,
              StaffRoomState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

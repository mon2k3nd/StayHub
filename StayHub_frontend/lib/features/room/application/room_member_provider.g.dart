// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_member_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoomMemberNotifier)
final roomMemberProvider = RoomMemberNotifierFamily._();

final class RoomMemberNotifierProvider
    extends
        $AsyncNotifierProvider<RoomMemberNotifier, List<Map<String, dynamic>>> {
  RoomMemberNotifierProvider._({
    required RoomMemberNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'roomMemberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMemberNotifierHash();

  @override
  String toString() {
    return r'roomMemberProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RoomMemberNotifier create() => RoomMemberNotifier();

  @override
  bool operator ==(Object other) {
    return other is RoomMemberNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMemberNotifierHash() =>
    r'63b8c73253d74d63e57826704f35d2185fd62fe4';

final class RoomMemberNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RoomMemberNotifier,
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>,
          int
        > {
  RoomMemberNotifierFamily._()
    : super(
        retry: null,
        name: r'roomMemberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoomMemberNotifierProvider call(int roomId) =>
      RoomMemberNotifierProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomMemberProvider';
}

abstract class _$RoomMemberNotifier
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  late final _$args = ref.$arg as int;
  int get roomId => _$args;

  FutureOr<List<Map<String, dynamic>>> build(int roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(roomRemoteDataSource)
final roomRemoteDataSourceProvider = RoomRemoteDataSourceProvider._();

final class RoomRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          RoomRemoteDataSource,
          RoomRemoteDataSource,
          RoomRemoteDataSource
        >
    with $Provider<RoomRemoteDataSource> {
  RoomRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<RoomRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RoomRemoteDataSource create(Ref ref) {
    return roomRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomRemoteDataSource>(value),
    );
  }
}

String _$roomRemoteDataSourceHash() =>
    r'f6db3db4412921dfa94ec68e3d5d93ed6c04df79';

@ProviderFor(roomRepository)
final roomRepositoryProvider = RoomRepositoryProvider._();

final class RoomRepositoryProvider
    extends $FunctionalProvider<RoomRepository, RoomRepository, RoomRepository>
    with $Provider<RoomRepository> {
  RoomRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomRepositoryHash();

  @$internal
  @override
  $ProviderElement<RoomRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoomRepository create(Ref ref) {
    return roomRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomRepository>(value),
    );
  }
}

String _$roomRepositoryHash() => r'fb379645f1a87446a648dd5a103fd6f23008a7d5';

@ProviderFor(RoomNotifier)
final roomProvider = RoomNotifierProvider._();

final class RoomNotifierProvider
    extends $AsyncNotifierProvider<RoomNotifier, List<RoomModel>> {
  RoomNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomNotifierHash();

  @$internal
  @override
  RoomNotifier create() => RoomNotifier();
}

String _$roomNotifierHash() => r'b54aabbe1b7d457885693474ff8a5b055b05049b';

abstract class _$RoomNotifier extends $AsyncNotifier<List<RoomModel>> {
  FutureOr<List<RoomModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<RoomModel>>, List<RoomModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RoomModel>>, List<RoomModel>>,
              AsyncValue<List<RoomModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(allOwnerRooms)
final allOwnerRoomsProvider = AllOwnerRoomsProvider._();

final class AllOwnerRoomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RoomModel>>,
          List<RoomModel>,
          FutureOr<List<RoomModel>>
        >
    with $FutureModifier<List<RoomModel>>, $FutureProvider<List<RoomModel>> {
  AllOwnerRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allOwnerRoomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allOwnerRoomsHash();

  @$internal
  @override
  $FutureProviderElement<List<RoomModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RoomModel>> create(Ref ref) {
    return allOwnerRooms(ref);
  }
}

String _$allOwnerRoomsHash() => r'640ad3a70f85e87a387ec8766283c110e3e15728';

@ProviderFor(RoommateNotifier)
final roommateProvider = RoommateNotifierFamily._();

final class RoommateNotifierProvider
    extends $AsyncNotifierProvider<RoommateNotifier, List<RoommateModel>> {
  RoommateNotifierProvider._({
    required RoommateNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'roommateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roommateNotifierHash();

  @override
  String toString() {
    return r'roommateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RoommateNotifier create() => RoommateNotifier();

  @override
  bool operator ==(Object other) {
    return other is RoommateNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roommateNotifierHash() => r'c4c8ced0d167b361557c842a09db0d367da76140';

final class RoommateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RoommateNotifier,
          AsyncValue<List<RoommateModel>>,
          List<RoommateModel>,
          FutureOr<List<RoommateModel>>,
          int
        > {
  RoommateNotifierFamily._()
    : super(
        retry: null,
        name: r'roommateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoommateNotifierProvider call(int contractId) =>
      RoommateNotifierProvider._(argument: contractId, from: this);

  @override
  String toString() => r'roommateProvider';
}

abstract class _$RoommateNotifier extends $AsyncNotifier<List<RoommateModel>> {
  late final _$args = ref.$arg as int;
  int get contractId => _$args;

  FutureOr<List<RoommateModel>> build(int contractId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<RoommateModel>>, List<RoommateModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RoommateModel>>, List<RoommateModel>>,
              AsyncValue<List<RoommateModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

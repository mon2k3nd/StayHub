// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_device_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(smartDeviceRepository)
final smartDeviceRepositoryProvider = SmartDeviceRepositoryProvider._();

final class SmartDeviceRepositoryProvider
    extends
        $FunctionalProvider<
          SmartDeviceRepository,
          SmartDeviceRepository,
          SmartDeviceRepository
        >
    with $Provider<SmartDeviceRepository> {
  SmartDeviceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartDeviceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartDeviceRepositoryHash();

  @$internal
  @override
  $ProviderElement<SmartDeviceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SmartDeviceRepository create(Ref ref) {
    return smartDeviceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartDeviceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartDeviceRepository>(value),
    );
  }
}

String _$smartDeviceRepositoryHash() =>
    r'b2b481d2f31845013294f28226452f5afd5222a5';

@ProviderFor(SmartDevice)
final smartDeviceProvider = SmartDeviceFamily._();

final class SmartDeviceProvider
    extends $AsyncNotifierProvider<SmartDevice, List<SmartDeviceModel>> {
  SmartDeviceProvider._({
    required SmartDeviceFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'smartDeviceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$smartDeviceHash();

  @override
  String toString() {
    return r'smartDeviceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SmartDevice create() => SmartDevice();

  @override
  bool operator ==(Object other) {
    return other is SmartDeviceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$smartDeviceHash() => r'49fc3f0363f31af4297d99b1b8e669eca46b040e';

final class SmartDeviceFamily extends $Family
    with
        $ClassFamilyOverride<
          SmartDevice,
          AsyncValue<List<SmartDeviceModel>>,
          List<SmartDeviceModel>,
          FutureOr<List<SmartDeviceModel>>,
          int
        > {
  SmartDeviceFamily._()
    : super(
        retry: null,
        name: r'smartDeviceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SmartDeviceProvider call(int roomId) =>
      SmartDeviceProvider._(argument: roomId, from: this);

  @override
  String toString() => r'smartDeviceProvider';
}

abstract class _$SmartDevice extends $AsyncNotifier<List<SmartDeviceModel>> {
  late final _$args = ref.$arg as int;
  int get roomId => _$args;

  FutureOr<List<SmartDeviceModel>> build(int roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<SmartDeviceModel>>, List<SmartDeviceModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SmartDeviceModel>>,
                List<SmartDeviceModel>
              >,
              AsyncValue<List<SmartDeviceModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

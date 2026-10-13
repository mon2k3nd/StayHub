// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_addon_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(availableAddons)
final availableAddonsProvider = AvailableAddonsFamily._();

final class AvailableAddonsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AddonModel>>,
          List<AddonModel>,
          FutureOr<List<AddonModel>>
        >
    with $FutureModifier<List<AddonModel>>, $FutureProvider<List<AddonModel>> {
  AvailableAddonsProvider._({
    required AvailableAddonsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'availableAddonsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availableAddonsHash();

  @override
  String toString() {
    return r'availableAddonsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AddonModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AddonModel>> create(Ref ref) {
    final argument = this.argument as int;
    return availableAddons(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableAddonsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availableAddonsHash() => r'7aa79a55cb99339265d9f5d3cbd69d930d0d0974';

final class AvailableAddonsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AddonModel>>, int> {
  AvailableAddonsFamily._()
    : super(
        retry: null,
        name: r'availableAddonsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AvailableAddonsProvider call(int roomId) =>
      AvailableAddonsProvider._(argument: roomId, from: this);

  @override
  String toString() => r'availableAddonsProvider';
}

@ProviderFor(myAddonRequests)
final myAddonRequestsProvider = MyAddonRequestsProvider._();

final class MyAddonRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TenantAddonRequestModel>>,
          List<TenantAddonRequestModel>,
          FutureOr<List<TenantAddonRequestModel>>
        >
    with
        $FutureModifier<List<TenantAddonRequestModel>>,
        $FutureProvider<List<TenantAddonRequestModel>> {
  MyAddonRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myAddonRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myAddonRequestsHash();

  @$internal
  @override
  $FutureProviderElement<List<TenantAddonRequestModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TenantAddonRequestModel>> create(Ref ref) {
    return myAddonRequests(ref);
  }
}

String _$myAddonRequestsHash() => r'400e03b4c212bc7a53414ebf907c29aa7a623540';

@ProviderFor(TenantAddonNotifier)
final tenantAddonProvider = TenantAddonNotifierProvider._();

final class TenantAddonNotifierProvider
    extends $NotifierProvider<TenantAddonNotifier, AsyncValue<void>> {
  TenantAddonNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantAddonProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantAddonNotifierHash();

  @$internal
  @override
  TenantAddonNotifier create() => TenantAddonNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$tenantAddonNotifierHash() =>
    r'279b25b009ea1867e3e1aa9a9e1c4c0205851e92';

abstract class _$TenantAddonNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

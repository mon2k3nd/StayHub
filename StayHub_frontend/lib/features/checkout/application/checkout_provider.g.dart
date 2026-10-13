// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkoutRepository)
final checkoutRepositoryProvider = CheckoutRepositoryProvider._();

final class CheckoutRepositoryProvider
    extends
        $FunctionalProvider<
          CheckoutRepository,
          CheckoutRepository,
          CheckoutRepository
        >
    with $Provider<CheckoutRepository> {
  CheckoutRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutRepositoryHash();

  @$internal
  @override
  $ProviderElement<CheckoutRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckoutRepository create(Ref ref) {
    return checkoutRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutRepository>(value),
    );
  }
}

String _$checkoutRepositoryHash() =>
    r'da209a91add65840b7d7ee989d07ffcb9e4fbec8';

@ProviderFor(TenantCheckoutRequests)
final tenantCheckoutRequestsProvider = TenantCheckoutRequestsProvider._();

final class TenantCheckoutRequestsProvider
    extends
        $AsyncNotifierProvider<
          TenantCheckoutRequests,
          List<CheckoutRequestModel>
        > {
  TenantCheckoutRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantCheckoutRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantCheckoutRequestsHash();

  @$internal
  @override
  TenantCheckoutRequests create() => TenantCheckoutRequests();
}

String _$tenantCheckoutRequestsHash() =>
    r'1e3d6c061fa95fb0b290c1842094e1bfb1a27728';

abstract class _$TenantCheckoutRequests
    extends $AsyncNotifier<List<CheckoutRequestModel>> {
  FutureOr<List<CheckoutRequestModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<CheckoutRequestModel>>,
              List<CheckoutRequestModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CheckoutRequestModel>>,
                List<CheckoutRequestModel>
              >,
              AsyncValue<List<CheckoutRequestModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(OwnerCheckoutRequests)
final ownerCheckoutRequestsProvider = OwnerCheckoutRequestsProvider._();

final class OwnerCheckoutRequestsProvider
    extends
        $AsyncNotifierProvider<
          OwnerCheckoutRequests,
          List<CheckoutRequestModel>
        > {
  OwnerCheckoutRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerCheckoutRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerCheckoutRequestsHash();

  @$internal
  @override
  OwnerCheckoutRequests create() => OwnerCheckoutRequests();
}

String _$ownerCheckoutRequestsHash() =>
    r'0c9891a6660dd90fd791a2a98e3ddf77eb50af8a';

abstract class _$OwnerCheckoutRequests
    extends $AsyncNotifier<List<CheckoutRequestModel>> {
  FutureOr<List<CheckoutRequestModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<CheckoutRequestModel>>,
              List<CheckoutRequestModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CheckoutRequestModel>>,
                List<CheckoutRequestModel>
              >,
              AsyncValue<List<CheckoutRequestModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

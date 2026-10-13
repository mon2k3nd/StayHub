// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_checkout_request_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TenantCheckoutRequestNotifier)
final tenantCheckoutRequestProvider = TenantCheckoutRequestNotifierFamily._();

final class TenantCheckoutRequestNotifierProvider
    extends
        $NotifierProvider<TenantCheckoutRequestNotifier, CheckoutRequestState> {
  TenantCheckoutRequestNotifierProvider._({
    required TenantCheckoutRequestNotifierFamily super.from,
    required (ContractModel, CheckoutRequestModel?) super.argument,
  }) : super(
         retry: null,
         name: r'tenantCheckoutRequestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tenantCheckoutRequestNotifierHash();

  @override
  String toString() {
    return r'tenantCheckoutRequestProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TenantCheckoutRequestNotifier create() => TenantCheckoutRequestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutRequestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutRequestState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TenantCheckoutRequestNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tenantCheckoutRequestNotifierHash() =>
    r'555e4868e6ded1ff28b17c6f035b47d18e92025c';

final class TenantCheckoutRequestNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TenantCheckoutRequestNotifier,
          CheckoutRequestState,
          CheckoutRequestState,
          CheckoutRequestState,
          (ContractModel, CheckoutRequestModel?)
        > {
  TenantCheckoutRequestNotifierFamily._()
    : super(
        retry: null,
        name: r'tenantCheckoutRequestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TenantCheckoutRequestNotifierProvider call(
    ContractModel contract,
    CheckoutRequestModel? previousRequest,
  ) => TenantCheckoutRequestNotifierProvider._(
    argument: (contract, previousRequest),
    from: this,
  );

  @override
  String toString() => r'tenantCheckoutRequestProvider';
}

abstract class _$TenantCheckoutRequestNotifier
    extends $Notifier<CheckoutRequestState> {
  late final _$args = ref.$arg as (ContractModel, CheckoutRequestModel?);
  ContractModel get contract => _$args.$1;
  CheckoutRequestModel? get previousRequest => _$args.$2;

  CheckoutRequestState build(
    ContractModel contract,
    CheckoutRequestModel? previousRequest,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CheckoutRequestState, CheckoutRequestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheckoutRequestState, CheckoutRequestState>,
              CheckoutRequestState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

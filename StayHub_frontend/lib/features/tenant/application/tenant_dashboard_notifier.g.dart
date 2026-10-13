// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_dashboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(unpaidBills)
final unpaidBillsProvider = UnpaidBillsProvider._();

final class UnpaidBillsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<dynamic>>,
          List<dynamic>,
          FutureOr<List<dynamic>>
        >
    with $FutureModifier<List<dynamic>>, $FutureProvider<List<dynamic>> {
  UnpaidBillsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unpaidBillsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unpaidBillsHash();

  @$internal
  @override
  $FutureProviderElement<List<dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<dynamic>> create(Ref ref) {
    return unpaidBills(ref);
  }
}

String _$unpaidBillsHash() => r'b0a8fb4b9ebcf0b73dfb79f36edb3f7a1f6e1a1a';

@ProviderFor(TenantDashboardNotifier)
final tenantDashboardProvider = TenantDashboardNotifierProvider._();

final class TenantDashboardNotifierProvider
    extends $NotifierProvider<TenantDashboardNotifier, TenantDashboardState> {
  TenantDashboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantDashboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantDashboardNotifierHash();

  @$internal
  @override
  TenantDashboardNotifier create() => TenantDashboardNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TenantDashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TenantDashboardState>(value),
    );
  }
}

String _$tenantDashboardNotifierHash() =>
    r'98ae4b9476a2af441a79570a856198720855c32d';

abstract class _$TenantDashboardNotifier
    extends $Notifier<TenantDashboardState> {
  TenantDashboardState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TenantDashboardState, TenantDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TenantDashboardState, TenantDashboardState>,
              TenantDashboardState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

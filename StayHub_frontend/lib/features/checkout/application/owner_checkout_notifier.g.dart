// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_checkout_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OwnerCheckoutNotifier)
final ownerCheckoutProvider = OwnerCheckoutNotifierProvider._();

final class OwnerCheckoutNotifierProvider
    extends $NotifierProvider<OwnerCheckoutNotifier, OwnerCheckoutState> {
  OwnerCheckoutNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerCheckoutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerCheckoutNotifierHash();

  @$internal
  @override
  OwnerCheckoutNotifier create() => OwnerCheckoutNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OwnerCheckoutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OwnerCheckoutState>(value),
    );
  }
}

String _$ownerCheckoutNotifierHash() =>
    r'9b862507a055b2ebe25b6b5f11a76b87be8fcd8b';

abstract class _$OwnerCheckoutNotifier extends $Notifier<OwnerCheckoutState> {
  OwnerCheckoutState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OwnerCheckoutState, OwnerCheckoutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OwnerCheckoutState, OwnerCheckoutState>,
              OwnerCheckoutState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

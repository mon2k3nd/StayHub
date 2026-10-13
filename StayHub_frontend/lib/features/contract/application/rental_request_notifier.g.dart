// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental_request_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RentalRequestNotifier)
final rentalRequestProvider = RentalRequestNotifierProvider._();

final class RentalRequestNotifierProvider
    extends $NotifierProvider<RentalRequestNotifier, RentalRequestState> {
  RentalRequestNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rentalRequestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rentalRequestNotifierHash();

  @$internal
  @override
  RentalRequestNotifier create() => RentalRequestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RentalRequestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RentalRequestState>(value),
    );
  }
}

String _$rentalRequestNotifierHash() =>
    r'da196bc29a42631b107aeafabf3b781e54377ea1';

abstract class _$RentalRequestNotifier extends $Notifier<RentalRequestState> {
  RentalRequestState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RentalRequestState, RentalRequestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RentalRequestState, RentalRequestState>,
              RentalRequestState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

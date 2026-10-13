// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'electronic_contract_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ElectronicContractNotifier)
final electronicContractProvider = ElectronicContractNotifierProvider._();

final class ElectronicContractNotifierProvider
    extends
        $NotifierProvider<ElectronicContractNotifier, ElectronicContractState> {
  ElectronicContractNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'electronicContractProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$electronicContractNotifierHash();

  @$internal
  @override
  ElectronicContractNotifier create() => ElectronicContractNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ElectronicContractState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ElectronicContractState>(value),
    );
  }
}

String _$electronicContractNotifierHash() =>
    r'81499dc1a56fa15221d53b7e81f3e667062ce9f4';

abstract class _$ElectronicContractNotifier
    extends $Notifier<ElectronicContractState> {
  ElectronicContractState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ElectronicContractState, ElectronicContractState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ElectronicContractState, ElectronicContractState>,
              ElectronicContractState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

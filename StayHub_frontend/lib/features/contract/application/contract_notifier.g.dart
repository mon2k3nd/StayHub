// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contractRemoteDataSource)
final contractRemoteDataSourceProvider = ContractRemoteDataSourceProvider._();

final class ContractRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ContractRemoteDataSource,
          ContractRemoteDataSource,
          ContractRemoteDataSource
        >
    with $Provider<ContractRemoteDataSource> {
  ContractRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contractRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contractRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ContractRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContractRemoteDataSource create(Ref ref) {
    return contractRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContractRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContractRemoteDataSource>(value),
    );
  }
}

String _$contractRemoteDataSourceHash() =>
    r'e2bb8b8369cd6229598a832a4ad195b9c3eb9732';

@ProviderFor(contractRepository)
final contractRepositoryProvider = ContractRepositoryProvider._();

final class ContractRepositoryProvider
    extends
        $FunctionalProvider<
          ContractRepository,
          ContractRepository,
          ContractRepository
        >
    with $Provider<ContractRepository> {
  ContractRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contractRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contractRepositoryHash();

  @$internal
  @override
  $ProviderElement<ContractRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContractRepository create(Ref ref) {
    return contractRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContractRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContractRepository>(value),
    );
  }
}

String _$contractRepositoryHash() =>
    r'2e4f3aea1aeac59af1bdec8b9a5a157d7ca98db4';

@ProviderFor(ContractNotifier)
final contractProvider = ContractNotifierProvider._();

final class ContractNotifierProvider
    extends $AsyncNotifierProvider<ContractNotifier, List<ContractModel>> {
  ContractNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contractProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contractNotifierHash();

  @$internal
  @override
  ContractNotifier create() => ContractNotifier();
}

String _$contractNotifierHash() => r'65a60100c047bccfe7d20ebf59df7509853db3cf';

abstract class _$ContractNotifier extends $AsyncNotifier<List<ContractModel>> {
  FutureOr<List<ContractModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ContractModel>>, List<ContractModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ContractModel>>, List<ContractModel>>,
              AsyncValue<List<ContractModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

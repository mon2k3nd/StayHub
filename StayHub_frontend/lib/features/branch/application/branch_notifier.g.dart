// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(branchRemoteDataSource)
final branchRemoteDataSourceProvider = BranchRemoteDataSourceProvider._();

final class BranchRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          BranchRemoteDataSource,
          BranchRemoteDataSource,
          BranchRemoteDataSource
        >
    with $Provider<BranchRemoteDataSource> {
  BranchRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<BranchRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BranchRemoteDataSource create(Ref ref) {
    return branchRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BranchRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BranchRemoteDataSource>(value),
    );
  }
}

String _$branchRemoteDataSourceHash() =>
    r'07b5d0ec5554d56fa002834bc08621d3b968c00b';

@ProviderFor(branchRepository)
final branchRepositoryProvider = BranchRepositoryProvider._();

final class BranchRepositoryProvider
    extends
        $FunctionalProvider<
          BranchRepository,
          BranchRepository,
          BranchRepository
        >
    with $Provider<BranchRepository> {
  BranchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchRepositoryHash();

  @$internal
  @override
  $ProviderElement<BranchRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BranchRepository create(Ref ref) {
    return branchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BranchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BranchRepository>(value),
    );
  }
}

String _$branchRepositoryHash() => r'7a13203d929089c92b0dce540c05b9d281b3b927';

@ProviderFor(BranchNotifier)
final branchProvider = BranchNotifierProvider._();

final class BranchNotifierProvider
    extends $AsyncNotifierProvider<BranchNotifier, List<BranchModel>> {
  BranchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchNotifierHash();

  @$internal
  @override
  BranchNotifier create() => BranchNotifier();
}

String _$branchNotifierHash() => r'8b11d407f733364a037bbc688e1bab331c22a602';

abstract class _$BranchNotifier extends $AsyncNotifier<List<BranchModel>> {
  FutureOr<List<BranchModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BranchModel>>, List<BranchModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BranchModel>>, List<BranchModel>>,
              AsyncValue<List<BranchModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

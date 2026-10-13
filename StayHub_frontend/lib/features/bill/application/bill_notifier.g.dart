// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(billRemoteDataSource)
final billRemoteDataSourceProvider = BillRemoteDataSourceProvider._();

final class BillRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          BillRemoteDataSource,
          BillRemoteDataSource,
          BillRemoteDataSource
        >
    with $Provider<BillRemoteDataSource> {
  BillRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<BillRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BillRemoteDataSource create(Ref ref) {
    return billRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillRemoteDataSource>(value),
    );
  }
}

String _$billRemoteDataSourceHash() =>
    r'02eff0440164a1403d2315c5c4750368caafd86f';

@ProviderFor(billRepository)
final billRepositoryProvider = BillRepositoryProvider._();

final class BillRepositoryProvider
    extends $FunctionalProvider<BillRepository, BillRepository, BillRepository>
    with $Provider<BillRepository> {
  BillRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BillRepository create(Ref ref) {
    return billRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillRepository>(value),
    );
  }
}

String _$billRepositoryHash() => r'00534266f7b7c8f4ef4bb315462890b96a3c0122';

@ProviderFor(BillNotifier)
final billProvider = BillNotifierProvider._();

final class BillNotifierProvider
    extends $AsyncNotifierProvider<BillNotifier, List<BillModel>> {
  BillNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billNotifierHash();

  @$internal
  @override
  BillNotifier create() => BillNotifier();
}

String _$billNotifierHash() => r'672cefa641897bea0b84cdd4fed1e95b599dd2ff';

abstract class _$BillNotifier extends $AsyncNotifier<List<BillModel>> {
  FutureOr<List<BillModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<BillModel>>, List<BillModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BillModel>>, List<BillModel>>,
              AsyncValue<List<BillModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

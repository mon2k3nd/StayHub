// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_kyc_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminKycNotifier)
final adminKycProvider = AdminKycNotifierProvider._();

final class AdminKycNotifierProvider
    extends $AsyncNotifierProvider<AdminKycNotifier, List<dynamic>> {
  AdminKycNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminKycProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminKycNotifierHash();

  @$internal
  @override
  AdminKycNotifier create() => AdminKycNotifier();
}

String _$adminKycNotifierHash() => r'1d626eb527e5701ebaa547fd3bbc727ae13ee595';

abstract class _$AdminKycNotifier extends $AsyncNotifier<List<dynamic>> {
  FutureOr<List<dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<dynamic>>, List<dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<dynamic>>, List<dynamic>>,
              AsyncValue<List<dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

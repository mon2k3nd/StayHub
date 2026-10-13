// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DashboardStats)
final dashboardStatsProvider = DashboardStatsFamily._();

final class DashboardStatsProvider
    extends $AsyncNotifierProvider<DashboardStats, Map<String, dynamic>> {
  DashboardStatsProvider._({
    required DashboardStatsFamily super.from,
    required ({int? month, int? year}) super.argument,
  }) : super(
         retry: null,
         name: r'dashboardStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dashboardStatsHash();

  @override
  String toString() {
    return r'dashboardStatsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DashboardStats create() => DashboardStats();

  @override
  bool operator ==(Object other) {
    return other is DashboardStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dashboardStatsHash() => r'5157882eedeea92bf7105e2e87c0c821d8bb30de';

final class DashboardStatsFamily extends $Family
    with
        $ClassFamilyOverride<
          DashboardStats,
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>,
          ({int? month, int? year})
        > {
  DashboardStatsFamily._()
    : super(
        retry: null,
        name: r'dashboardStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DashboardStatsProvider call({int? month, int? year}) =>
      DashboardStatsProvider._(
        argument: (month: month, year: year),
        from: this,
      );

  @override
  String toString() => r'dashboardStatsProvider';
}

abstract class _$DashboardStats extends $AsyncNotifier<Map<String, dynamic>> {
  late final _$args = ref.$arg as ({int? month, int? year});
  int? get month => _$args.month;
  int? get year => _$args.year;

  FutureOr<Map<String, dynamic>> build({int? month, int? year});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, dynamic>>, Map<String, dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>>,
                Map<String, dynamic>
              >,
              AsyncValue<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(month: _$args.month, year: _$args.year),
    );
  }
}

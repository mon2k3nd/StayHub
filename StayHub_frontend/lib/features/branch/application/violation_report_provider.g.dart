// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'violation_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ViolationReportNotifier)
final violationReportProvider = ViolationReportNotifierFamily._();

final class ViolationReportNotifierProvider
    extends
        $AsyncNotifierProvider<ViolationReportNotifier, List<ViolationReport>> {
  ViolationReportNotifierProvider._({
    required ViolationReportNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'violationReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$violationReportNotifierHash();

  @override
  String toString() {
    return r'violationReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ViolationReportNotifier create() => ViolationReportNotifier();

  @override
  bool operator ==(Object other) {
    return other is ViolationReportNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$violationReportNotifierHash() =>
    r'8b00d1244c8340039c378395eae6fa65cef30b78';

final class ViolationReportNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ViolationReportNotifier,
          AsyncValue<List<ViolationReport>>,
          List<ViolationReport>,
          FutureOr<List<ViolationReport>>,
          int
        > {
  ViolationReportNotifierFamily._()
    : super(
        retry: null,
        name: r'violationReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ViolationReportNotifierProvider call(int branchId) =>
      ViolationReportNotifierProvider._(argument: branchId, from: this);

  @override
  String toString() => r'violationReportProvider';
}

abstract class _$ViolationReportNotifier
    extends $AsyncNotifier<List<ViolationReport>> {
  late final _$args = ref.$arg as int;
  int get branchId => _$args;

  FutureOr<List<ViolationReport>> build(int branchId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ViolationReport>>, List<ViolationReport>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ViolationReport>>,
                List<ViolationReport>
              >,
              AsyncValue<List<ViolationReport>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

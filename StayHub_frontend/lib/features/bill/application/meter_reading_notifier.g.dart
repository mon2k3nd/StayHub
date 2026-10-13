// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meter_reading_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MeterReadingNotifier)
final meterReadingProvider = MeterReadingNotifierFamily._();

final class MeterReadingNotifierProvider
    extends
        $AsyncNotifierProvider<MeterReadingNotifier, List<MeterReadingModel>> {
  MeterReadingNotifierProvider._({
    required MeterReadingNotifierFamily super.from,
    required (int, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'meterReadingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$meterReadingNotifierHash();

  @override
  String toString() {
    return r'meterReadingProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  MeterReadingNotifier create() => MeterReadingNotifier();

  @override
  bool operator ==(Object other) {
    return other is MeterReadingNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$meterReadingNotifierHash() =>
    r'770adf69de76fadd80ebef5ee6540eb60cb5db13';

final class MeterReadingNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MeterReadingNotifier,
          AsyncValue<List<MeterReadingModel>>,
          List<MeterReadingModel>,
          FutureOr<List<MeterReadingModel>>,
          (int, int, int)
        > {
  MeterReadingNotifierFamily._()
    : super(
        retry: null,
        name: r'meterReadingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MeterReadingNotifierProvider call(int branchId, int month, int year) =>
      MeterReadingNotifierProvider._(
        argument: (branchId, month, year),
        from: this,
      );

  @override
  String toString() => r'meterReadingProvider';
}

abstract class _$MeterReadingNotifier
    extends $AsyncNotifier<List<MeterReadingModel>> {
  late final _$args = ref.$arg as (int, int, int);
  int get branchId => _$args.$1;
  int get month => _$args.$2;
  int get year => _$args.$3;

  FutureOr<List<MeterReadingModel>> build(int branchId, int month, int year);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<MeterReadingModel>>,
              List<MeterReadingModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MeterReadingModel>>,
                List<MeterReadingModel>
              >,
              AsyncValue<List<MeterReadingModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_assignment_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StaffAssignmentNotifier)
final staffAssignmentProvider = StaffAssignmentNotifierProvider._();

final class StaffAssignmentNotifierProvider
    extends $NotifierProvider<StaffAssignmentNotifier, StaffAssignmentState> {
  StaffAssignmentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffAssignmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffAssignmentNotifierHash();

  @$internal
  @override
  StaffAssignmentNotifier create() => StaffAssignmentNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaffAssignmentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaffAssignmentState>(value),
    );
  }
}

String _$staffAssignmentNotifierHash() =>
    r'065558a847857ed659d42a57a1653769e9592aed';

abstract class _$StaffAssignmentNotifier
    extends $Notifier<StaffAssignmentState> {
  StaffAssignmentState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StaffAssignmentState, StaffAssignmentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StaffAssignmentState, StaffAssignmentState>,
              StaffAssignmentState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

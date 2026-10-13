// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unread_notifications_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UnreadNotificationsCountNotifier)
final unreadNotificationsCountProvider =
    UnreadNotificationsCountNotifierProvider._();

final class UnreadNotificationsCountNotifierProvider
    extends $AsyncNotifierProvider<UnreadNotificationsCountNotifier, int> {
  UnreadNotificationsCountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationsCountNotifierHash();

  @$internal
  @override
  UnreadNotificationsCountNotifier create() =>
      UnreadNotificationsCountNotifier();
}

String _$unreadNotificationsCountNotifierHash() =>
    r'f4916d16630f139deaae8ce09fbf9a629994dc4e';

abstract class _$UnreadNotificationsCountNotifier extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

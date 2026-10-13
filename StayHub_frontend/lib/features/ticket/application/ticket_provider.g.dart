// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketRepository)
final ticketRepositoryProvider = TicketRepositoryProvider._();

final class TicketRepositoryProvider
    extends
        $FunctionalProvider<
          TicketRepository,
          TicketRepository,
          TicketRepository
        >
    with $Provider<TicketRepository> {
  TicketRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketRepositoryHash();

  @$internal
  @override
  $ProviderElement<TicketRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TicketRepository create(Ref ref) {
    return ticketRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketRepository>(value),
    );
  }
}

String _$ticketRepositoryHash() => r'eaf9aeddb7d8eef6e03fab4885d77f3f3415f551';

@ProviderFor(TicketNotifier)
final ticketProvider = TicketNotifierProvider._();

final class TicketNotifierProvider
    extends $AsyncNotifierProvider<TicketNotifier, List<TicketModel>> {
  TicketNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketNotifierHash();

  @$internal
  @override
  TicketNotifier create() => TicketNotifier();
}

String _$ticketNotifierHash() => r'0fa7957cb2f0e9dc5a96f85a46847edb2619b7f8';

abstract class _$TicketNotifier extends $AsyncNotifier<List<TicketModel>> {
  FutureOr<List<TicketModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TicketModel>>, List<TicketModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TicketModel>>, List<TicketModel>>,
              AsyncValue<List<TicketModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

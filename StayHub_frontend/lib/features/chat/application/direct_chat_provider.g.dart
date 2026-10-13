// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(directChatRepository)
final directChatRepositoryProvider = DirectChatRepositoryProvider._();

final class DirectChatRepositoryProvider
    extends
        $FunctionalProvider<
          DirectChatRepository,
          DirectChatRepository,
          DirectChatRepository
        >
    with $Provider<DirectChatRepository> {
  DirectChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directChatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directChatRepositoryHash();

  @$internal
  @override
  $ProviderElement<DirectChatRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DirectChatRepository create(Ref ref) {
    return directChatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectChatRepository>(value),
    );
  }
}

String _$directChatRepositoryHash() =>
    r'9b8a5d5518bbefa996048999b5ccc535522e5f72';

@ProviderFor(DirectChat)
final directChatProvider = DirectChatFamily._();

final class DirectChatProvider
    extends $AsyncNotifierProvider<DirectChat, List<DirectChatMessageModel>> {
  DirectChatProvider._({
    required DirectChatFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'directChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$directChatHash();

  @override
  String toString() {
    return r'directChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DirectChat create() => DirectChat();

  @override
  bool operator ==(Object other) {
    return other is DirectChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$directChatHash() => r'7087007270c886807f877cdb4e9cdfb7ccc406ce';

final class DirectChatFamily extends $Family
    with
        $ClassFamilyOverride<
          DirectChat,
          AsyncValue<List<DirectChatMessageModel>>,
          List<DirectChatMessageModel>,
          FutureOr<List<DirectChatMessageModel>>,
          int
        > {
  DirectChatFamily._()
    : super(
        retry: null,
        name: r'directChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DirectChatProvider call(int partnerId) =>
      DirectChatProvider._(argument: partnerId, from: this);

  @override
  String toString() => r'directChatProvider';
}

abstract class _$DirectChat
    extends $AsyncNotifier<List<DirectChatMessageModel>> {
  late final _$args = ref.$arg as int;
  int get partnerId => _$args;

  FutureOr<List<DirectChatMessageModel>> build(int partnerId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<DirectChatMessageModel>>,
              List<DirectChatMessageModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<DirectChatMessageModel>>,
                List<DirectChatMessageModel>
              >,
              AsyncValue<List<DirectChatMessageModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

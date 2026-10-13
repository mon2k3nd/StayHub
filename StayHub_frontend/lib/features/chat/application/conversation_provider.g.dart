// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConversationNotifier)
final conversationProvider = ConversationNotifierProvider._();

final class ConversationNotifierProvider
    extends
        $AsyncNotifierProvider<ConversationNotifier, List<MessageThreadModel>> {
  ConversationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationNotifierHash();

  @$internal
  @override
  ConversationNotifier create() => ConversationNotifier();
}

String _$conversationNotifierHash() =>
    r'1e866e362719f4588b0be182b39b1c4f3b9f7715';

abstract class _$ConversationNotifier
    extends $AsyncNotifier<List<MessageThreadModel>> {
  FutureOr<List<MessageThreadModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<MessageThreadModel>>,
              List<MessageThreadModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MessageThreadModel>>,
                List<MessageThreadModel>
              >,
              AsyncValue<List<MessageThreadModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

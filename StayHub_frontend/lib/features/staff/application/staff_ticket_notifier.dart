import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class StaffTicketState {
  final List<dynamic> tickets;
  final bool isLoading;

  StaffTicketState({this.tickets = const [], this.isLoading = false});

  StaffTicketState copyWith({List<dynamic>? tickets, bool? isLoading}) {
    return StaffTicketState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StaffTicketNotifier extends Notifier<StaffTicketState> {
  WebSocketChannel? _channel;

  @override
  StaffTicketState build() {
    // Cleanup WebSocket khi provider b? dispose
    ref.onDispose(() {
      unawaited(_channel?.sink.close());
    });

    unawaited(Future.microtask(() => _init()));
    return StaffTicketState();
  }

  Future<void> _init() async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null || user.role != 'STAFF') return;

    state = state.copyWith(isLoading: true);
    await _fetchTickets(user.id);
    unawaited(_connectWebSocket(user.id));
  }

  Future<void> _fetchTickets(int staffId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/v1/tickets/staff/$staffId');
      if (res['success'] == true) {
        state = state.copyWith(tickets: res['data'], isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error fetching staff tickets: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _connectWebSocket(int staffId) async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final token = await secureStorage.getAccessToken();
      if (token == null) return;

      final apiClient = ref.read(apiClientProvider);
      final baseUrl = apiClient.dio.options.baseUrl;
      final wsUrl = baseUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('/api', '/ws')
          .replaceFirst('/v1', '/ws');
      final finalWsUrl = '$wsUrl?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(finalWsUrl));

      _channel?.stream.listen(
        (message) {
          debugPrint('Staff WS Received: $message');
          try {
            final data = jsonDecode(message);
            if (data['event'] == 'ticket_assigned' ||
                data['event'] == 'ticket_closed') {
              unawaited(_fetchTickets(staffId));
            }
          } catch (e) {
            debugPrint('Error parsing WS message: $e');
          }
        },
        onError: (error) {
          debugPrint('Staff WS Error: $error');
        },
        onDone: () {
          debugPrint('Staff WS Closed');
        },
      );
    } catch (e) {
      debugPrint('Error connecting staff WS: $e');
    }
  }

  Future<void> refresh() async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;
    await _fetchTickets(user.id);
  }
}

final staffTicketProvider =
    NotifierProvider<StaffTicketNotifier, StaffTicketState>(
      () => StaffTicketNotifier(),
    );

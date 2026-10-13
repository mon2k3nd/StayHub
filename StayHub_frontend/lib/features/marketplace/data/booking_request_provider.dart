import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/auth_notifier.dart';

enum BookingStatus { none, pending, confirmed, rejected }

class BookingRequest {
  final String roomId;
  final String roomName;
  final DateTime date;
  final int hour;
  final BookingStatus status;

  BookingRequest({
    required this.roomId,
    required this.roomName,
    required this.date,
    required this.hour,
    this.status = BookingStatus.none,
  });

  BookingRequest copyWith({BookingStatus? status}) {
    return BookingRequest(
      roomId: roomId,
      roomName: roomName,
      date: date,
      hour: hour,
      status: status ?? this.status,
    );
  }
}

class BookingRequestNotifier extends Notifier<BookingRequest?> {
  @override
  BookingRequest? build() => null;

  Future<bool> requestBooking(
    String roomId,
    String roomName,
    DateTime date,
    int hour, {
    required int ownerId,
    String? note,
  }) async {
    try {
      final user = ref.read(authProvider).value;
      if (user == null) return false;

      final payload = {
        'roomId': int.tryParse(roomId) ?? 0,
        'tenantId': user.id,
        'ownerId': ownerId,
        'viewDate':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'viewHour': hour,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      await ApiClient().post('/api/v1/viewing-schedules', data: payload);

      state = BookingRequest(
        roomId: roomId,
        roomName: roomName,
        date: date,
        hour: hour,
        status: BookingStatus.pending,
      );
      return true;
    } catch (e) {
      debugPrint('Error booking viewing schedule: $e');
      return false;
    }
  }

  void approveRequest() {
    if (state != null) {
      state = state!.copyWith(status: BookingStatus.confirmed);
    }
  }

  void rejectRequest() {
    if (state != null) {
      state = state!.copyWith(status: BookingStatus.rejected);
    }
  }

  void reset() {
    state = null;
  }
}

final bookingRequestProvider =
    NotifierProvider<BookingRequestNotifier, BookingRequest?>(() {
      return BookingRequestNotifier();
    });

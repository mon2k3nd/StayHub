import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ticket/application/ticket_provider.dart';

// --- Models ---
enum BookingStatus { pending, inProgress, completed, cancelled }

class ServiceItem {
  final String id;
  final String title;
  final String iconName;
  final int colorValue;
  final String priceDesc;

  const ServiceItem({
    required this.id,
    required this.title,
    required this.iconName,
    required this.colorValue,
    required this.priceDesc,
  });
}

class ServiceBooking {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final String notes;
  final DateTime createdAt;
  final BookingStatus status;

  const ServiceBooking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.notes,
    required this.createdAt,
    required this.status,
  });

  ServiceBooking copyWith({BookingStatus? status}) {
    return ServiceBooking(
      id: id,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      notes: notes,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}

// --- Mock Data ---
final _mockAvailableServices = [
  const ServiceItem(
    id: 'cleaning',
    title: 'Dọn dẹp phòng',
    iconName: 'sparkles',
    colorValue: 0xFF10B981,
    priceDesc: 'Từ 150k/lần',
  ),
  const ServiceItem(
    id: 'laundry',
    title: 'Giặt ủi',
    iconName: 'snow',
    colorValue: 0xFF298FFF,
    priceDesc: 'Từ 20k/kg',
  ),
  const ServiceItem(
    id: 'water_gas',
    title: 'Đổi Nước / Gas',
    iconName: 'drop_fill',
    colorValue: 0xFF298FFF,
    priceDesc: 'Giao trong 30p',
  ),
  const ServiceItem(
    id: 'handyman',
    title: 'Sửa chữa điện nước',
    iconName: 'wrench_fill',
    colorValue: 0xFFF59E0B,
    priceDesc: 'Khảo sát miễn phí',
  ),
  const ServiceItem(
    id: 'groceries',
    title: 'Tạp hóa / Đồ ăn',
    iconName: 'bag_fill',
    colorValue: 0xFFEC4899,
    priceDesc: 'Giao tận cửa',
  ),
  const ServiceItem(
    id: 'moving',
    title: 'Chuyển trọ',
    iconName: 'car_detailed',
    colorValue: 0xFF298FFF,
    priceDesc: 'Xe tải / Ba gác',
  ),
];

// --- Providers ---

final availableServicesProvider = Provider<List<ServiceItem>>((ref) {
  return _mockAvailableServices;
});

class ServiceBookingNotifier extends AsyncNotifier<List<ServiceBooking>> {
  @override
  FutureOr<List<ServiceBooking>> build() async {
    // Integrate with Ticket API
    final tickets = await ref.watch(ticketProvider.future);

    // Map tickets to ServiceBooking format for UI consistency
    return tickets
        .map(
          (t) => ServiceBooking(
            id: t.id.toString(),
            serviceId: t.category == 'MAINTENANCE' ? 'handyman' : 'cleaning',
            serviceTitle: t.description ?? 'Dịch vụ StayHub',
            notes: t.description ?? '',
            createdAt: t.createdAt ?? DateTime.now(),
            status: t.status == 'COMPLETED'
                ? BookingStatus.completed
                : t.status == 'IN_PROGRESS'
                ? BookingStatus.inProgress
                : BookingStatus.pending,
          ),
        )
        .toList();
  }

  Future<void> bookNewService(
    String serviceId,
    String serviceTitle,
    String notes,
  ) async {
    state = const AsyncLoading();

    // Convert booking request to a Ticket payload
    final data = {
      'title': serviceTitle,
      'description': notes.isEmpty ? 'Yêu cầu dịch vụ' : notes,
      'type': serviceId == 'handyman' ? 'MAINTENANCE' : 'CLEANING',
      'priority': 'NORMAL',
    };

    // Create ticket via real API
    await ref.read(ticketProvider.notifier).createTicket(data, null);

    // Reload state
    ref.invalidateSelf();
  }
}

final serviceBookingProvider =
    AsyncNotifierProvider<ServiceBookingNotifier, List<ServiceBooking>>(
      () => ServiceBookingNotifier(),
    );

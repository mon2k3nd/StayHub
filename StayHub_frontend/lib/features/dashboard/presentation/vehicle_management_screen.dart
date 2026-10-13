import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Colors, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/components/app_error_widget.dart';

// ──────────────────────────────────────────────
// Model
// ──────────────────────────────────────────────
class VehicleModel {
  final int? id;
  final int tenantId;
  final int ownerId;
  final int? branchId;
  final int? roomId;
  final String vehicleType;
  final String licensePlate;
  final String? brand;
  final String? color;
  final double monthlyFee;
  final String status;
  final String? tenantName;
  final String? roomName;

  const VehicleModel({
    this.id,
    required this.tenantId,
    required this.ownerId,
    this.branchId,
    this.roomId,
    required this.vehicleType,
    required this.licensePlate,
    this.brand,
    this.color,
    this.monthlyFee = 0,
    this.status = 'APPROVED',
    this.tenantName,
    this.roomName,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'],
    tenantId: json['tenantId'] ?? 0,
    ownerId: json['ownerId'] ?? 0,
    branchId: json['branchId'],
    roomId: json['roomId'],
    vehicleType: json['vehicleType'] ?? 'Xe máy',
    licensePlate: json['licensePlate'] ?? '',
    brand: json['brand'],
    color: json['color'],
    monthlyFee: (json['monthlyFee'] ?? 0).toDouble(),
    status: json['status'] ?? 'APPROVED',
    tenantName: json['tenantName'],
    roomName: json['roomName'],
  );

  Map<String, dynamic> toJson() => {
    'tenantId': tenantId,
    'ownerId': ownerId,
    if (branchId != null) 'branchId': branchId,
    if (roomId != null) 'roomId': roomId,
    'vehicleType': vehicleType,
    'licensePlate': licensePlate,
    if (brand != null) 'brand': brand,
    if (color != null) 'color': color,
    'monthlyFee': monthlyFee,
    'status': status,
  };
}

// ──────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────
final vehicleListProvider = FutureProvider.family<List<VehicleModel>, int>((
  ref,
  ownerId,
) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/v1/vehicles/owner/$ownerId');
  // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
  // null/không phải List.
  final raw = res.data is Map ? res.data['data'] : null;
  final data = raw is List ? raw : const <dynamic>[];
  return data
      .whereType<Map>()
      .map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

// ──────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────
class VehicleManagementScreen extends ConsumerStatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  ConsumerState<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState
    extends ConsumerState<VehicleManagementScreen> {
  String _filterType = 'Tất cả';
  final _vehicleTypes = ['Tất cả', 'Xe máy', 'Xe đạp điện', 'Ô tô', 'Xe đạp'];

  int get _ownerId => ref.read(authProvider).value?.id ?? 0;

  Future<void> _showAddVehicleDialog({VehicleModel? existing}) async {
    final types = ['Xe máy', 'Xe đạp điện', 'Ô tô', 'Xe đạp'];
    String selectedType = existing?.vehicleType ?? 'Xe máy';
    final plateCtrl = TextEditingController(text: existing?.licensePlate ?? '');
    final brandCtrl = TextEditingController(text: existing?.brand ?? '');
    final colorCtrl = TextEditingController(text: existing?.color ?? '');
    final feeCtrl = TextEditingController(
      text: existing != null
          ? existing.monthlyFee.toStringAsFixed(0)
          : '100000',
    );
    final tenantCtrl = TextEditingController(
      text: existing?.tenantId.toString() ?? '',
    );

    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => CupertinoAlertDialog(
          title: Text(existing == null ? 'Đăng ký xe mới' : 'Sửa thông tin xe'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.kSurfaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () async {
                      await showCupertinoModalPopup(
                        context: ctx,
                        builder: (_) => Container(
                          height: 200,
                          color: AppTheme.kBackgroundLight,
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: types.indexOf(selectedType),
                            ),
                            onSelectedItemChanged: (i) =>
                                setDlgState(() => selectedType = types[i]),
                            children: types
                                .map((t) => Center(child: Text(t)))
                                .toList(),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedType,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Icon(CupertinoIcons.chevron_down, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: plateCtrl,
                  placeholder: 'Biển số xe (VD: 51A-123.45)',
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: brandCtrl,
                  placeholder: 'Hãng xe (VD: Honda, Yamaha)',
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: colorCtrl,
                  placeholder: 'Màu sắc',
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: feeCtrl,
                  placeholder: 'Phí gửi xe/tháng (VND)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(10),
                ),
                if (existing == null) ...[
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: tenantCtrl,
                    placeholder: 'ID Khách thuê',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(10),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text('Lưu'),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final api = ref.read(apiClientProvider);
                  final payload = {
                    'ownerId': _ownerId,
                    'tenantId':
                        existing?.tenantId ??
                        int.tryParse(tenantCtrl.text) ??
                        0,
                    'vehicleType': selectedType,
                    'licensePlate': plateCtrl.text.trim().toUpperCase(),
                    'brand': brandCtrl.text.trim(),
                    'color': colorCtrl.text.trim(),
                    'monthlyFee': double.tryParse(feeCtrl.text) ?? 0,
                    'status': 'APPROVED',
                  };
                  if (existing == null) {
                    await api.dio.post('/v1/vehicles', data: payload);
                  } else {
                    await api.dio.put(
                      '/v1/vehicles/${existing.id}',
                      data: payload,
                    );
                  }
                  ref.invalidate(vehicleListProvider(_ownerId));
                } catch (e, st) {
                  debugPrint('Error: $e\n$st');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(VehicleModel v) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xóa xe?'),
        content: Text('Xóa biển số ${v.licensePlate}?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Xóa'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(apiClientProvider).dio.delete('/v1/vehicles/${v.id}');
    ref.invalidate(vehicleListProvider(_ownerId));
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleListProvider(_ownerId));

    return LiquidGlassScaffold(
      title: 'Quản Lý Xe',
      useScrollView: false,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.add_circled_solid,
          color: CupertinoColors.systemBlue,
        ),
        onPressed: () => _showAddVehicleDialog(),
      ),
      child: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _vehicleTypes.length,
              itemBuilder: (_, i) {
                final t = _vehicleTypes[i];
                final isSelected = t == _filterType;
                return GestureDetector(
                  onTap: () => setState(() => _filterType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? LiquidGlassColors.tenantAccent
                          : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? LiquidGlassColors.tenantAccent
                            : AppTheme.kTextMuted,
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        color: isSelected
                            ? CupertinoColors.white
                            : CupertinoColors.label,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: vehiclesAsync.when(
              data: (vehicles) {
                final filtered = _filterType == 'Tất cả'
                    ? vehicles
                    : vehicles
                          .where((v) => v.vehicleType == _filterType)
                          .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.car_detailed,
                          size: 60,
                          color: AppTheme.kTextMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có xe nào được đăng ký.',
                          style: TextStyle(color: AppTheme.kTextSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _VehicleCard(
                    vehicle: filtered[i],
                    onEdit: () => _showAddVehicleDialog(existing: filtered[i]),
                    onDelete: () => _deleteVehicle(filtered[i]),
                  ),
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => AppErrorWidget(error: e),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// VehicleCard widget
// ──────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Ô tô':
        return CupertinoIcons.car_detailed;
      case 'Xe đạp':
        return Icons.pedal_bike;
      default:
        return CupertinoIcons.rocket_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feeStr = vehicle.monthlyFee > 0
        ? '${(vehicle.monthlyFee / 1000).toStringAsFixed(0)}k/tháng'
        : 'Miễn phí';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _typeIcon(vehicle.vehicleType),
              color: LiquidGlassColors.tenantAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.licensePlate.isNotEmpty
                      ? vehicle.licensePlate
                      : 'Chưa có biển số',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.vehicleType}${vehicle.brand != null && vehicle.brand!.isNotEmpty ? ' • ${vehicle.brand}' : ''}${vehicle.color != null && vehicle.color!.isNotEmpty ? ' • ${vehicle.color}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    feeStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    color: CupertinoColors.systemBlue,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.systemRed,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

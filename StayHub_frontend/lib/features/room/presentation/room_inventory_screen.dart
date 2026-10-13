import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/components/app_error_widget.dart';

// ──────────────────────────────────────────────
// Model
// ──────────────────────────────────────────────
class RoomAssetModel {
  final int? id;
  final int roomId;
  final String assetName;
  final int quantity;
  final String conditionNote;
  final String assetStatus; // GOOD, DAMAGED, LOST, NORMAL
  final double? value;

  const RoomAssetModel({
    this.id,
    required this.roomId,
    required this.assetName,
    this.quantity = 1,
    this.conditionNote = '',
    this.assetStatus = 'GOOD',
    this.value,
  });

  factory RoomAssetModel.fromJson(Map<String, dynamic> json) => RoomAssetModel(
    id: json['id'],
    roomId: json['roomId'] ?? 0,
    assetName: json['assetName'] ?? '',
    quantity: json['quantity'] ?? 1,
    conditionNote: json['conditionNote'] ?? '',
    assetStatus: json['assetStatus'] ?? 'GOOD',
    value: json['value']?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'assetName': assetName,
    'quantity': quantity,
    'conditionNote': conditionNote,
    'assetStatus': assetStatus,
    if (value != null) 'value': value,
  };
}

// ──────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────
final roomAssetListProvider = FutureProvider.family<List<RoomAssetModel>, int>((
  ref,
  roomId,
) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/v1/assets/room/$roomId');
  // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
  // null/không phải List.
  final raw = res.data is Map ? res.data['data'] : null;
  final data = raw is List ? raw : const <dynamic>[];
  return data
      .whereType<Map>()
      .map((e) => RoomAssetModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

// ──────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────
class RoomInventoryScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;

  const RoomInventoryScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<RoomInventoryScreen> createState() =>
      _RoomInventoryScreenState();
}

class _RoomInventoryScreenState extends ConsumerState<RoomInventoryScreen> {
  final List<String> _presetAssets = [
    'Giường',
    'Tủ quần áo',
    'Bàn học',
    'Ghế',
    'Điều hòa',
    'Quạt trần',
    'Máy nước nóng',
    'Tủ lạnh',
    'Bình gas',
    'Bếp ga',
    'Bình nước',
    'Kệ để đồ',
    'Remote điều hòa',
    'Chìa khóa',
    'Remote cổng',
    'Đèn phòng',
    'Toilet',
  ];

  Future<void> _showAddAssetDialog({RoomAssetModel? existing}) async {
    final statuses = ['GOOD', 'NORMAL', 'DAMAGED', 'LOST'];
    final statusLabels = {
      'GOOD': 'Tốt',
      'NORMAL': 'Bình thường',
      'DAMAGED': 'Hư hỏng',
      'LOST': 'Mất',
    };
    String selectedStatus = existing?.assetStatus ?? 'GOOD';
    final nameCtrl = TextEditingController(text: existing?.assetName ?? '');
    final noteCtrl = TextEditingController(text: existing?.conditionNote ?? '');
    final valueCtrl = TextEditingController(
      text: existing?.value?.toStringAsFixed(0) ?? '',
    );
    int quantity = existing?.quantity ?? 1;

    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => CupertinoAlertDialog(
          title: Text(existing == null ? 'Thêm tài sản' : 'Sửa tài sản'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                // Preset name or custom
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.kSurfaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoTextField(
                    controller: nameCtrl,
                    placeholder: 'Tên tài sản',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Preset quick-select
                SizedBox(
                  height: 80,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _presetAssets
                          .take(12)
                          .map(
                            (name) => GestureDetector(
                              onTap: () =>
                                  setDlgState(() => nameCtrl.text = name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: nameCtrl.text == name
                                      ? LiquidGlassColors.tenantAccent
                                            .withValues(alpha: 0.2)
                                      : AppTheme.kSurfaceBlue,
                                  borderRadius: BorderRadius.circular(6),
                                  border: nameCtrl.text == name
                                      ? Border.all(
                                          color: LiquidGlassColors.tenantAccent,
                                        )
                                      : null,
                                ),
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Quantity
                Row(
                  children: [
                    const Text('Số lượng:', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.minus_circle, size: 22),
                      onPressed: () => setDlgState(() {
                        if (quantity > 1) quantity--;
                      }),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.add_circled, size: 22),
                      onPressed: () => setDlgState(() => quantity++),
                    ),
                  ],
                ),
                // Status
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.kSurfaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                              initialItem: statuses.indexOf(selectedStatus),
                            ),
                            onSelectedItemChanged: (i) =>
                                setDlgState(() => selectedStatus = statuses[i]),
                            children: statuses
                                .map(
                                  (s) =>
                                      Center(child: Text(statusLabels[s] ?? s)),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tình trạng: ${statusLabels[selectedStatus]}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const Icon(CupertinoIcons.chevron_down, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: noteCtrl,
                  placeholder: 'Ghi chú tình trạng',
                  padding: const EdgeInsets.all(8),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: valueCtrl,
                  placeholder: 'Giá trị (VND) – để tính đền bù',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(8),
                ),
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
                    'roomId': widget.roomId,
                    'assetName': nameCtrl.text.trim(),
                    'quantity': quantity,
                    'conditionNote': noteCtrl.text.trim(),
                    'assetStatus': selectedStatus,
                    'value': double.tryParse(valueCtrl.text),
                  };
                  if (existing == null) {
                    await api.dio.post('/v1/assets', data: payload);
                  } else {
                    await api.dio.put(
                      '/v1/assets/${existing.id}',
                      data: payload,
                    );
                  }
                  ref.invalidate(roomAssetListProvider(widget.roomId));
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

  Future<void> _deleteAsset(RoomAssetModel asset) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xóa tài sản?'),
        content: Text('Xóa "${asset.assetName}" khỏi danh sách?'),
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
    await ref.read(apiClientProvider).dio.delete('/v1/assets/${asset.id}');
    ref.invalidate(roomAssetListProvider(widget.roomId));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'GOOD':
        return Colors.green;
      case 'NORMAL':
        return Colors.blue;
      case 'DAMAGED':
        return Colors.orange;
      case 'LOST':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    const labels = {
      'GOOD': 'Tốt',
      'NORMAL': 'BT',
      'DAMAGED': 'Hỏng',
      'LOST': 'Mất',
    };
    return labels[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(roomAssetListProvider(widget.roomId));

    return LiquidGlassScaffold(
      title: 'Tài Sản – ${widget.roomName}',
      useScrollView: false,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.add_circled_solid,
          color: CupertinoColors.systemBlue,
        ),
        onPressed: () => _showAddAssetDialog(),
      ),
      child: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.archivebox,
                    size: 64,
                    color: AppTheme.kTextMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có tài sản nào.\nBấm + để thêm danh sách bàn giao.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.kTextSecondary),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    child: const Text('Thêm tài sản'),
                    onPressed: () => _showAddAssetDialog(),
                  ),
                ],
              ),
            );
          }

          // Calculate total value of damaged/lost assets
          double damagedValue = assets
              .where(
                (a) => a.assetStatus == 'DAMAGED' || a.assetStatus == 'LOST',
              )
              .fold(0.0, (sum, a) => sum + (a.value ?? 0));

          return Column(
            children: [
              if (damagedValue > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tài sản hỏng/mất: Cần thu bồi thường ~${(damagedValue / 1000).toStringAsFixed(0)}k₫',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: assets.length,
                  itemBuilder: (_, i) {
                    final a = assets[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _statusColor(
                                a.assetStatus,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.archivebox_fill,
                              color: _statusColor(a.assetStatus),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.assetName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (a.conditionNote.isNotEmpty)
                                  Text(
                                    a.conditionNote,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.kTextSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    a.assetStatus,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _statusLabel(a.assetStatus),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(a.assetStatus),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SL: ${a.quantity}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showAddAssetDialog(existing: a),
                                child: const Icon(
                                  CupertinoIcons.pencil,
                                  color: CupertinoColors.systemBlue,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _deleteAsset(a),
                                child: const Icon(
                                  CupertinoIcons.trash,
                                  color: CupertinoColors.systemRed,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => AppErrorWidget(error: e),
      ),
    );
  }
}

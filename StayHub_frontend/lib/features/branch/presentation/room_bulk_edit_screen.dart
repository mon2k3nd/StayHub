import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Material,
        Colors,
        DataTable,
        DataColumn,
        DataRow,
        DataCell,
        ScaffoldMessenger,
        SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../data/models/branch_model.dart';
import '../application/branch_notifier.dart';
import 'dart:async' show unawaited;

final branchRoomsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, branchId) async {
      final src = ref.read(branchRemoteDataSourceProvider);
      final res = await src.getRoomsByBranch(branchId);
      // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi `data` là
      // null/không phải List hoặc phần tử không phải Map.
      final raw = res['data'];
      if (raw is! List) return <Map<String, dynamic>>[];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });

class RoomBulkEditScreen extends ConsumerStatefulWidget {
  final BranchModel branch;
  const RoomBulkEditScreen({super.key, required this.branch});

  @override
  ConsumerState<RoomBulkEditScreen> createState() => _RoomBulkEditScreenState();
}

class _RoomBulkEditScreenState extends ConsumerState<RoomBulkEditScreen> {
  final Map<int, Map<String, dynamic>> _editedData = {};
  bool _isLoading = false;

  void _onCellEdited(int roomId, String field, dynamic value) {
    if (!_editedData.containsKey(roomId)) {
      _editedData[roomId] = {};
    }
    _editedData[roomId]![field] = value;
  }

  void _applyToAll(
    String field,
    dynamic value,
    List<Map<String, dynamic>> rooms,
  ) {
    if (value == null || value.toString().isEmpty) return;
    setState(() {
      for (var room in rooms) {
        // BUGFIX (data): trước đây ép `room['id'] as int` — nếu id là
        // String/null thì ném TypeError và thao tác sửa hàng loạt không chạy.
        final rawId = room['id'];
        final rId = rawId is num
            ? rawId.toInt()
            : int.tryParse(rawId?.toString() ?? '');
        if (rId == null) continue;
        _onCellEdited(rId, field, value);
      }
    });
  }

  Future<void> _saveAll() async {
    if (_editedData.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final src = ref.read(branchRemoteDataSourceProvider);
      final futures = <Future>[];

      for (var entry in _editedData.entries) {
        final roomId = entry.key;
        final payload = entry.value;
        futures.add(src.configureRoom(roomId, payload));
      }

      await Future.wait(futures);

      if (mounted) {
        ref.invalidate(branchRoomsProvider(widget.branch.id));
        // Sửa hàng loạt có thể đổi trạng thái cấu hình → làm mới dashboard.
        refreshOwnerDashboardFromWidget(ref);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(branchRoomsProvider(widget.branch.id));

    return LiquidGlassScaffold(
      title: 'Ma Trận Quản Lý Phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return const Center(child: Text('Không có phòng nào.'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Material(
                        color: Colors.transparent,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppTheme.kAccentColor.withValues(alpha: 0.1),
                          ),
                          columnSpacing: 16,
                          columns: [
                            const DataColumn(
                              label: Text(
                                'Tên Phòng',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: _buildApplyHeader(
                                'Giá thuê (đ)',
                                'price',
                                rooms,
                              ),
                            ),
                            DataColumn(
                              label: _buildApplyHeader(
                                'Tiền cọc (đ)',
                                'deposit',
                                rooms,
                              ),
                            ),
                            DataColumn(
                              label: _buildApplyHeader(
                                'Diện tích (m2)',
                                'area',
                                rooms,
                              ),
                            ),
                            DataColumn(
                              label: _buildApplyHeader(
                                'Số người tối đa',
                                'maxOccupants',
                                rooms,
                              ),
                            ),
                          ],
                          rows: rooms.map((room) {
                            // BUGFIX (data): tránh `as int` ném TypeError khi
                            // id là String/null.
                            final rawId = room['id'];
                            final rId = rawId is num
                                ? rawId.toInt()
                                : int.tryParse(rawId?.toString() ?? '') ?? 0;
                            final edited = _editedData[rId] ?? {};

                            return DataRow(
                              cells: [
                                DataCell(
                                  _buildCellInput(
                                    initialValue:
                                        edited['roomName']?.toString() ??
                                        room['roomName']?.toString() ??
                                        '',
                                    onChanged: (v) =>
                                        _onCellEdited(rId, 'roomName', v),
                                  ),
                                ),
                                DataCell(
                                  _buildCellInput(
                                    initialValue:
                                        edited['price']?.toString() ??
                                        room['price']?.toString() ??
                                        '',
                                    isNumber: true,
                                    onChanged: (v) => _onCellEdited(
                                      rId,
                                      'price',
                                      double.tryParse(v) ?? 0,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _buildCellInput(
                                    initialValue:
                                        edited['deposit']?.toString() ??
                                        room['deposit']?.toString() ??
                                        '',
                                    isNumber: true,
                                    onChanged: (v) => _onCellEdited(
                                      rId,
                                      'deposit',
                                      double.tryParse(v) ?? 0,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _buildCellInput(
                                    initialValue:
                                        edited['area']?.toString() ??
                                        room['floorArea']?.toString() ??
                                        '',
                                    isNumber: true,
                                    onChanged: (v) => _onCellEdited(
                                      rId,
                                      'area',
                                      double.tryParse(v) ?? 0,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _buildCellInput(
                                    initialValue:
                                        edited['maxOccupants']?.toString() ??
                                        room['maxGuests']?.toString() ??
                                        '',
                                    isNumber: true,
                                    onChanged: (v) => _onCellEdited(
                                      rId,
                                      'maxOccupants',
                                      int.tryParse(v) ?? 0,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: CupertinoColors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isLoading ? null : _saveAll,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Text(
                          'Lưu Tất Cả Thay Đổi',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyHeader(
    String title,
    String fieldKey,
    List<Map<String, dynamic>> rooms,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            _showApplyAllDialog(title, fieldKey, rooms);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.kAccentColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Áp dụng ⬇',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCellInput({
    required String initialValue,
    required Function(String) onChanged,
    bool isNumber = false,
  }) {
    // Note: In a real app we might want to preserve cursor position by using controllers per cell,
    // but for simplicity in this grid we use TextFormField inside a stateful wrapper or rely on focus loss.
    // To avoid losing focus on every keystroke when UI rebuilds, we use a simple TextField with a local controller.
    return SizedBox(
      width: 120,
      height: 40,
      child: CupertinoTextField(
        controller: TextEditingController(text: initialValue)
          ..selection = TextSelection.collapsed(offset: initialValue.length),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        style: const TextStyle(fontSize: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(6),
        ),
        onChanged: onChanged,
      ),
    );
  }

  void _showApplyAllDialog(
    String title,
    String fieldKey,
    List<Map<String, dynamic>> rooms,
  ) {
    final ctrl = TextEditingController();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Áp dụng $title'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: ctrl,
              placeholder: 'Nhập giá trị...',
              keyboardType: fieldKey == 'roomName'
                  ? TextInputType.text
                  : TextInputType.number,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Hủy',
                style: TextStyle(color: CupertinoColors.systemRed),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text('Áp dụng'),
              onPressed: () {
                final val = fieldKey == 'roomName'
                    ? ctrl.text
                    : (double.tryParse(ctrl.text) ?? 0);
                _applyToAll(fieldKey, val, rooms);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

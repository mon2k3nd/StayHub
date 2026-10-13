import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/room_model.dart';

class BulkCloneRoomBottomSheet extends ConsumerStatefulWidget {
  final RoomModel sourceRoom;
  final List<RoomModel> allRoomsInBranch;

  const BulkCloneRoomBottomSheet({
    super.key,
    required this.sourceRoom,
    required this.allRoomsInBranch,
  });

  @override
  ConsumerState<BulkCloneRoomBottomSheet> createState() =>
      _BulkCloneRoomBottomSheetState();
}

class _BulkCloneRoomBottomSheetState
    extends ConsumerState<BulkCloneRoomBottomSheet> {
  List<RoomModel> _targetRooms = [];
  Set<int> _selectedIds = {};
  final Map<int, TextEditingController> _priceCtrls = {};
  final Map<int, TextEditingController> _areaCtrls = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _targetRooms = widget.allRoomsInBranch
        .where((r) => r.id != widget.sourceRoom.id)
        .toList();
    for (var r in _targetRooms) {
      _priceCtrls[r.id] = TextEditingController(
        text: widget.sourceRoom.price?.toInt().toString() ?? '',
      );
      _areaCtrls[r.id] = TextEditingController(
        text: widget.sourceRoom.area?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var ctrl in _priceCtrls.values) {
      ctrl.dispose();
    }
    for (var ctrl in _areaCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _targetRooms.length) {
        _selectedIds.clear();
      } else {
        _selectedIds = _targetRooms.map((r) => r.id).toSet();
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/api/v1/rooms/bulk-clone',
            data: {
              'sourceRoomId': widget.sourceRoom.id,
              'targetRooms': _selectedIds
                  .map(
                    (id) => {
                      'id': id,
                      'price': double.tryParse(
                        _priceCtrls[id]!.text.replaceAll(',', ''),
                      ),
                      'floorArea': double.tryParse(_areaCtrls[id]!.text),
                    },
                  )
                  .toList(),
            },
          );
      if (mounted) {
        ToastUtils.show(context, 'Nhân bản thành công');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Lỗi: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nhân bản cấu hình',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Chọn các phòng để sao chép giá, phí dịch vụ, và nội thất từ phòng hiện tại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedIds.length} / ${_targetRooms.length} phòng',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF298FFF),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _toggleSelectAll,
                  child: Text(
                    _selectedIds.length == _targetRooms.length
                        ? 'Bỏ chọn hết'
                        : 'Chọn tất cả',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _targetRooms.length,
              itemBuilder: (context, index) {
                final room = _targetRooms[index];
                final isSelected = _selectedIds.contains(room.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected
                          ? _selectedIds.remove(room.id)
                          : _selectedIds.add(room.id);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      color: isSelected
                          ? const Color(0xFF298FFF).withValues(alpha: 0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF298FFF)
                            : AppTheme.kBrandLight.withValues(alpha: 0.3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: isSelected
                                    ? const Color(0xFF298FFF)
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                room.roomName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          if (isSelected) const SizedBox(height: 12),
                          if (isSelected)
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: _priceCtrls[room.id],
                                    placeholder: 'Giá thuê',
                                    keyboardType: TextInputType.number,
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        CupertinoIcons.money_dollar,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: _areaCtrls[room.id],
                                    placeholder: 'Diện tích',
                                    keyboardType: TextInputType.number,
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        CupertinoIcons.square_on_square,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    suffix: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Text(
                                        'm²',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: _selectedIds.isEmpty
                      ? CupertinoColors.inactiveGray
                      : const Color(0xFF298FFF),
                  borderRadius: BorderRadius.circular(100),
                  onPressed: (_selectedIds.isEmpty || _isLoading)
                      ? null
                      : _submit,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Áp dụng',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

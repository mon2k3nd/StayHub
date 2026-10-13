import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/utils/toast_utils.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/identifier_utils.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../data/models/room_model.dart';
import '../../branch/application/branch_notifier.dart';
import '../../../core/providers/core_providers.dart';
import '../application/room_notifier.dart';
import '../../../core/components/responsive_file_image.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/dashboard_refresh.dart';

class _FurnitureItem {
  final String key;
  final String label;
  final String emoji;
  const _FurnitureItem({
    required this.key,
    required this.label,
    required this.emoji,
  });
}

const _furniturePresets = [
  _FurnitureItem(key: 'AC', label: 'Điều hoà', emoji: '❄️'),
  _FurnitureItem(key: 'NUOC_NONG', label: 'Nóng lạnh', emoji: '🚿'),
  _FurnitureItem(key: 'GIUONG', label: 'Giường', emoji: '🛏️'),
  _FurnitureItem(key: 'TU_QUAN_AO', label: 'Tủ quần áo', emoji: '🗄️'),
  _FurnitureItem(key: 'BAN_HOC', label: 'Bàn học', emoji: '📚'),
  _FurnitureItem(key: 'TU_LANH', label: 'Tủ lạnh', emoji: '🧊'),
  _FurnitureItem(key: 'TV', label: 'TV', emoji: '📺'),
  _FurnitureItem(key: 'MAY_GIAT', label: 'Máy giặt', emoji: '🫧'),
  _FurnitureItem(key: 'BEP', label: 'Bếp', emoji: '🍳'),
  _FurnitureItem(key: 'SOFA', label: 'Sofa', emoji: '🛋️'),
];

const _roomLayoutPresets = [
  _FurnitureItem(key: 'STUDIO', label: 'Studio', emoji: '🏢'),
  _FurnitureItem(key: '1PN', label: '1 Phòng ngủ', emoji: '🛏️'),
  _FurnitureItem(key: '2PN', label: '2 Phòng ngủ', emoji: '🛌'),
  _FurnitureItem(key: '3PN', label: '3 Phòng ngủ', emoji: '🏠'),
  _FurnitureItem(key: 'DUPLEX', label: 'Duplex', emoji: '🪜'),
  _FurnitureItem(key: 'PHONG_KHACH', label: 'Phòng khách', emoji: '🛋️'),
  _FurnitureItem(key: 'PHONG_BEP', label: 'Bếp riêng', emoji: '🍳'),
  _FurnitureItem(key: 'PHONG_TRONG', label: 'Phòng trống', emoji: '📦'),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class CreateRoomsWizardScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String branchCode;
  final int totalRooms;

  const CreateRoomsWizardScreen({
    super.key,
    required this.branchId,
    required this.branchCode,
    required this.totalRooms,
  });

  @override
  ConsumerState<CreateRoomsWizardScreen> createState() =>
      _CreateRoomsWizardScreenState();
}

class _CreateRoomsWizardScreenState
    extends ConsumerState<CreateRoomsWizardScreen> {
  int _currentRoomIndex = 1;
  bool _isLoading = false;
  bool _isFetchingRooms = true;
  List<RoomModel> _rooms = [];

  // Basic controllers
  final _roomNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _mezzanineAreaCtrl = TextEditingController();
  final _baseDepositCtrl = TextEditingController();
  final _maxCapacityCtrl = TextEditingController();
  final _maxVehiclesCtrl = TextEditingController(text: '2');
  final _descCtrl = TextEditingController();

  // Room detail fields
  String _bathroomType = 'CHUNG';
  String _direction = '';
  final Set<String> _furniture = {};
  final Set<String> _roomLayouts = {};
  bool _hasBalcony = false;
  bool _hasWindow = true;
  // ignore: unused_field
  bool _hasPrivateMeter = true;
  DateTime _availableFrom = DateTime.now();
  final List<File> _roomPhotos = [];

  // Service Pool config
  // _availablePools populated by _loadPools, stored for potential future UI use
  List<Map<String, dynamic>> _availablePools = []; // ignore: unused_field
  bool _loadingPools = false; // ignore: unused_field
  final Set<int> _selectedPoolIds = {};
  final Set<String> _selectedServices = {};

  // Optional section toggles
  bool _showDirection = false;
  bool _showRoomLayout = false;
  bool _showBathroom = false;
  bool _showFurniture = false;
  bool _showPhotos = false;
  bool _showDescription = false;
  bool _showExtraCapacity = false;
  bool _showAvailableFrom = false;

  bool _applyToAll = false;

  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _roomNameCtrl.addListener(() => setState(() {}));
    unawaited(_loadRooms());
    unawaited(_loadPools(widget.branchId));

    // Auto-save every 30 seconds quietly
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isLoading && _roomNameCtrl.text.isNotEmpty) {
        unawaited(_performQuietAutoSave());
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _roomNameCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _mezzanineAreaCtrl.dispose();
    _baseDepositCtrl.dispose();
    _maxCapacityCtrl.dispose();
    _maxVehiclesCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      final repo = ref.read(roomRepositoryProvider);
      final rooms = await repo.loadByBranch(widget.branchId);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isFetchingRooms = false;
          if (rooms.isNotEmpty) {
            final r = rooms[0];
            _roomNameCtrl.text = r.roomName;
            _priceCtrl.text = (r.price ?? 0) > 0 ? r.price.toString() : '';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingRooms = false);
    }
  }

  Future<void> _loadPools(int branchId) async {
    setState(() => _loadingPools = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/service-pools/branch/$branchId');
      if (mounted) {
        setState(() {
          // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi body
          // không phải List hoặc phần tử không phải Map.
          final raw = resp.data;
          _availablePools = raw is List
              ? raw
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
              : <Map<String, dynamic>>[];
          _loadingPools = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPools = false);
    }
  }

  Future<void> _fetchRooms() async {
    // Bug fix: tách 2 guard riêng – không silent-fail nữa
    if (_rooms.isEmpty) {
      _showDialog('Lỗi', 'Dữ liệu phòng chưa được tải. Vui lòng thử lại.');
      return;
    }
    if (_roomNameCtrl.text.trim().isEmpty ||
        _priceCtrl.text.trim().isEmpty ||
        _areaCtrl.text.trim().isEmpty ||
        _baseDepositCtrl.text.trim().isEmpty) {
      _showDialog(
        'Thiếu thông tin',
        'Vui lòng nhập tên phòng, giá thuê, diện tích và tiền cọc.',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final currentRoom = _rooms[_currentRoomIndex - 1];
      final repo = ref.read(roomRepositoryProvider);

      List<String> photoUrls = [];
      if (_roomPhotos.isNotEmpty) {
        photoUrls = await repo.uploadRoomImages(
          currentRoom.id,
          _roomPhotos.map((f) => f.path).toList(),
        );
      }

      final rawPrice = _priceCtrl.text
          .replaceAll(',', '')
          .replaceAll('.', '')
          .trim();
      final rawDeposit = _baseDepositCtrl.text
          .replaceAll(',', '')
          .replaceAll('.', '')
          .trim();

      final configData = {
        'price': double.tryParse(rawPrice) ?? 0.0,
        'area': double.tryParse(_areaCtrl.text),
        'deposit': double.tryParse(rawDeposit),
        'maxOccupants': int.tryParse(_maxCapacityCtrl.text) ?? 1,
        'maxVehicles': int.tryParse(_maxVehiclesCtrl.text) ?? 2,
        'roomDescription': _descCtrl.text,
        'isSelfContained': _bathroomType == 'RIENG',
        'orientation': _direction.isEmpty ? null : _direction,
        'furnitureItems': _furniture.toList(),
        'hasBalcony': _hasBalcony,
        'hasWindow': _hasWindow,
        'hasMezzanine':
            double.tryParse(_mezzanineAreaCtrl.text) != null &&
            double.tryParse(_mezzanineAreaCtrl.text)! > 0,
        if (_selectedPoolIds.isNotEmpty) 'poolIds': _selectedPoolIds.toList(),
        if (_selectedServices.isNotEmpty)
          'services': _selectedServices.toList(),
        'roomLayouts': _roomLayouts.toList(),
        'availableFrom':
            '${_availableFrom.year}-${_availableFrom.month.toString().padLeft(2, '0')}-${_availableFrom.day.toString().padLeft(2, '0')}',
        if (photoUrls.isNotEmpty) 'photos': photoUrls,
      };

      if (_applyToAll) {
        // Cấu hình phòng hiện tại
        await repo.configureRoom(currentRoom.id, {
          ...configData,
          'roomName': _roomNameCtrl.text.trim(),
        });

        // Áp dụng cho các phòng còn lại
        for (int i = _currentRoomIndex; i < _rooms.length; i++) {
          final r = _rooms[i];
          await repo.configureRoom(r.id, {
            ...configData,
            'roomName': r.roomName, // Giữ nguyên tên gốc của phòng đó
          });
        }
        if (mounted) setState(() => _isLoading = false);
        _finishWizard();
      } else {
        await repo.configureRoom(currentRoom.id, {
          ...configData,
          'roomName': _roomNameCtrl.text.trim(),
        });
        if (mounted) setState(() => _isLoading = false);
        _moveToNextOrFinish();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showDialog('Lỗi', 'Không thể cập nhật phòng: $e');
      }
    }
  }

  void _moveToNextOrFinish() {
    if (_currentRoomIndex < widget.totalRooms &&
        _currentRoomIndex < _rooms.length) {
      setState(() {
        _currentRoomIndex++;
        _roomNameCtrl.clear();
        _priceCtrl.clear();
        _areaCtrl.clear();
        _mezzanineAreaCtrl.clear();
        _baseDepositCtrl.clear();
        _maxCapacityCtrl.clear();
        _maxVehiclesCtrl.text = '2';
        _descCtrl.clear();
        _bathroomType = 'CHUNG';
        _direction = '';
        _furniture.clear();
        _roomLayouts.clear();
        _hasBalcony = false;
        _hasWindow = true;
        _hasPrivateMeter = true;
        _availableFrom = DateTime.now();
        _roomPhotos.clear();
        _selectedPoolIds.clear();
        _showDirection = _showRoomLayout = _showBathroom = _showFurniture =
            _showPhotos = _showDescription = _showExtraCapacity =
                _showAvailableFrom = false;
        if (_currentRoomIndex <= _rooms.length) {
          final r = _rooms[_currentRoomIndex - 1];
          _roomNameCtrl.text = r.roomName;
          _priceCtrl.text = (r.price ?? 0) > 0 ? r.price.toString() : '';
        }
      });
    } else {
      setState(() => _isLoading = true);
      unawaited(
        ref
            .read(branchRepositoryProvider)
            .completeBranch(widget.branchId)
            .then((_) {
              if (mounted) setState(() => _isLoading = false);

              final user = ref.read(authProvider).value;
              final isStaff = user?.role == 'STAFF';
              final message = isStaff
                  ? 'Bạn đã nhập đủ thông tin cho tất cả ${widget.totalRooms} phòng. Dãy trọ đang ở trạng thái CHỜ DUYỆT. Vui lòng báo quản lý/chủ nhà duyệt để hiển thị trên ứng dụng.'
                  : 'Bạn đã nhập đủ thông tin cho tất cả ${widget.totalRooms} phòng. Dãy trọ đã sẵn sàng đăng trên StayHub!';

              _showDialog(
                '🎉 Hoàn tất!',
                message,
                onSuccess: () {
                  _finishWizard();
                },
              );
            })
            .catchError((e) {
              if (mounted) {
                setState(() => _isLoading = false);
                _showDialog('Lỗi', 'Không thể hoàn tất dãy trọ: $e');
              }
            }),
      );
    }
  }

  void _nextRoom() => _fetchRooms();

  Future<void> _saveCurrentRoomAsDraft() async {
    if (_roomNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      context.go('/landlord/branch-management');
      return;
    }
    setState(() => _isLoading = true);
    await _performQuietAutoSave();
    refreshOwnerDashboardFromWidget(ref);
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/landlord/branch-management');
    ToastUtils.show(context, 'Đã lưu bản nháp');
  }

  Future<void> _performQuietAutoSave() async {
    if (_rooms.isEmpty || _currentRoomIndex > _rooms.length) return;
    try {
      final currentRoom = _rooms[_currentRoomIndex - 1];
      final repo = ref.read(roomRepositoryProvider);

      final rawPrice = _priceCtrl.text
          .replaceAll(',', '')
          .replaceAll('.', '')
          .trim();
      final rawDeposit = _baseDepositCtrl.text
          .replaceAll(',', '')
          .replaceAll('.', '')
          .trim();

      await repo.configureRoom(currentRoom.id, {
        'roomName': _roomNameCtrl.text.trim(),
        'price': double.tryParse(rawPrice) ?? 0.0,
        if (_areaCtrl.text.isNotEmpty) 'area': double.tryParse(_areaCtrl.text),
        if (rawDeposit.isNotEmpty) 'deposit': double.tryParse(rawDeposit),
        'roomDescription': _descCtrl.text,
        'isSelfContained': _bathroomType == 'RIENG',
        'furnitureItems': _furniture.toList(),
      });
    } catch (_) {
      // Quiet fail for background auto-save
    }
  }

  Future<void> _pickPhoto() async {
    unawaited(
      ImagePickerUtils.showPicker(
        context: context,
        onPicked: (files) {
          setState(() {
            for (final f in files) {
              _roomPhotos.add(File(f.path));
            }
          });
        },
      ),
    );
  }

  void _finishWizard() {
    refreshOwnerDashboardFromWidget(ref);
    context.go('/landlord/branch-management');
    ToastUtils.show(context, '🎉 Đã khởi tạo cấu hình phòng thành công!');
  }

  void _cancel() {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác nhận huỷ'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Bạn có chắc muốn huỷ không?\n\nDãy trọ vừa tạo và toàn bộ phòng sẽ bị XOÁ hoàn toàn. Không thể hoàn tác.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await ref
                      .read(branchProvider.notifier)
                      .deleteBranch(widget.branchId);
                } catch (_) {
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    context.go('/owner-dashboard');
                  }
                }
              },
              child: const Text('Xóa và Thoát'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tiếp tục chỉnh sửa'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String message, {VoidCallback? onSuccess}) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(ctx);
                onSuccess?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Mã phòng đầy đủ: {branchCode}-{roomName}, build theo IdentifierUtils
    final roomCode = _roomNameCtrl.text.isNotEmpty
        ? IdentifierUtils.buildRoomFullCode(
            branchFullCode: widget.branchCode,
            roomName: _roomNameCtrl.text,
          )
        : '';
    final progress = _currentRoomIndex / widget.totalRooms;

    return LiquidGlassScaffold(
      title: 'Khởi Tạo Phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: _isFetchingRooms
            ? const Center(child: CupertinoActivityIndicator(radius: 20))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Progress header ─────────────────────────────────────
                  _buildProgressHeader(progress, roomCode),
                  const SizedBox(height: 24),

                  // ── Basic info ──────────────────────────────────────────
                  _buildSectionTitle('THÔNG TIN BẮT BUỘC'),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Giá thuê, diện tích và tiền cọc là bắt buộc',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ),
                  _buildInput(
                    ctrl: _roomNameCtrl,
                    placeholder: 'Tên phòng (VD: 101)',
                    icon: CupertinoIcons.home,
                  ),
                  const SizedBox(height: 10),
                  if (roomCode.isNotEmpty)
                    _buildReadOnlyRow(CupertinoIcons.barcode, roomCode),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          ctrl: _priceCtrl,
                          placeholder: 'Giá thuê (VNĐ/tháng)',
                          icon: CupertinoIcons.money_dollar,
                          type: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInput(
                          ctrl: _baseDepositCtrl,
                          placeholder: 'Cọc cơ bản (VNĐ)',
                          icon: CupertinoIcons.money_dollar,
                          type: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          ctrl: _areaCtrl,
                          placeholder: 'Diện tích (m²)',
                          icon: CupertinoIcons.square,
                          type: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInput(
                          ctrl: _mezzanineAreaCtrl,
                          placeholder: 'Gác lửng (m²)',
                          icon: CupertinoIcons.square_split_1x2,
                          type: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('CẤU HÌNH DỊCH VỤ DÙNG CHUNG'),
                  _buildServicePoolSection(),
                  const SizedBox(height: 20),

                  // ──── OPTIONAL SECTIONS ────────────────────────────────
                  const SizedBox(height: 4),
                  _buildSectionTitle('THÊM THÔNG TIN (Tuỳ chọn)'),
                  const SizedBox(height: 4),
                  const Text(
                    'Ấn chọn để bổ sung chi tiết phòng',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Capacity chips
                  _buildOptionalSection(
                    key: 'capacity',
                    icon: CupertinoIcons.person_2,
                    label: 'Sức chứa & Xe',
                    enabled: _showExtraCapacity,
                    onToggle: (v) => setState(() => _showExtraCapacity = v),
                    body: Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            ctrl: _maxCapacityCtrl,
                            placeholder: 'Người ở tối đa',
                            icon: CupertinoIcons.person_2,
                            type: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(
                            ctrl: _maxVehiclesCtrl,
                            placeholder: 'Xe tối đa',
                            icon: CupertinoIcons.car,
                            type: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hướng phòng
                  _buildOptionalSection(
                    key: 'direction',
                    icon: CupertinoIcons.compass,
                    label: 'Hướng phòng',
                    enabled: _showDirection,
                    onToggle: (v) => setState(() => _showDirection = v),
                    body: _buildDirectionSelector(),
                  ),

                  // Cấu trúc phòng
                  _buildOptionalSection(
                    key: 'layout',
                    icon: CupertinoIcons.square_grid_2x2,
                    label: 'Cấu trúc phòng',
                    enabled: _showRoomLayout,
                    onToggle: (v) => setState(() => _showRoomLayout = v),
                    body: _buildRoomLayouts(),
                  ),

                  // Vệ sinh
                  _buildOptionalSection(
                    key: 'bathroom',
                    icon: CupertinoIcons.drop,
                    label: 'Loại vệ sinh & Phụ kiện',
                    enabled: _showBathroom,
                    onToggle: (v) => setState(() => _showBathroom = v),
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionChip(
                                label: '🚿 Vệ sinh khép kín',
                                selected: _bathroomType == 'RIENG',
                                onTap: () =>
                                    setState(() => _bathroomType = 'RIENG'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildOptionChip(
                                label: '🚻 Vệ sinh chung',
                                selected: _bathroomType == 'CHUNG',
                                onTap: () =>
                                    setState(() => _bathroomType = 'CHUNG'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildToggleCard(
                                label: '🌅 Có ban công',
                                value: _hasBalcony,
                                onChanged: (v) =>
                                    setState(() => _hasBalcony = v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildToggleCard(
                                label: '🪟 Có cửa sổ',
                                value: _hasWindow,
                                onChanged: (v) =>
                                    setState(() => _hasWindow = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Nội thất
                  _buildOptionalSection(
                    key: 'furniture',
                    icon: CupertinoIcons.house,
                    label: 'Nội thất có sẵn',
                    enabled: _showFurniture,
                    onToggle: (v) => setState(() => _showFurniture = v),
                    body: _buildFurnitureChecklist(),
                  ),

                  // Ảnh phòng
                  _buildOptionalSection(
                    key: 'photos',
                    icon: CupertinoIcons.photo,
                    label: 'Ảnh phòng (tối đa 15)',
                    enabled: _showPhotos,
                    onToggle: (v) => setState(() => _showPhotos = v),
                    body: _buildPhotoUpload(),
                  ),

                  // Ngày vào ở
                  _buildOptionalSection(
                    key: 'availableFrom',
                    icon: CupertinoIcons.calendar,
                    label: 'Ngày vào ở sớm nhất',
                    enabled: _showAvailableFrom,
                    onToggle: (v) => setState(() => _showAvailableFrom = v),
                    body: _buildDatePicker(),
                  ),

                  // Mô tả
                  _buildOptionalSection(
                    key: 'description',
                    icon: CupertinoIcons.doc_text,
                    label: 'Mô tả thêm',
                    enabled: _showDescription,
                    onToggle: (v) => setState(() => _showDescription = v),
                    body: _buildInput(
                      ctrl: _descCtrl,
                      placeholder: 'Mô tả chi tiết về phòng...',
                      icon: CupertinoIcons.text_alignleft,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Buttons ─────────────────────────────────────────────
                  if (_currentRoomIndex < widget.totalRooms)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kBrand.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.kBrand.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Áp dụng hàng loạt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.kBrand,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sử dụng cấu hình này cho tất cả ${widget.totalRooms - _currentRoomIndex} phòng còn lại',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: _applyToAll,
                            activeTrackColor: AppTheme.kBrand,
                            onChanged: (val) {
                              setState(() => _applyToAll = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  _buildSubmitButton(),
                  const SizedBox(height: 12),
                  _buildDraftButton(),
                  const SizedBox(height: 12),
                  _buildCancelButton(),
                  const SizedBox(height: 60),
                ],
              ),
      ),
    );
  }

  // ─── Sub-Widgets ──────────────────────────────────────────────────────────

  // --- Service Pool Section ---
  Widget _buildServicePoolSection() {
    final services = [
      'WiFi',
      'Bãi xe máy',
      'Bãi xe ô tô',
      'Máy giặt',
      'Bể bơi',
      'Gym',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(services.length, (index) {
        final service = services[index];
        final isSelected = _selectedServices.contains(service);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: GestureDetector(
            onTap: () {
              unawaited(HapticFeedback.lightImpact());
              setState(() {
                if (isSelected) {
                  _selectedServices.remove(service);
                } else {
                  _selectedServices.add(service);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.kSuccess.withValues(alpha: 0.1)
                    : CupertinoColors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.kSuccess
                      : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.kSuccess.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                service,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.kSuccess
                      : const Color(0xFF4B5563),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // --- Helper UI ---
  Widget _buildOptionalSection({
    required String key,
    required IconData icon,
    required String label,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required Widget body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onToggle(!enabled),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: enabled ? CupertinoColors.white : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled ? AppTheme.kAccentColor : const Color(0xFFE5E7EB),
              width: enabled ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header row (always visible)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: enabled
                            ? AppTheme.kAccentColor
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: enabled
                            ? CupertinoColors.white
                            : const Color(0xFF9CA3AF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: enabled
                              ? AppTheme.kAccentColor
                              : const Color(0xFF374151),
                          fontWeight: enabled
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: enabled ? 0.25 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        color: enabled
                            ? AppTheme.kAccentColor
                            : const Color(0xFF9CA3AF),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded body
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: GestureDetector(
                  onTap: () {}, // prevent parent onTap
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: body,
                  ),
                ),
                crossFadeState: enabled
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(double progress, String roomCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi Tiết Phòng',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phòng $_currentRoomIndex / ${widget.totalRooms}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_currentRoomIndex / ${widget.totalRooms}',
                style: const TextStyle(
                  color: AppTheme.kAccentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 8,
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      width: constraints.maxWidth * progress,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5FAEFF), Color(0xFF298FFF)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF298FFF,
                            ).withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.kAccentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController ctrl,
    required String placeholder,
    required IconData icon,
    TextInputType? type,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        final focusNode = FocusNode();
        bool isFocused = false;
        focusNode.addListener(() {
          if (mounted) setState(() => isFocused = focusNode.hasFocus);
        });

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFF298FFF)
                  : const Color(0xFFE5E7EB),
              width: isFocused ? 1.5 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF298FFF).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: CupertinoTextField(
            focusNode: focusNode,
            controller: ctrl,
            placeholder: placeholder,
            keyboardType: type,
            textInputAction: TextInputAction.done,
            placeholderStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            style: const TextStyle(color: Color(0xFF111827)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(
                icon,
                color: isFocused
                    ? const Color(0xFF298FFF)
                    : AppTheme.kAccentColor,
                size: 18,
              ),
            ),
            decoration: null,
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.kAccentColor : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.kAccentColor : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? CupertinoColors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: value
              ? AppTheme.kAccentColor.withValues(alpha: 0.08)
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppTheme.kAccentColor : const Color(0xFFE5E7EB),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: value ? AppTheme.kAccentColor : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Icon(
              value
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: value ? AppTheme.kAccentColor : const Color(0xFFD1D5DB),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionSelector() {
    const directions = [
      ('DONG', 'Đông ↑'),
      ('TAY', 'Tây ↓'),
      ('NAM', 'Nam →'),
      ('BAC', 'Bắc ←'),
    ];
    return Row(
      children: directions.map((d) {
        final selected = _direction == d.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _direction = selected ? '' : d.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.kAccentColor
                      : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppTheme.kAccentColor
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Center(
                  child: Text(
                    d.$2,
                    style: TextStyle(
                      color: selected
                          ? CupertinoColors.white
                          : const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFurnitureChecklist() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _furniturePresets.map((item) {
        final selected = _furniture.contains(item.key);
        return GestureDetector(
          onTap: () => setState(() {
            selected ? _furniture.remove(item.key) : _furniture.add(item.key);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.kAccentColor : CupertinoColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppTheme.kAccentColor
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.emoji),
                const SizedBox(width: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected
                        ? CupertinoColors.white
                        : const Color(0xFF374151),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoomLayouts() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roomLayoutPresets.map((item) {
        final selected = _roomLayouts.contains(item.key);
        return GestureDetector(
          onTap: () => setState(() {
            selected
                ? _roomLayouts.remove(item.key)
                : _roomLayouts.add(item.key);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.kAccentColor : CupertinoColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppTheme.kAccentColor
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.emoji),
                const SizedBox(width: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected
                        ? CupertinoColors.white
                        : const Color(0xFF374151),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () {
        unawaited(
          showCupertinoModalPopup(
            context: context,
            builder: (_) => Container(
              height: 250,
              color: AppTheme.kBackgroundLight,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        child: const Text('Xong'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: _availableFrom,
                      minimumDate: DateTime.now(),
                      onDateTimeChanged: (d) =>
                          setState(() => _availableFrom = d),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.calendar,
              color: AppTheme.kAccentColor,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              'Có thể vào ở từ: ${_availableFrom.day}/${_availableFrom.month}/${_availableFrom.year}',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              CupertinoIcons.chevron_down,
              color: Color(0xFF9CA3AF),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Add photo button
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.kAccentColor.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.plus_circle,
                        color: AppTheme.kAccentColor,
                        size: 28,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Thêm ảnh',
                        style: TextStyle(
                          color: AppTheme.kAccentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Photo thumbnails
              ..._roomPhotos.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ResponsiveFileImage(
                          e.value,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _roomPhotos.removeAt(e.key)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (_roomPhotos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              'Ảnh thực tế giúp tăng 3x tỷ lệ khách thuê',
              style: TextStyle(color: Colors.orange[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _nextRoom,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.kBrand, AppTheme.kBrandDeep],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kBrand.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  _applyToAll
                      ? '✅ Áp dụng & Hoàn tất (${widget.totalRooms - _currentRoomIndex + 1} phòng)'
                      : _currentRoomIndex < widget.totalRooms
                      ? 'Lưu & Phòng Tiếp Theo →'
                      : '✅ Lưu & Hoàn Tất',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDraftButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveCurrentRoomAsDraft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text(
            'Lưu Bản Nháp & Thoát',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _cancel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Center(
          child: Text(
            'Huỷ & Thoát',
            style: TextStyle(
              color: AppTheme.kError,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

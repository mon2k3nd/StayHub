import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/utils/identifier_utils.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../branch/application/branch_notifier.dart';
import '../application/room_notifier.dart';
import '../../../core/components/responsive_file_image.dart';
import 'package:flutter/services.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class CreateRoomScreen extends ConsumerStatefulWidget {
  final int? ownerId;
  final int? branchId;
  final String? branchName;

  const CreateRoomScreen({
    super.key,
    this.ownerId,
    this.branchId,
    this.branchName,
  });

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _elecInitCtrl = TextEditingController();
  final _waterInitCtrl = TextEditingController();

  // Mã phòng tự động sinh: không để chủ nhà nhập thủ công
  String _autoRoomCode = '';
  // branchCode của dãy đã chọn (cần để build room full code)
  String? _selectedBranchCode;

  final _floorAreaCtrl = TextEditingController();
  final _mezzanineAreaCtrl = TextEditingController();
  final _baseDepositCtrl = TextEditingController();
  final _maxVehiclesCtrl = TextEditingController(text: '2');
  final _maxGuestsCtrl = TextEditingController(text: '2');
  final _contractDurationCtrl = TextEditingController(
    text: '12',
  ); // Thời hạn hợp đồng (tháng)

  int? _selectedBranchId;
  String? _selectedBranchName;

  final List<String> _imagePaths = [];
  // -- Physical Attributes State --------------------------------
  String _bathroomType = 'RIENG'; // RIENG | CHUNG
  String _direction =
      'DONG_NAM'; // DONG | TAY | NAM | BAC | DONG_NAM | DONG_BAC | TAY_NAM | TAY_BAC
  bool _hasBalcony = false;
  bool _hasWindow = true;
  final Set<String> _selectedFurniture = {};

  // Preset danh mục nội thất mẫu
  final List<Map<String, String>> _furniturePresets = const [
    {'key': 'AC', 'label': 'Điều hoà', 'emoji': '❄️'},
    {'key': 'NUOC_NONG', 'label': 'Nóng lạnh', 'emoji': '🚿'},
    {'key': 'GIUONG', 'label': 'Giường ngủ', 'emoji': '🛏️'},
    {'key': 'TU_QUAN_AO', 'label': 'Tủ quần áo', 'emoji': '🚪'},
    {'key': 'BAN_HOC', 'label': 'Bàn học/làm việc', 'emoji': '💻'},
    {'key': 'TU_LANH', 'label': 'Tủ lạnh', 'emoji': '🧊'},
    {'key': 'MAY_GIAT', 'label': 'Máy giặt', 'emoji': '🧺'},
    {'key': 'BEP', 'label': 'Bếp nấu', 'emoji': '🍳'},
  ];

  // -- Service Pool config ---------------------------------------
  bool _hasPrivateMeter = true; // true = công to riêng, false = dùng chung Pool
  List<Map<String, dynamic>> _availablePools = [];
  // ignore: prefer_final_fields
  Set<int> _selectedPoolIds = {};
  bool _loadingPools = false;

  late AnimationController _btnAnimCtrl;
  late Animation<double> _btnScaleAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.branchId;
    _selectedBranchName = widget.branchName;
    _btnAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _btnScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnAnimCtrl, curve: Curves.easeInOut));
    if (widget.branchId != null) unawaited(_loadPools(widget.branchId!));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floorCtrl.dispose();
    _priceCtrl.dispose();
    _elecInitCtrl.dispose();
    _waterInitCtrl.dispose();

    _floorAreaCtrl.dispose();
    _mezzanineAreaCtrl.dispose();
    _baseDepositCtrl.dispose();
    _maxVehiclesCtrl.dispose();
    _maxGuestsCtrl.dispose();
    _contractDurationCtrl.dispose();

    _btnAnimCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop =
            await showCupertinoDialog<bool>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Hủy thao tác?'),
                content: const Text(
                  'Dữ liệu bạn vừa nhập sẽ không được lưu. Bạn có chắc chắn muốn thoát?',
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Không'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('Có, thoát'),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ) ??
            false;
        if (shouldPop && context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: LiquidGlassScaffold(
        title: 'Thêm Phòng Trọ Mới',
        backgroundColors: AppTheme.kBackgroundLight,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm phòng trọ',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập thông tin chi tiết phòng để đăng tải và bắt đầu cho thuê.',
                style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('VỊ TRÍ & ĐỊNH DANH'),
              _buildBranchSelector(),
              const SizedBox(height: 16),
              // Ô nhập tên phòng — mã tự sinh
              _buildRoomNameInput(),
              const SizedBox(height: 16),
              // Preview mã auto-gen
              if (_autoRoomCode.isNotEmpty) _buildRoomCodePreview(),
              const SizedBox(height: 16),
              _buildInput(
                controller: _floorCtrl,
                placeholder: 'Tầng',
                icon: CupertinoIcons.arrow_up_down_square_fill,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('KÍCH THƯỚC & GIỚI HẠN'),
              _buildInput(
                controller: _floorAreaCtrl,
                placeholder: 'Diện tích sàn (m²)',
                icon: CupertinoIcons.square_split_2x2_fill,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _mezzanineAreaCtrl,
                placeholder: 'Diện tích gác xép (m²)',
                icon: CupertinoIcons.square_split_2x2_fill,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _maxGuestsCtrl,
                placeholder: 'Giới hạn người ở tối đa',
                icon: CupertinoIcons.person_2_fill,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _maxVehiclesCtrl,
                placeholder: 'Giới hạn số lượng xe máy',
                icon: CupertinoIcons.car_detailed,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('THÔNG TIN THUÊ'),
              _buildInput(
                controller: _priceCtrl,
                placeholder: 'Giá thuê phòng (đ/tháng)',
                icon: CupertinoIcons.money_dollar_circle_fill,
                keyboardType: TextInputType.number,
                formatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _baseDepositCtrl,
                placeholder: 'Tiền cọc tiêu chuẩn (đ)',
                icon: CupertinoIcons.shield_fill,
                keyboardType: TextInputType.number,
                formatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _contractDurationCtrl,
                placeholder: 'Thời hạn hợp đồng (tháng, VD: 12)',
                icon: CupertinoIcons.calendar_badge_plus,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('CHỈ SỐ BAN ĐẦU'),
              _buildInput(
                controller: _elecInitCtrl,
                placeholder: 'Chỉ số điện ban đầu',
                icon: CupertinoIcons.bolt_fill,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _waterInitCtrl,
                placeholder: 'Chỉ số nước ban đầu',
                icon: CupertinoIcons.drop_fill,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('CẤU HÌNH DỊCH VỤ DÙNG CHUNG'),
              _buildServicePoolSection(),

              const SizedBox(height: 32),
              _buildSectionTitle('THÔNG SỐ VẬT LÝ & TIỆN NGHI'),
              _buildPhysicalAttributesSection(),
              const SizedBox(height: 16),
              _buildFurnitureSection(),

              const SizedBox(height: 32),
              _buildSectionTitle('HÌNH ẢNH PHÒNG'),
              _buildImagePicker(),

              const SizedBox(height: 48),

              GestureDetector(
                onTapDown: (_) => _btnAnimCtrl.forward(),
                onTapUp: (_) {
                  unawaited(_btnAnimCtrl.reverse());
                  unawaited(_submit());
                },
                onTapCancel: () => _btnAnimCtrl.reverse(),
                child: ScaleTransition(
                  scale: _btnScaleAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.kBrand,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kBrand.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Xác Nhận Thêm Phòng',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        placeholderStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w400,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(icon, color: AppTheme.kBrand, size: 20),
        ),
        decoration: null,
      ),
    );
  }

  Widget _buildBranchSelector() {
    return GestureDetector(
      onTap: _showBranchPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.building_2_fill,
              color: AppTheme.kBrand,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedBranchName ?? "Chọn Dãy Trọ...",
                style: TextStyle(
                  color: _selectedBranchName == null
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF111827),
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _pickImages,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.kBrand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.kBrand.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.photo_on_rectangle,
                  color: AppTheme.kBrand,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Thêm Ảnh",
                  style: TextStyle(
                    color: AppTheme.kBrand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_imagePaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: getResponsiveFileImageProvider(
                            _imagePaths[index],
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imagePaths.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: CupertinoColors.systemRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      int remaining =
          5 - _imagePaths.length; // Assuming max 5 images for a room
      if (remaining <= 0) return;

      unawaited(
        ImagePickerUtils.showPicker(
          context: context,
          limit: remaining,
          onPicked: (images) {
            if (images.isNotEmpty) {
              setState(() {
                for (var img in images) {
                  if (!_imagePaths.contains(img.path) &&
                      _imagePaths.length < 5) {
                    _imagePaths.add(img.path);
                  }
                }
              });
            }
          },
        ),
      );
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  void _showBranchPicker() {
    final branchesState = ref.watch(branchProvider);
    final branches = branchesState.value ?? [];
    if (branches.isEmpty) {
      _showDialog(
        "Lỗi",
        "Bạn chưa có dãy trọ nào. Vui lòng thêm dãy trọ trước!",
      );
      return;
    }

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 250,
          color: CupertinoColors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: const Color(0xFFF3F4F6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text("Hủy"),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const Text(
                      "Chọn dãy trọ",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    CupertinoButton(
                      child: const Text("Xong"),
                      onPressed: () {
                        if (_selectedBranchId == null && branches.isNotEmpty) {
                          setState(() {
                            _selectedBranchId = branches[0].id;
                            _selectedBranchName = branches[0].branchName;
                            _selectedBranchCode =
                                branches[0].branchCode ??
                                IdentifierUtils.generateFallbackBranchCode(
                                  branches[0].id,
                                );
                            _autoRoomCode =
                                _selectedBranchCode != null &&
                                    _nameCtrl.text.isNotEmpty
                                ? IdentifierUtils.buildRoomFullCode(
                                    branchFullCode: _selectedBranchCode!,
                                    roomName: _nameCtrl.text,
                                  )
                                : "";
                          });
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedBranchId = branches[index].id;
                      _selectedBranchName = branches[index].branchName;
                      _selectedBranchCode =
                          branches[index].branchCode ??
                          IdentifierUtils.generateFallbackBranchCode(
                            branches[index].id,
                          );
                      // Recalculate room code with new branch
                      _autoRoomCode =
                          _selectedBranchCode != null &&
                              _nameCtrl.text.isNotEmpty
                          ? IdentifierUtils.buildRoomFullCode(
                              branchFullCode: _selectedBranchCode!,
                              roomName: _nameCtrl.text,
                            )
                          : "";
                    });
                  },
                  children: branches
                      .map((b) => Center(child: Text(b.branchName)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedBranchId == null) {
      _showDialog("Lỗi", "Vui lòng chọn dãy trọ.");
      return;
    }
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      _showDialog("Lỗi", "Vui lòng nhập Tên phòng và Giá thuê.");
      return;
    }

    setState(() => _isLoading = true);

    final description = jsonEncode({
      "elecInit": _elecInitCtrl.text,
      "waterInit": _waterInitCtrl.text,
    });
    final price =
        double.tryParse(
          _priceCtrl.text.replaceAll(',', '').replaceAll('.', ''),
        ) ??
        0.0;

    try {
      await ref.read(roomProvider.notifier).createRoom({
        "branchId": _selectedBranchId,
        "roomCode": _autoRoomCode,
        "roomName": _nameCtrl.text,
        "floor": int.tryParse(_floorCtrl.text),
        "floorArea": double.tryParse(_floorAreaCtrl.text),
        "mezzanineArea": double.tryParse(_mezzanineAreaCtrl.text),
        'maxGuests': int.tryParse(_maxGuestsCtrl.text) ?? 2,
        'maxVehicles': int.tryParse(_maxVehiclesCtrl.text) ?? 2,
        'price': price,
        'baseDeposit': double.tryParse(_baseDepositCtrl.text),
        'contractDurationMonths':
            int.tryParse(_contractDurationCtrl.text) ?? 12,
        'status': 'TRONG',
        'description': description,
        'hasPrivateMeter': _hasPrivateMeter,
        'bathroomType': _bathroomType,
        'direction': _direction,
        'hasBalcony': _hasBalcony,
        'hasWindow': _hasWindow,
        'furniture': _selectedFurniture.toList(),
        if (_selectedPoolIds.isNotEmpty) 'poolIds': _selectedPoolIds.toList(),
      }, imagePaths: _imagePaths);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Fix: dùng mounted thay vì context.mounted để thoả mãn use_build_context_synchronously
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('Giới hạn phòng') ||
          errStr.contains('room limit') ||
          errStr.contains('giới hạn')) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Đạt giới hạn gói'),
              content: Text(errStr.replaceFirst('Exception: ', '')),
              actions: [
                CupertinoDialogAction(
                  child: const Text(
                    'Để sau',
                    style: TextStyle(color: AppTheme.kTextSecondary),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    'Nâng cấp ngay',
                    style: TextStyle(color: CupertinoColors.activeBlue),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(context.push('/subscription-management'));
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        _showDialog('Lỗi', errStr);
      }
      return;
    }

    // Refresh branch list to show updated counts if any
    await ref.read(branchProvider.notifier).refreshBranches();

    if (mounted) setState(() => _isLoading = false);

    final user = ref.read(authProvider).value;
    final isStaff = user?.role == 'STAFF';
    final message = isStaff
        ? 'Phòng trọ mới đã được thêm và đang ở trạng thái CHỜ DUYỆT. Vui lòng báo quản lý duyệt để hiển thị trên ứng dụng.'
        : 'Phòng trọ mới đã được thêm thành công!';

    _showDialog(
      'Thành công',
      message,
      onSuccess: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showDialog(String title, String message, {VoidCallback? onSuccess}) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
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

  // ─€─€ Service Pool UI Section ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildServicePoolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle: Công tơ riêng vs Dùng chung
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'š¡ Điện nước',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  CupertinoSlidingSegmentedControl<bool>(
                    groupValue: _hasPrivateMeter,
                    backgroundColor: const Color(0xFFF3F4F6),
                    thumbColor: CupertinoColors.white,
                    children: const {
                      true: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          '🔌 Công tơ riêng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      false: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          '🏢 Dùng chung',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) {
                        setState(() => _hasPrivateMeter = val);
                        if (!val &&
                            _selectedBranchId != null &&
                            _availablePools.isEmpty) {
                          unawaited(_loadPools(_selectedBranchId!));
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _hasPrivateMeter
                    ? 'Phòng có công tơ điện/nước riêng. Hệ thống chốt theo chỉ số thực tế.'
                    : 'Phòng dùng chung đồng hồ tầng. Tiền điện/nước tính theo Pool bên dưới.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),

        // Pool multi-selector (chỉ hiện khi dùng chung)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: !_hasPrivateMeter
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.square_grid_2x2_fill,
                              color: Color(0xFF6366F1),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Chọn Nhóm Dịch Vụ (Pool)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const Spacer(),
                            if (_loadingPools)
                              const CupertinoActivityIndicator(radius: 8),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chọn tất cả Pool mà phòng này tham gia (có thể chọn nhiều)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_availablePools.isEmpty && !_loadingPools)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF9500,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFFF9500,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text('š ï¸', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dãy trọ này chưa có Pool nào. Hãy tạo Pool trước trong “Nhóm Dịch Vụ”.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFF9500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availablePools.map((pool) {
                              // BUGFIX (data): `id` có thể là String/null.
                              final rawId = pool['id'];
                              final id = rawId is num
                                  ? rawId.toInt()
                                  : int.tryParse(rawId?.toString() ?? '') ?? 0;
                              final name = pool['name']?.toString() ?? '';
                              final type =
                                  pool['serviceType']?.toString() ?? 'OTHER';
                              final icon = _iconForType(type);
                              final selected = _selectedPoolIds.contains(id);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedPoolIds.remove(id);
                                  } else {
                                    _selectedPoolIds.add(id);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF6366F1)
                                        : CupertinoColors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFFE5E7EB),
                                      width: selected ? 1.5 : 1,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF6366F1,
                                              ).withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (selected)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: CupertinoColors.white,
                                            size: 13,
                                          ),
                                        ),
                                      Text(
                                        '$icon $name',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: selected
                                              ? CupertinoColors.white
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        if (_selectedPoolIds.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.kSuccess.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'œ… Đã chọn ${_selectedPoolIds.length} Pool. Hóa đơn sẽ tự động tính phiếu theo từng Pool.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.kSuccess,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  static String _iconForType(String type) {
    const map = {
      'ELECTRICITY': '⚡',
      'WATER': '💧',
      'CLEANING': '🧹',
      'ELEVATOR': '🛗',
      'WIFI': '📶',
      'OTHER': '📦',
    };
    return map[type] ?? '📦';
  }

  // ─€─€ Room Name Input (auto-gen code) ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildRoomNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CupertinoTextField(
            controller: _nameCtrl,
            placeholder: 'Tên / Số phòng (VD: 101, A02)',
            maxLength: 20,
            keyboardType: TextInputType.text,
            placeholderStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Icon(
                CupertinoIcons.number_square_fill,
                color: AppTheme.kAccentColor,
                size: 19,
              ),
            ),
            decoration: null,
            onChanged: (val) {
              setState(() {
                if (_selectedBranchCode != null && val.isNotEmpty) {
                  _autoRoomCode = IdentifierUtils.buildRoomFullCode(
                    branchFullCode: _selectedBranchCode!,
                    roomName: val,
                  );
                } else {
                  _autoRoomCode = '';
                }
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 6),
            child: Text(
              '${_nameCtrl.text.length}/20',
              style: TextStyle(
                fontSize: 11,
                color: _nameCtrl.text.length >= 20
                    ? CupertinoColors.systemRed
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─€─€ Physical Attributes section UI ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildPhysicalAttributesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Nhà vệ sinh
          _buildFormRow(
            icon: CupertinoIcons.wind,
            label: 'Nhà vệ sinh:',
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _bathroomType,
              backgroundColor: const Color(0xFFF3F4F6),
              thumbColor: CupertinoColors.white,
              children: const {
                'RIENG': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'Khép kín',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                'CHUNG': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'Chung',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _bathroomType = val);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Hướng phòng
          _buildFormRow(
            icon: CupertinoIcons.compass,
            label: 'Hướng phòng:',
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _direction,
              backgroundColor: const Color(0xFFF3F4F6),
              thumbColor: CupertinoColors.white,
              children: const {
                'DONG': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Đông', style: TextStyle(fontSize: 11)),
                ),
                'TAY': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Tây', style: TextStyle(fontSize: 11)),
                ),
                'NAM': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Nam', style: TextStyle(fontSize: 11)),
                ),
                'BAC': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Bắc', style: TextStyle(fontSize: 11)),
                ),
                'DONG_NAM': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Đông Nam', style: TextStyle(fontSize: 11)),
                ),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _direction = val);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Ban công & Cửa sổ
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sun_max,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ban công',
                      style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                    ),
                    const Spacer(),
                    CupertinoSwitch(
                      value: _hasBalcony,
                      onChanged: (val) => setState(() => _hasBalcony = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sidebar_left,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Cửa sổ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                    ),
                    const Spacer(),
                    CupertinoSwitch(
                      value: _hasWindow,
                      onChanged: (val) => setState(() => _hasWindow = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─€─€ Furniture multi-select section UI ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildFurnitureSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.bed_double_fill,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              SizedBox(width: 8),
              Text(
                'Trang bị tiện nghi nội thất:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _furniturePresets.map((item) {
              final isSelected = _selectedFurniture.contains(item['key']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFurniture.remove(item['key']);
                    } else {
                      _selectedFurniture.add(item['key']!);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEEF2FF)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : CupertinoColors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['emoji']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
        child,
      ],
    );
  }

  // ─€─€ Room Code Preview badge ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildRoomCodePreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.barcode,
            color: Color(0xFF16A34A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Mã phòng đầy đủ (tự động):',
                  style: TextStyle(color: Color(0xFF15803D), fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  _autoRoomCode,
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

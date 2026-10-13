import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/meter_reading_notifier.dart';
import '../data/models/meter_reading_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../core/components/app_error_widget.dart';
import '../../staff/presentation/widgets/ai_ocr_scanner_modal.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class BatchMeterReadingScreen extends ConsumerStatefulWidget {
  final int branchId;

  const BatchMeterReadingScreen({super.key, required this.branchId});

  @override
  ConsumerState<BatchMeterReadingScreen> createState() =>
      _BatchMeterReadingScreenState();
}

class _BatchMeterReadingScreenState
    extends ConsumerState<BatchMeterReadingScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // ── Đồng hồ Tổng (ServicePool) ──────────────────────────────────────────
  final _poolElecCtrl = TextEditingController();
  final _poolWaterCtrl = TextEditingController();

  bool _showPoolSection = false;

  // Controllers map: roomId -> Map<type, TextEditingController>
  final Map<int, Map<String, TextEditingController>> _controllers = {};

  // Images map: roomId -> Map<type, String> (Base64)
  final Map<int, Map<String, String>> _images = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _poolElecCtrl.dispose();
    _poolWaterCtrl.dispose();
    for (var roomControllers in _controllers.values) {
      roomControllers['elec']?.dispose();
      roomControllers['water']?.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(
    int roomId,
    String type,
    double? initialValue,
  ) {
    _controllers[roomId] ??= {};
    if (!_controllers[roomId]!.containsKey(type)) {
      _controllers[roomId]![type] = TextEditingController(
        text: initialValue?.toString() ?? '',
      );
    }
    return _controllers[roomId]![type]!;
  }

  Future<void> _pickImage(int roomId, String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        imageQuality: 50,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _images[roomId] ??= {};
          _images[roomId]![type] = 'data:image/jpeg;base64,$base64String';
        });
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi Camera'),
              content: Text('Không thể chụp ảnh: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveAll(List<MeterReadingModel> readings) async {
    final notifier = ref.read(
      meterReadingProvider(
        widget.branchId,
        _selectedMonth,
        _selectedYear,
      ).notifier,
    );

    // unawaited(Show loading dialog)
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) =>
            const Center(child: CupertinoActivityIndicator(radius: 20)),
      ),
    );

    try {
      for (final r in readings) {
        final elecText = _controllers[r.roomId]?['elec']?.text.trim();
        final waterText = _controllers[r.roomId]?['water']?.text.trim();

        double? elec = elecText != null && elecText.isNotEmpty
            ? double.tryParse(elecText)
            : null;
        double? water = waterText != null && waterText.isNotEmpty
            ? double.tryParse(waterText)
            : null;
        String? elecImg = _images[r.roomId]?['elec'];
        String? waterImg = _images[r.roomId]?['water'];

        if (elec != null || water != null) {
          await notifier.updateUtilitiesByRoom(
            r.roomId,
            elec,
            water,
            electricImage: elecImg,
            waterImage: waterImg,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context); // unawaited(pop loading)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: const Text('Đã lưu tất cả chỉ số điện nước.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // unawaited(pop loading)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể lưu: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _generateDrafts() async {
    final notifier = ref.read(
      meterReadingProvider(
        widget.branchId,
        _selectedMonth,
        _selectedYear,
      ).notifier,
    );

    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) =>
            const Center(child: CupertinoActivityIndicator(radius: 20)),
      ),
    );

    try {
      await notifier.generateBills();
      if (mounted) {
        Navigator.pop(context); // unawaited(pop loading)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: const Text(
                'Đã tạo hóa đơn nháp cho tất cả các phòng đang có khách thuê.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // unawaited(pop loading)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể tạo hóa đơn nháp: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportCsv(List<MeterReadingModel> readings) async {
    try {
      final rentedRooms = readings
          .where((r) => r.currentTenantId != null)
          .toList();
      if (rentedRooms.isEmpty) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thông báo'),
              content: const Text(
                'Không có dữ liệu phòng đang thuê để xuất CSV.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
        return;
      }

      final buffer = StringBuffer();
      // CSV Header (BOM for Excel UTF-8 support)
      buffer.write('\uFEFF');
      buffer.writeln(
        'Phòng,Chỉ số điện cũ,Chỉ số điện mới,Tiêu thụ điện,Chỉ số nước cũ,Chỉ số nước mới,Tiêu thụ nước',
      );

      for (final r in rentedRooms) {
        final elecText =
            _controllers[r.roomId]?['elec']?.text.trim() ??
            r.electricCurrent?.toString() ??
            '';
        final waterText =
            _controllers[r.roomId]?['water']?.text.trim() ??
            r.waterCurrent?.toString() ??
            '';

        final elecCurrent = double.tryParse(elecText) ?? r.electricCurrent ?? 0;
        final waterCurrent = double.tryParse(waterText) ?? r.waterCurrent ?? 0;

        final elecConsumed = (elecCurrent > 0)
            ? elecCurrent - r.electricPrevious
            : 0;
        final waterConsumed = (waterCurrent > 0)
            ? waterCurrent - r.waterPrevious
            : 0;

        buffer.writeln(
          '${r.roomName},${r.electricPrevious},$elecCurrent,$elecConsumed,${r.waterPrevious},$waterCurrent,$waterConsumed',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/Chot_Dien_Nuoc_Thang_${_selectedMonth}_$_selectedYear.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: Text('Đã xuất file CSV tại:\n$path'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Mở file'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(OpenFile.open(path));
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi xuất file'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(
      meterReadingProvider(widget.branchId, _selectedMonth, _selectedYear),
    );

    return LiquidGlassScaffold(
      title: 'Chốt Điện Nước',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false, // Prevents Column from having unbounded height
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(
              CupertinoIcons.square_arrow_up,
              color: CupertinoColors.black,
              size: 24,
            ),
            onPressed: () {
              final val = ref.read(
                meterReadingProvider(
                  widget.branchId,
                  _selectedMonth,
                  _selectedYear,
                ),
              );
              if (val.hasValue) unawaited(_exportCsv(val.value!));
            },
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(
              CupertinoIcons.clear_circled_solid,
              color: CupertinoColors.black,
              size: 28,
            ),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tháng/Năm:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.minus_circle,
                          color: CupertinoColors.systemBlue,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 1) {
                              _selectedMonth = 12;
                              _selectedYear--;
                            } else {
                              _selectedMonth--;
                            }
                          });
                        },
                      ),
                      Text(
                        '$_selectedMonth/$_selectedYear',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.add_circled,
                          color: CupertinoColors.systemBlue,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 12) {
                              _selectedMonth = 1;
                              _selectedYear++;
                            } else {
                              _selectedMonth++;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: readingsAsync.when(
              data: (readings) {
                final rentedRooms = readings
                    .where((r) => r.currentTenantId != null)
                    .toList();

                if (rentedRooms.isEmpty) {
                  return const Center(
                    child: Text('Không có phòng nào đang có khách thuê.'),
                  );
                }

                return Column(
                  children: [
                    // ── Section: Đồng hồ Tổng Tầng/Tòa ─────────────────
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showPoolSection = !_showPoolSection),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: 0.12),
                              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.building_2_fill,
                              color: Color(0xFF6366F1),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Đồng hồ Tổng Tầng / Tòa (Dịch vụ chung)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                            Icon(
                              _showPoolSection
                                  ? CupertinoIcons.chevron_up
                                  : CupertinoIcons.chevron_down,
                              color: const Color(0xFF6366F1),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: _showPoolSection
                          ? Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📋 Nhập chỉ số đồng hồ TỔNG của tầng/tòa để hệ thống tự phân bổ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '⚡ Điện Tổng (kWh)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF4B5563),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            CupertinoTextField(
                                              controller: _poolElecCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              placeholder: 'VD: 500',
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF9FAFB),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF6366F1,
                                                  ).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '💧 Nước Tổng (m³)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF4B5563),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            CupertinoTextField(
                                              controller: _poolWaterCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              placeholder: 'VD: 30',
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF9FAFB),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF6366F1,
                                                  ).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Preview phân bổ
                                  if (_poolElecCtrl.text.isNotEmpty ||
                                      _poolWaterCtrl.text.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '📊 Preview phân bổ (Chia đều theo số phòng)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Builder(
                                            builder: (_) {
                                              final elecTotal =
                                                  double.tryParse(
                                                    _poolElecCtrl.text,
                                                  ) ??
                                                  0;
                                              final waterTotal =
                                                  double.tryParse(
                                                    _poolWaterCtrl.text,
                                                  ) ??
                                                  0;
                                              final roomCount =
                                                  rentedRooms.length;
                                              final elecPerRoom = roomCount > 0
                                                  ? elecTotal / roomCount
                                                  : 0;
                                              final waterPerRoom = roomCount > 0
                                                  ? waterTotal / roomCount
                                                  : 0;
                                              return Column(
                                                children: [
                                                  if (elecTotal > 0)
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          '⚡',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '$elecTotal kWh ÷ $roomCount phòng = ${elecPerRoom.toStringAsFixed(1)} kWh/phòng',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(
                                                                  0xFF10B981,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  if (waterTotal > 0) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          '💧',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '$waterTotal m³ ÷ $roomCount phòng = ${waterPerRoom.toStringAsFixed(1)} m³/phòng',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(
                                                                  0xFF10B981,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 4),
                    // ── Section: Chỉ số từng Phòng ────────────────────────
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: rentedRooms.length,
                        itemBuilder: (context, index) {
                          final r = rentedRooms[index];
                          final isRented = r.currentTenantId != null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        r.roomName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isRented
                                              ? CupertinoColors.systemGreen
                                                    .withValues(alpha: 0.2)
                                              : CupertinoColors.systemGrey
                                                    .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          isRented ? 'Có khách' : 'Trống',
                                          style: TextStyle(
                                            color: isRented
                                                ? CupertinoColors.systemGreen
                                                : CupertinoColors.systemGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isRented) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Điện (Cũ: ${r.electricPrevious})',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF4B5563),
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () async {
                                                          final val =
                                                              await AiOcrScannerModal.show(
                                                                context,
                                                                title:
                                                                    'Quét Số Điện P.${r.roomName}',
                                                              );
                                                          if (val != null) {
                                                            _getController(
                                                              r.roomId,
                                                              'elec',
                                                              r.electricCurrent,
                                                            ).text = val
                                                                .toStringAsFixed(
                                                                  0,
                                                                );
                                                          }
                                                        },
                                                        minimumSize: const Size(
                                                          0,
                                                          0,
                                                        ),
                                                        child: const Icon(
                                                          CupertinoIcons
                                                              .camera_viewfinder,
                                                          size: 18,
                                                          color: AppTheme
                                                              .kAccentColor,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () =>
                                                            _pickImage(
                                                              r.roomId,
                                                              'elec',
                                                            ),
                                                        minimumSize: const Size(
                                                          0,
                                                          0,
                                                        ),
                                                        child: Icon(
                                                          _images[r.roomId]?['elec'] !=
                                                                  null
                                                              ? CupertinoIcons
                                                                    .check_mark_circled_solid
                                                              : CupertinoIcons
                                                                    .photo_camera_solid,
                                                          size: 18,
                                                          color:
                                                              _images[r
                                                                      .roomId]?['elec'] !=
                                                                  null
                                                              ? CupertinoColors
                                                                    .systemGreen
                                                              : CupertinoColors
                                                                    .systemGrey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              CupertinoTextField(
                                                controller: _getController(
                                                  r.roomId,
                                                  'elec',
                                                  r.electricCurrent,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                textInputAction:
                                                    TextInputAction.next,
                                                placeholder: 'Số mới',
                                                style: const TextStyle(
                                                  color: CupertinoColors.black,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: (() {
                                                      final text =
                                                          _getController(
                                                            r.roomId,
                                                            'elec',
                                                            r.electricCurrent,
                                                          ).text;
                                                      final newVal =
                                                          double.tryParse(text);
                                                      final oldVal =
                                                          r.electricPrevious;
                                                      if (newVal != null) {
                                                        if (newVal < oldVal) {
                                                          return CupertinoColors
                                                              .systemRed;
                                                        }
                                                        if ((newVal - oldVal) >
                                                            100) {
                                                          return CupertinoColors
                                                              .systemOrange; // Mock spike
                                                        }
                                                      }
                                                      return const Color(
                                                        0xFFE5E7EB,
                                                      );
                                                    })(),
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  color: CupertinoColors.white,
                                                ),
                                                onChanged: (val) =>
                                                    setState(() {}),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Nước (Cũ: ${r.waterPrevious})',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF4B5563),
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () async {
                                                          final val =
                                                              await AiOcrScannerModal.show(
                                                                context,
                                                                title:
                                                                    'Quét Số Nước P.${r.roomName}',
                                                              );
                                                          if (val != null) {
                                                            _getController(
                                                              r.roomId,
                                                              'water',
                                                              r.waterCurrent,
                                                            ).text = val
                                                                .toStringAsFixed(
                                                                  0,
                                                                );
                                                          }
                                                        },
                                                        minimumSize: const Size(
                                                          0,
                                                          0,
                                                        ),
                                                        child: const Icon(
                                                          CupertinoIcons
                                                              .camera_viewfinder,
                                                          size: 18,
                                                          color: AppTheme
                                                              .kAccentColor,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () =>
                                                            _pickImage(
                                                              r.roomId,
                                                              'water',
                                                            ),
                                                        minimumSize: const Size(
                                                          0,
                                                          0,
                                                        ),
                                                        child: Icon(
                                                          _images[r.roomId]?['water'] !=
                                                                  null
                                                              ? CupertinoIcons
                                                                    .check_mark_circled_solid
                                                              : CupertinoIcons
                                                                    .photo_camera_solid,
                                                          size: 18,
                                                          color:
                                                              _images[r
                                                                      .roomId]?['water'] !=
                                                                  null
                                                              ? CupertinoColors
                                                                    .systemGreen
                                                              : CupertinoColors
                                                                    .systemGrey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              CupertinoTextField(
                                                controller: _getController(
                                                  r.roomId,
                                                  'water',
                                                  r.waterCurrent,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                textInputAction:
                                                    TextInputAction.next,
                                                placeholder: 'Số mới',
                                                style: const TextStyle(
                                                  color: CupertinoColors.black,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: (() {
                                                      final text =
                                                          _getController(
                                                            r.roomId,
                                                            'water',
                                                            r.waterCurrent,
                                                          ).text;
                                                      final newVal =
                                                          double.tryParse(text);
                                                      final oldVal =
                                                          r.waterPrevious;
                                                      if (newVal != null) {
                                                        if (newVal < oldVal) {
                                                          return CupertinoColors
                                                              .systemRed;
                                                        }
                                                        if ((newVal - oldVal) >
                                                            20) {
                                                          return CupertinoColors
                                                              .systemOrange; // Mock spike
                                                        }
                                                      }
                                                      return const Color(
                                                        0xFFE5E7EB,
                                                      );
                                                    })(),
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  color: CupertinoColors.white,
                                                ),
                                                onChanged: (val) =>
                                                    setState(() {}),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GlassButton(
                                  text: 'Chốt Số Hàng Loạt (Batch)',
                                  icon: CupertinoIcons.paperplane_fill,
                                  color: CupertinoColors.systemBlue,
                                  onPressed: () {
                                    // Gửi request tới /v1/bills/batch-generate
                                    unawaited(
                                      _generateDrafts(),
                                    ); // Currently mapped to generateBills
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GlassButton(
                                  text: 'Lưu Bản Nháp Chỉ Số',
                                  icon: CupertinoIcons.check_mark_circled,
                                  color: CupertinoColors.systemGreen,
                                  onPressed: () => _saveAll(readings),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, _) => AppErrorWidget(error: err),
            ),
          ),
        ],
      ),
    );
  }
}

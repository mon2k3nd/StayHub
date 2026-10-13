import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../branch/application/branch_notifier.dart';
import '../../bill/application/meter_reading_notifier.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/toast_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class RecordUtilitiesScreen extends ConsumerStatefulWidget {
  const RecordUtilitiesScreen({super.key});

  @override
  ConsumerState<RecordUtilitiesScreen> createState() =>
      _RecordUtilitiesScreenState();
}

class _RecordUtilitiesScreenState extends ConsumerState<RecordUtilitiesScreen> {
  int? _selectedBranchId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final Map<int, TextEditingController> _elecControllers = {};
  final Map<int, TextEditingController> _waterControllers = {};
  final Map<int, XFile?> _elecImages = {};
  final Map<int, XFile?> _waterImages = {};

  bool _isSubmitting = false;

  @override
  void dispose() {
    for (var c in _elecControllers.values) {
      c.dispose();
    }
    for (var c in _waterControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitAll() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      int successCount = 0;
      int errorCount = 0;

      for (final roomId in _elecControllers.keys) {
        final elecText = _elecControllers[roomId]?.text ?? '';
        final waterText = _waterControllers[roomId]?.text ?? '';

        if (elecText.isNotEmpty || waterText.isNotEmpty) {
          final elecVal = double.tryParse(elecText);
          final waterVal = double.tryParse(waterText);

          // Bug fix: đọc file rồi base64 encode thay vì gửi raw path
          String? elecImgB64;
          String? waterImgB64;
          final elecFile = _elecImages[roomId];
          final waterFile = _waterImages[roomId];
          if (elecFile != null) {
            try {
              final bytes = await elecFile.readAsBytes();
              elecImgB64 = base64Encode(bytes);
            } catch (_) {}
          }
          if (waterFile != null) {
            try {
              final bytes = await waterFile.readAsBytes();
              waterImgB64 = base64Encode(bytes);
            } catch (_) {}
          }

          try {
            await dio.put(
              '/v1/bills/room/$roomId/utilities',
              data: {
                if (elecVal != null) 'electricCurrent': elecVal,
                if (waterVal != null) 'waterCurrent': waterVal,
                if (elecImgB64 != null) 'electricImage': elecImgB64,
                if (waterImgB64 != null) 'waterImage': waterImgB64,
              },
            );
            successCount++;
          } catch (e) {
            errorCount++;
          }
        }
      }

      if (!mounted) return;

      final msg = errorCount > 0
          ? 'Đã lưu $successCount phòng, lỗi $errorCount phòng.'
          : 'Đã lưu điện nước $successCount phòng thành công.';
      ToastUtils.show(context, msg);
      // Bug fix: luôn invalidate để refresh UI, không chỉ khi errorCount == 0
      if (_selectedBranchId != null) {
        ref.invalidate(
          meterReadingProvider(
            _selectedBranchId!,
            _selectedMonth,
            _selectedYear,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _generateBills() async {
    if (_isSubmitting || _selectedBranchId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/v1/bills/generate',
        data: {
          'branchId': _selectedBranchId,
          'month': _selectedMonth,
          'year': _selectedYear,
        },
      );

      if (!mounted) return;

      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Thành công'),
            content: Text(
              'Đã tạo hóa đơn cho tháng $_selectedMonth/$_selectedYear! Các phòng đã chốt điện nước sẽ tự động lên hóa đơn.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Đóng'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.invalidate(
                    meterReadingProvider(
                      _selectedBranchId!,
                      _selectedMonth,
                      _selectedYear,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ToastUtils.show(context, 'Lỗi tạo hóa đơn: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesState = ref.watch(branchProvider);

    return LiquidGlassScaffold(
      title: 'Chốt Số Nhanh',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _selectedBranchId == null || _isSubmitting
            ? null
            : _submitAll,
        child: const Text(
          'Lưu Nhanh',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.kBrand),
        ),
      ),
      child: branchesState.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, _) => AppErrorWidget(error: err),
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(child: Text('Bạn chưa có dãy trọ nào.'));
          }
          if (_selectedBranchId == null && branches.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedBranchId = branches.first.id;
              });
            });
          }

          return Column(
            children: [
              // Filter bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: CupertinoColors.white,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _showBranchPicker(branches),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.kTextMuted),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  branches
                                      .firstWhere(
                                        (b) => b.id == _selectedBranchId,
                                        orElse: () => branches.first,
                                      )
                                      .branchName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                  ),
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                                color: AppTheme.kTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _showMonthYearPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.kTextMuted),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'T$_selectedMonth/$_selectedYear',
                                style: const TextStyle(
                                  color: CupertinoColors.black,
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                                color: AppTheme.kTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.kBackgroundLight,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Phòng',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Điện mới (kWh)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kBrand,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Nước mới (m³)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kBrand,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedBranchId == null
                    ? const SizedBox()
                    : _buildMeterReadingsList(),
              ),
              if (_selectedBranchId != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: AppTheme.kBrand,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _isSubmitting ? null : _generateBills,
                        child: _isSubmitting
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text(
                                'Tạo Hóa Đơn Tự Động',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMeterReadingsList() {
    final meterReadingsAsync = ref.watch(
      meterReadingProvider(_selectedBranchId!, _selectedMonth, _selectedYear),
    );

    return meterReadingsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, _) => AppErrorWidget(error: err),
      data: (readings) {
        if (readings.isEmpty) {
          return const Center(
            child: Text(
              'Không có phòng nào đang thuê trong dãy này.',
              style: TextStyle(color: AppTheme.kTextSecondary),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: readings.length,
          itemBuilder: (context, index) {
            final reading = readings[index];
            _elecControllers.putIfAbsent(
              reading.roomId,
              () => TextEditingController(
                text: reading.electricCurrent?.toString() ?? '',
              ),
            );
            _waterControllers.putIfAbsent(
              reading.roomId,
              () => TextEditingController(
                text: reading.waterCurrent?.toString() ?? '',
              ),
            );

            return _buildGridRow(
              reading,
              _elecControllers[reading.roomId]!,
              _waterControllers[reading.roomId]!,
              index,
            );
          },
        );
      },
    );
  }

  Widget _buildGridRow(
    dynamic reading,
    TextEditingController elecCtrl,
    TextEditingController waterCtrl,
    int index,
  ) {
    final prevElec = reading.electricPrevious?.toString() ?? '0';
    final prevWater = reading.waterPrevious?.toString() ?? '0';
    final roomId = reading.roomId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? CupertinoColors.white : AppTheme.kBackgroundLight,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  reading.roomName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prevElec,
                        style: const TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        CupertinoIcons.arrow_right,
                        size: 10,
                        color: AppTheme.kTextSecondary,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CupertinoTextField(
                        controller: elecCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        padding: const EdgeInsets.all(8),
                        placeholder: 'Nhập',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.kBrand,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prevWater,
                        style: const TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        CupertinoIcons.arrow_right,
                        size: 10,
                        color: AppTheme.kTextSecondary,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CupertinoTextField(
                        controller: waterCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        padding: const EdgeInsets.all(8),
                        placeholder: 'Nhập',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.kBrand,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 50,
                  );
                  if (img != null) {
                    setState(() => _elecImages[roomId] = img);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.camera_fill,
                      size: 16,
                      color: _elecImages[roomId] != null
                          ? CupertinoColors.systemGreen
                          : AppTheme.kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _elecImages[roomId] != null ? 'Ảnh điện' : 'Chụp điện',
                      style: TextStyle(
                        fontSize: 12,
                        color: _elecImages[roomId] != null
                            ? CupertinoColors.systemGreen
                            : AppTheme.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 50,
                  );
                  if (img != null) {
                    setState(() => _waterImages[roomId] = img);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.camera_fill,
                      size: 16,
                      color: _waterImages[roomId] != null
                          ? CupertinoColors.systemGreen
                          : AppTheme.kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _waterImages[roomId] != null ? 'Ảnh nước' : 'Chụp nước',
                      style: TextStyle(
                        fontSize: 12,
                        color: _waterImages[roomId] != null
                            ? CupertinoColors.systemGreen
                            : AppTheme.kTextSecondary,
                      ),
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

  void _showBranchPicker(List<dynamic> branches) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: CupertinoColors.white,
          child: Column(
            children: [
              SizedBox(
                height: 190,
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: branches.indexWhere(
                      (b) => b.id == _selectedBranchId,
                    ),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() => _selectedBranchId = branches[index].id);
                  },
                  children: branches
                      .map((b) => Center(child: Text(b.branchName)))
                      .toList(),
                ),
              ),
              CupertinoButton(
                child: const Text('Xong'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthYearPicker() {
    // A simple picker for month (1-12) and year (e.g. 2023-2030)
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: CupertinoColors.white,
          child: Column(
            children: [
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: tempMonth - 1,
                        ),
                        onSelectedItemChanged: (index) => tempMonth = index + 1,
                        children: List.generate(
                          12,
                          (index) => Center(child: Text('Tháng ${index + 1}')),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: tempYear - 2024,
                        ),
                        onSelectedItemChanged: (index) =>
                            tempYear = index + 2024,
                        children: List.generate(
                          10,
                          (index) => Center(child: Text('${index + 2024}')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                child: const Text('Xong'),
                onPressed: () {
                  setState(() {
                    _selectedMonth = tempMonth;
                    _selectedYear = tempYear;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

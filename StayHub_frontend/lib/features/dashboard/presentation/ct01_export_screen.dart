import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../branch/application/branch_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

// ──────────────────────────────────────────────
// Screen: CT01 Export (Khai báo Tạm trú)
// ──────────────────────────────────────────────
class CT01ExportScreen extends ConsumerStatefulWidget {
  const CT01ExportScreen({super.key});

  @override
  ConsumerState<CT01ExportScreen> createState() => _CT01ExportScreenState();
}

class _CT01ExportScreenState extends ConsumerState<CT01ExportScreen> {
  int? _selectedBranchId;
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  String? _errorMsg;

  /// BUGFIX (data): danh sách người cư trú đã lọc an toàn — tránh `as List`/
  /// `as Map` ném TypeError khi `tenants` là null/không phải List hoặc phần tử
  /// không phải Map.
  List<Map<String, dynamic>> get _tenantsList {
    final raw = _reportData?['tenants'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _fetchData() async {
    if (_selectedBranchId == null) {
      setState(() => _errorMsg = 'Vui lòng chọn khu trọ!');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _reportData = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get('/v1/reports/ct01/$_selectedBranchId');
      setState(
        () => _reportData = Map<String, dynamic>.from(res.data['data'] ?? {}),
      );
    } catch (e) {
      setState(() => _errorMsg = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_reportData == null) return;
    setState(() => _isLoading = true);

    try {
      // BUGFIX (data): trước đây ép `as List` — nếu `tenants` là null/object
      // thì ném TypeError và nút xuất PDF không hoạt động. Guard an toàn.
      final rawTenants = _reportData!['tenants'];
      final tenants = rawTenants is List
          ? rawTenants
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      final branchName = 'Khu trọ ID: $_selectedBranchId';
      final exportDate = _reportData!['exportDate'] ?? '';

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'DANH SÁCH ĐĂNG KÝ TẠM TRÚ',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '(Mẫu CT01 – Theo Thông tư 56/2021/TT-BCA)',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Đơn vị: $branchName',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Ngày xuất: $exportDate',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Divider(),
            ],
          ),
          build: (ctx) => [
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _pdfCell('STT', bold: true),
                    _pdfCell('Họ và tên', bold: true),
                    _pdfCell('Số CCCD', bold: true),
                    _pdfCell('Ngày sinh', bold: true),
                    _pdfCell('Phòng', bold: true),
                    _pdfCell('Quê quán', bold: true),
                  ],
                ),
                // Data rows
                ...tenants.asMap().entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      _pdfCell('${entry.key + 1}'),
                      _pdfCell(entry.value['tenantName'] ?? ''),
                      _pdfCell(entry.value['cccdNumber'] ?? ''),
                      _pdfCell(entry.value['dateOfBirth'] ?? ''),
                      _pdfCell(entry.value['roomName'] ?? ''),
                      _pdfCell(entry.value['hometown'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Tổng số người: ${tenants.length}',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Chủ nhà / Chủ hộ',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      '(Ký và ghi rõ họ tên)',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/ct01_tamtru_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      if (mounted) setState(() => _isLoading = false);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Lỗi xuất PDF'),
              content: Text('$e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchProvider);

    return LiquidGlassScaffold(
      title: 'Khai Báo Tạm Trú (CT01)',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LiquidGlassColors.tenantAccent.withValues(alpha: 0.15),
                    LiquidGlassColors.tenantAccent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    color: LiquidGlassColors.tenantAccent,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Xuất danh sách cư trú tự động theo mẫu CT01 để nộp cho Công An Phường.',
                      style: TextStyle(
                        fontSize: 13,
                        color: LiquidGlassColors.tenantAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'CHỌN KHU TRỌ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            branchesAsync.when(
              data: (branches) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => showCupertinoModalPopup(
                    context: context,
                    builder: (_) => Container(
                      height: 250,
                      color: AppTheme.kBackgroundLight,
                      child: CupertinoPicker(
                        itemExtent: 44,
                        onSelectedItemChanged: (i) {
                          if (i < branches.length) {
                            setState(() => _selectedBranchId = branches[i].id);
                          }
                        },
                        children: branches
                            .map((b) => Center(child: Text(b.branchName)))
                            .toList(),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedBranchId != null
                            ? (branches
                                  .firstWhere(
                                    (b) => b.id == _selectedBranchId,
                                    orElse: () => branches.first,
                                  )
                                  .branchName)
                            : 'Chọn khu trọ...',
                        style: TextStyle(
                          color: _selectedBranchId != null
                              ? CupertinoColors.label
                              : AppTheme.kTextSecondary,
                          fontSize: 15,
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
              loading: () => const CupertinoActivityIndicator(),
              error: (err, st) => AppErrorWidget(error: err, compact: true),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _isLoading ? null : _fetchData,
                child: _isLoading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text('Lấy danh sách cư trú'),
              ),
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMsg!,
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
            ],

            if (_reportData != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.person_3_fill,
                    color: LiquidGlassColors.tenantAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng: ${_reportData!['totalTenants']} người cư trú',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tenant list preview
              Expanded(
                child: ListView.builder(
                  // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi
                  // `tenants` là null/không phải List hoặc phần tử không phải Map.
                  itemCount: _tenantsList.length,
                  itemBuilder: (_, i) {
                    final t = _tenantsList[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: LiquidGlassColors.tenantAccent.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: LiquidGlassColors.tenantAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['tenantName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${t['roomName'] ?? ''} • CCCD: ${t['cccdNumber']?.isNotEmpty == true ? t['cccdNumber'] : 'Chưa cập nhật'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: Colors.red,
                  onPressed: _isLoading ? null : _exportPdf,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.doc_fill,
                              color: CupertinoColors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'XUẤT PDF – NỘP CÔNG AN PHƯỜNG',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

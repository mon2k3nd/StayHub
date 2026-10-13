import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class ContractClause {
  String title;
  String content;

  ContractClause({required this.title, required this.content});

  Map<String, dynamic> toJson() => {'title': title, 'content': content};

  factory ContractClause.fromJson(Map<String, dynamic> json) => ContractClause(
    title: json['title'] ?? '',
    content: json['content'] ?? '',
  );
}

class ContractTemplateEditScreen extends ConsumerStatefulWidget {
  const ContractTemplateEditScreen({super.key});

  @override
  ConsumerState<ContractTemplateEditScreen> createState() =>
      _ContractTemplateEditScreenState();
}

class _ContractTemplateEditScreenState
    extends ConsumerState<ContractTemplateEditScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<ContractClause> _clauses = [];

  final List<ContractClause> _defaultClauses = [
    ContractClause(
      title: 'Điều 5. Quyền và nghĩa vụ của Bên cho thuê (Bên A)',
      content:
          '1. Giao nhà ở cho Bên B đúng hiện trạng và hướng dẫn sử dụng.\n2. Bảo đảm cho Bên B sử dụng ổn định trong thời hạn thuê.\n3. Bảo trì, sửa chữa nhà ở theo định kỳ; bồi thường nếu không bảo trì gây thiệt hại.\n4. Không được đơn phương chấm dứt hợp đồng khi Bên B thực hiện đúng nghĩa vụ.\n5. Thực hiện nghĩa vụ tài chính với Nhà nước theo quy định pháp luật.',
    ),
    ContractClause(
      title: 'Điều 6. Quyền và nghĩa vụ của Bên thuê (Bên B)',
      content:
          '1. Yêu cầu Bên A giao nhà đúng hiện trạng đã thỏa thuận.\n2. Bảo quản, sử dụng nhà ở đúng công năng, thiết kế.\n3. Thanh toán đủ tiền thuê theo thời hạn và phương thức đã thỏa thuận.\n4. Không được thay đổi, cải tạo, phá dỡ nếu không có sự đồng ý bằng văn bản của Bên A.\n5. Trả nhà ở cho Bên A khi hết thời hạn thuê.\n6. Bồi thường thiệt hại do lỗi của mình gây ra.',
    ),
    ContractClause(
      title: 'Điều 7. Trách nhiệm do vi phạm hợp đồng',
      content:
          '1. Bên vi phạm phải bồi thường thiệt hại cho bên còn lại theo quy định pháp luật.\n2. Trường hợp bất khả kháng (thiên tai, chiến tranh, thay đổi quy định pháp luật) không bị coi là vi phạm hợp đồng.',
    ),
    ContractClause(
      title: 'Điều 8. Các trường hợp chấm dứt hợp đồng',
      content:
          '1. Hai bên đồng ý chấm dứt hợp đồng bằng văn bản.\n2. Bên B chậm thanh toán tiền thuê quá 30 ngày.\n3. Bên A chậm bàn giao nhà ở theo thỏa thuận.\n4. Sự kiện bất khả kháng không thể khắc phục trong 90 ngày.',
    ),
    ContractClause(
      title: 'Điều 9. Giải quyết tranh chấp',
      content:
          'Mọi tranh chấp phát sinh từ hợp đồng này trước hết được giải quyết thông qua thương lượng, hòa giải giữa hai bên. Trường hợp không thể giải quyết được thì đưa ra Tòa án nhân dân có thẩm quyền theo quy định pháp luật.',
    ),
    ContractClause(
      title: 'Điều 10. Hiệu lực của hợp đồng',
      content:
          '1. Hợp đồng này có hiệu lực kể từ ngày hai bên ký kết.\n2. Hợp đồng này được lập thành 02 bản có giá trị pháp lý như nhau, mỗi bên giữ 01 bản.\n3. Các phụ lục đính kèm là nội dung không tách rời hợp đồng này.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadTemplate());
  }

  Future<void> _loadTemplate() async {
    try {
      final ownerId = ref.read(authProvider).value?.id;
      if (ownerId == null) return;

      final api = ref.read(apiClientProvider);
      final res = await api.get('/v1/owner-contract-templates/$ownerId');

      if (res['templateText'] != null &&
          res['templateText'].toString().trim().isNotEmpty) {
        final text = res['templateText'].toString();
        try {
          // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi JSON là
          // object hoặc phần tử không phải Map — lọc an toàn bằng whereType.
          final decoded = jsonDecode(text);
          _clauses = decoded is List
              ? decoded
                    .whereType<Map>()
                    .map(
                      (e) =>
                          ContractClause.fromJson(Map<String, dynamic>.from(e)),
                    )
                    .toList()
              : List.from(_defaultClauses);
        } catch (e, st) {
          debugPrint('Error: $e\n$st');
          // If not JSON, try to parse it or just use default. For now, use default to enforce the new format.
          _clauses = List.from(_defaultClauses);
        }
      } else {
        _clauses = List.from(_defaultClauses);
      }
    } catch (e) {
      debugPrint('Load template failed: $e');
      _clauses = List.from(_defaultClauses);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTemplate() async {
    // Validate
    for (var clause in _clauses) {
      if (clause.title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng nhập đầy đủ tiêu đề cho tất cả các điều khoản.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final ownerId = ref.read(authProvider).value?.id;
      if (ownerId == null) throw Exception('No owner ID');

      final String jsonString = jsonEncode(
        _clauses.map((c) => c.toJson()).toList(),
      );

      final api = ref.read(apiClientProvider);
      await api.post(
        '/v1/owner-contract-templates/$ownerId',
        data: {'templateText': jsonString},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu Mẫu Hợp Đồng thành công!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addClause() {
    setState(() {
      _clauses.add(ContractClause(title: '', content: ''));
    });
  }

  void _removeClause(int index) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa điều khoản này không?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _clauses.removeAt(index);
                });
              },
              child: const Text('Xóa'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Chỉnh Sửa Mẫu Hợp Đồng',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isSaving ? null : _saveTemplate,
        child: _isSaving
            ? const CupertinoActivityIndicator()
            : const Text(
                'Lưu',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: LiquidGlassColors.tenantAccent,
                ),
              ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: GlassContainer(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: LiquidGlassColors.tenantAccent,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Các thông tin cơ bản (Điều 1 - Điều 4) sẽ được hệ thống điền tự động. Bạn có thể tự do chỉnh sửa, thêm, bớt các quy định từ Điều 5 trở đi dưới đây.',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _clauses.length,
                    itemBuilder: (context, index) {
                      return _buildClauseCard(index);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CupertinoButton(
                        color: CupertinoColors.white.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _addClause,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.add_circled_solid,
                              color: LiquidGlassColors.tenantAccent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Thêm Điều Khoản Mới',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: LiquidGlassColors.tenantAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        color: AppTheme.kAccentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _isSaving ? null : _saveTemplate,
                        child: const Text(
                          'Lưu & Áp Dụng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildClauseCard(int index) {
    final clause = _clauses[index];

    // We use temporary controllers so the user can type without losing focus when setState triggers
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: clause.title,
                    onChanged: (val) => clause.title = val,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề điều khoản (VD: Điều 5...)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: CupertinoColors.systemGrey.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: CupertinoColors.systemGrey.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: LiquidGlassColors.tenantAccent,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                  onPressed: () => _removeClause(index),
                  tooltip: 'Xóa điều khoản',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: clause.content,
              onChanged: (val) => clause.content = val,
              maxLines: null,
              minLines: 3,
              style: const TextStyle(fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                labelText: 'Nội dung điều khoản',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: LiquidGlassColors.tenantAccent,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

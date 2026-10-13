import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/components/liquid_background.dart';
import '../application/contract_notifier.dart';
import 'contract_screen.dart';
import 'dart:async' show unawaited;

class ContractPreviewScreen extends ConsumerStatefulWidget {
  final int contractId;
  const ContractPreviewScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractPreviewScreen> createState() =>
      _ContractPreviewScreenState();
}

class _ContractPreviewScreenState extends ConsumerState<ContractPreviewScreen> {
  Map<String, dynamic>? _d;
  String? _customTerms;
  bool _isLoading = true;
  String? _error;

  // Scroll progress state
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  bool _hasReadToBottom = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadContractDetail());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      setState(() {
        _scrollProgress = progress;
        if (progress > 0.95) {
          _hasReadToBottom = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContractDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/v1/contracts/${widget.contractId}/detail');
      if (res['success'] == true && res['data'] is Map) {
        // BUGFIX (data): tránh `as Map` ném TypeError khi `data` không phải Map
        // (ví dụ List/String) — chỉ xử lý khi thực sự là Map.
        final d = Map<String, dynamic>.from(res['data'] as Map);

        // Load custom template if owner exists
        if (d['ownerId'] != null) {
          try {
            final templateRes = await api.get(
              '/v1/owner-contract-templates/${d['ownerId']}',
            );
            if (templateRes['templateText'] != null &&
                templateRes['templateText'].toString().trim().isNotEmpty) {
              _customTerms = templateRes['templateText'].toString();
            }
          } catch (e, st) {
            debugPrint('Error: $e\n$st');
          }
        }

        setState(() {
          _d = d;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Không thể tải hợp đồng';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải hợp đồng: $e';
        _isLoading = false;
      });
    }
  }

  String _s(dynamic val) =>
      (val ?? '').toString().isEmpty ? '............' : val.toString();
  String _money(dynamic val) {
    if (val == null) return '............';
    try {
      return NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
      ).format(num.parse(val.toString()));
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
      return val.toString();
    }
  }

  String _date(dynamic val) {
    if (val == null) return '.... /.... /........';
    try {
      final d = DateTime.parse(val.toString());
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
      return val.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Xem Hợp Đồng',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Color(0xFF4B5563)),
          onPressed: () => context.pop(),
        ),
        trailing: _d != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showActionMenu,
                child: const Icon(
                  CupertinoIcons.ellipsis_circle,
                  color: Color(0xFF4B5563),
                ),
              )
            : null,
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 16))
              : _error != null
              ? _buildErrorView()
              : _buildContractDocument(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
              color: CupertinoColors.systemRed,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 15),
            ),
            const SizedBox(height: 24),
            GlassButton(
              text: 'Thử lại',
              color: LiquidGlassColors.tenantAccent,
              onPressed: _loadContractDetail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractDocument() {
    final d = _d!;
    final now = DateTime.now();
    final branchAddr = _s(d['branchAddress']);
    final roomAddr = _s(d['roomAddress']);
    final address = branchAddr != '............' ? branchAddr : roomAddr;

    return Column(
      children: [
        // Thanh tiến trình đọc
        if (d['status'] == 'PENDING' &&
            d['tenantId'] == ref.read(authProvider).value?.id)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoColors.white,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _scrollProgress,
                      backgroundColor: CupertinoColors.systemGrey5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        LiquidGlassColors.tenantAccent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(_scrollProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: _scrollProgress == 1.0
                        ? LiquidGlassColors.tenantAccent
                        : CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- HEADER ----
                  const Center(
                    child: Text(
                      'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Độc lập – Tự do – Hạnh phúc',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      '________________________',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Ngày ${now.day} tháng ${now.month} năm ${now.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'HỢP ĐỒNG THUÊ NHÀ Ở',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Số: HD-${d['id'] ?? '...'}/StayHub',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legal basis
                  _p('Căn cứ Bộ luật Dân sự ngày 24 tháng 11 năm 2015;'),
                  _p(
                    'Căn cứ Luật Kinh doanh bất động sản ngày 28 tháng 11 năm 2023;',
                  ),
                  _p('Hai bên chúng tôi gồm:'),
                  const SizedBox(height: 12),

                  // ---- BÊN CHO THUÊ ----
                  _heading('I. BÊN CHO THUÊ NHÀ Ở (Bên A):'),
                  _row('Họ và tên', _s(d['ownerName'])),
                  _row('Số điện thoại', _s(d['ownerPhone'])),
                  if ((d['ownerEmail'] ?? '').toString().isNotEmpty)
                    _row('Email', _s(d['ownerEmail'])),
                  _row('Địa chỉ dãy trọ', address),
                  const SizedBox(height: 16),

                  // ---- BÊN THUÊ ----
                  _heading('II. BÊN THUÊ NHÀ Ở (Bên B):'),
                  _row('Họ và tên', _s(d['tenantName'])),
                  _row('Thẻ CCCD/CMND số', _s(d['tenantCccd'])),
                  _row('Số điện thoại', _s(d['tenantPhone'])),
                  if ((d['tenantEmail'] ?? '').toString().isNotEmpty)
                    _row('Email', _s(d['tenantEmail'])),
                  _row('Quê quán', _s(d['tenantHometown'])),
                  _row('Nghề nghiệp', _s(d['tenantOccupation'])),
                  const SizedBox(height: 8),
                  _p(
                    'Hai bên chúng tôi thống nhất ký kết hợp đồng cho thuê nhà ở với các nội dung sau đây:',
                  ),
                  const SizedBox(height: 16),

                  // ---- ĐIỀU 1 ----
                  _article('Điều 1. Các thông tin về nhà ở cho thuê'),
                  _row('Tên phòng', _s(d['roomName'])),
                  if ((d['branchName'] ?? '').toString().isNotEmpty)
                    _row('Thuộc dãy trọ', _s(d['branchName'])),
                  _row('Địa chỉ', address),
                  if ((d['roomCode'] ?? '').toString().isNotEmpty)
                    _row('Mã phòng', _s(d['roomCode'])),
                  if (d['floor'] != null) _row('Tầng', _s(d['floor'])),
                  if (d['floorArea'] != null)
                    _row('Diện tích sử dụng', '${d['floorArea']} m²'),
                  const SizedBox(height: 16),

                  // ---- ĐIỀU 2 ----
                  _article('Điều 2. Giá thuê nhà ở'),
                  _moneyRow('Giá thuê hàng tháng', d['monthlyRent']),
                  _p(
                    'Giá thuê trên đã bao gồm chi phí quản lý vận hành theo thỏa thuận giữa hai bên.',
                  ),
                  const SizedBox(height: 8),
                  _p(
                    'Các chi phí sử dụng điện, nước và dịch vụ khác do Bên B thanh toán theo mức thỏa thuận sau:',
                  ),
                  if (d['electricityPrice'] != null &&
                      d['electricityPrice'] != 0)
                    _moneyRow(
                      'Giá điện',
                      d['electricityPrice'],
                      suffix: '/kWh',
                    ),
                  if (d['waterPrice'] != null && d['waterPrice'] != 0)
                    _moneyRow('Giá nước', d['waterPrice'], suffix: '/m³'),
                  if (d['serviceFee'] != null && d['serviceFee'] != 0)
                    _moneyRow('Phí dịch vụ', d['serviceFee'], suffix: '/tháng'),
                  const SizedBox(height: 16),

                  // ---- ĐIỀU 3 ----
                  _article('Điều 3. Phương thức và thời hạn thanh toán'),
                  _p(
                    '1. Phương thức thanh toán: Thanh toán bằng tiền Việt Nam thông qua hình thức chuyển khoản qua ngân hàng hoặc hình thức khác theo thỏa thuận.',
                  ),
                  _p('2. Thời hạn thanh toán: Trước ngày 05 hàng tháng.'),
                  const SizedBox(height: 16),

                  // ---- ĐIỀU 4 ----
                  _article('Điều 4. Thời hạn cho thuê và tiền cọc'),
                  _row('Ngày bắt đầu', _date(d['startDate'])),
                  _row('Ngày kết thúc', _date(d['endDate'])),
                  _moneyRow('Tiền đặt cọc', d['depositAmount']),
                  _p(
                    'Tiền cọc sẽ được hoàn trả khi Bên B trả phòng và không vi phạm hợp đồng, sau khi trừ đi chi phí hư hỏng (nếu có).',
                  ),
                  const SizedBox(height: 16),

                  if (_customTerms != null && _customTerms!.isNotEmpty)
                    ...() {
                      try {
                        final decoded = jsonDecode(_customTerms!) as List;
                        return decoded.expand((e) {
                          final item = e as Map<String, dynamic>;
                          return [
                            _article(item['title'] ?? ''),
                            _p(item['content'] ?? ''),
                            const SizedBox(height: 16),
                          ];
                        }).toList();
                      } catch (e, st) {
                        debugPrint('Error: $e\n$st');
                        return [_p(_customTerms!), const SizedBox(height: 16)];
                      }
                    }()
                  else ...[
                    // ---- ĐIỀU 5 ----
                    _article(
                      'Điều 5. Quyền và nghĩa vụ của Bên cho thuê (Bên A)',
                    ),
                    _p(
                      '1. Giao nhà ở cho Bên B đúng hiện trạng và hướng dẫn sử dụng.',
                    ),
                    _p(
                      '2. Bảo đảm cho Bên B sử dụng ổn định trong thời hạn thuê.',
                    ),
                    _p(
                      '3. Bảo trì, sửa chữa nhà ở theo định kỳ; bồi thường nếu không bảo trì gây thiệt hại.',
                    ),
                    _p(
                      '4. Không được đơn phương chấm dứt hợp đồng khi Bên B thực hiện đúng nghĩa vụ.',
                    ),
                    _p(
                      '5. Thực hiện nghĩa vụ tài chính với Nhà nước theo quy định pháp luật.',
                    ),
                    const SizedBox(height: 16),

                    // ---- ĐIỀU 6 ----
                    _article('Điều 6. Quyền và nghĩa vụ của Bên thuê (Bên B)'),
                    _p(
                      '1. Yêu cầu Bên A giao nhà đúng hiện trạng đã thỏa thuận.',
                    ),
                    _p('2. Bảo quản, sử dụng nhà ở đúng công năng, thiết kế.'),
                    _p(
                      '3. Thanh toán đủ tiền thuê theo thời hạn và phương thức đã thỏa thuận.',
                    ),
                    _p(
                      '4. Không được thay đổi, cải tạo, phá dỡ nếu không có sự đồng ý bằng văn bản của Bên A.',
                    ),
                    _p('5. Trả nhà ở cho Bên A khi hết thời hạn thuê.'),
                    _p('6. Bồi thường thiệt hại do lỗi của mình gây ra.'),
                    const SizedBox(height: 16),

                    // ---- ĐIỀU 7 ----
                    _article('Điều 7. Trách nhiệm do vi phạm hợp đồng'),
                    _p(
                      '1. Bên vi phạm phải bồi thường thiệt hại cho bên còn lại theo quy định pháp luật.',
                    ),
                    _p(
                      '2. Trường hợp bất khả kháng (thiên tai, chiến tranh, thay đổi quy định pháp luật) không bị coi là vi phạm hợp đồng.',
                    ),
                    const SizedBox(height: 16),

                    // ---- ĐIỀU 8 ----
                    _article('Điều 8. Các trường hợp chấm dứt hợp đồng'),
                    _p('1. Hai bên đồng ý chấm dứt hợp đồng bằng văn bản.'),
                    _p('2. Bên B chậm thanh toán tiền thuê quá 30 ngày.'),
                    _p('3. Bên A chậm bàn giao nhà ở theo thỏa thuận.'),
                    _p(
                      '4. Sự kiện bất khả kháng không thể khắc phục trong 90 ngày.',
                    ),
                    const SizedBox(height: 16),

                    // ---- ĐIỀU 9 ----
                    _article('Điều 9. Giải quyết tranh chấp'),
                    _p(
                      'Mọi tranh chấp phát sinh từ hợp đồng này trước hết được giải quyết thông qua thương lượng, hòa giải giữa hai bên. Trường hợp không thể giải quyết được thì đưa ra Tòa án nhân dân có thẩm quyền theo quy định pháp luật.',
                    ),
                    const SizedBox(height: 16),

                    // ---- ĐIỀU 10 ----
                    _article('Điều 10. Hiệu lực của hợp đồng'),
                    _p(
                      '1. Hợp đồng này có hiệu lực kể từ ngày hai bên ký kết.',
                    ),
                    _p(
                      '2. Hợp đồng này được lập thành 02 bản có giá trị pháp lý như nhau, mỗi bên giữ 01 bản.',
                    ),
                    _p(
                      '3. Các phụ lục đính kèm là nội dung không tách rời hợp đồng này.',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---- NỘI QUY BỔ SUNG (nếu có) ----
                  if ((d['terms'] ?? '').toString().isNotEmpty) ...[
                    _article('Phụ lục: Nội quy & Điều khoản bổ sung'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        d['terms'].toString(),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if ((d['handoverCondition'] ?? '').toString().isNotEmpty) ...[
                    _article('Hiện trạng phòng bàn giao'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        d['handoverCondition'].toString(),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---- CHỮ KÝ ----
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'BÊN THUÊ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Text(
                              '(Bên B)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 80,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFD1D5DB),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: d['status'] == 'ACTIVE'
                                  ? d['tenantSignature'] != null
                                        ? Image.memory(
                                            base64Decode(d['tenantSignature']),
                                          )
                                        : const Center(
                                            child: Text(
                                              'Đã ký ✓',
                                              style: TextStyle(
                                                color:
                                                    CupertinoColors.systemGreen,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                  : const Center(
                                      child: Text(
                                        'Chưa ký',
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _s(d['tenantName']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'BÊN CHO THUÊ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Text(
                              '(Bên A)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 80,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFD1D5DB),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: d['ownerSignature'] != null
                                  ? Image.memory(
                                      base64Decode(d['ownerSignature']),
                                    )
                                  : const Center(
                                      child: Text(
                                        'Đã duyệt ✓',
                                        style: TextStyle(
                                          color: CupertinoColors.systemGreen,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _s(d['ownerName']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Xác nhận
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LiquidGlassColors.tenantAccent.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: LiquidGlassColors.tenantAccent.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_shield_fill,
                          color: LiquidGlassColors.tenantAccent,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bằng việc nhấn "Ký Hợp Đồng", Bên B xác nhận đã đọc, hiểu và đồng ý với tất cả các điều khoản trong hợp đồng này.',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        // Bottom button
        if (d['status'] == 'PENDING' &&
            d['tenantId'] == ref.read(authProvider).value?.id)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GlassButton(
              text: _hasReadToBottom ? 'Ký Hợp Đồng' : 'Kéo xuống cuối để ký',
              icon: _hasReadToBottom
                  ? CupertinoIcons.signature
                  : CupertinoIcons.arrow_down_circle_fill,
              color: _hasReadToBottom
                  ? LiquidGlassColors.tenantAccent
                  : CupertinoColors.systemGrey,
              onPressed: () {
                if (_hasReadToBottom) {
                  unawaited(
                    context.push(
                      '/contract-sign',
                      extra: {'contractId': widget.contractId},
                    ),
                  );
                } else {
                  unawaited(
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }

  // ---- Helper widgets ----

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    ),
  );

  Widget _article(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
        decoration: TextDecoration.underline,
      ),
    ),
  );

  Widget _p(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        height: 1.6,
        color: Color(0xFF374151),
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '- ',
          style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _moneyRow(String label, dynamic value, {String suffix = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '- ',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          Expanded(
            child: Text(
              '${_money(value)}$suffix',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu() {
    final d = _d!;
    final authUser = ref.read(authProvider).value;
    final isOwner = authUser?.role == 'OWNER';
    final isActive = d['status'] == 'ACTIVE';

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Tùy Chọn Hợp Đồng'),
          actions: [
            CupertinoActionSheetAction(
              child: const Text('Xem ảnh Hợp đồng gốc'),
              onPressed: () {
                Navigator.pop(ctx);
                _showContractImages();
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Xem Biên bản Nghiệm thu'),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_fetchAndShowInspectionLog());
              },
            ),
            if (isOwner && isActive) ...[
              CupertinoActionSheetAction(
                child: const Text(
                  'Gia hạn hợp đồng',
                  style: TextStyle(color: CupertinoColors.systemBlue),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showRenewDialog();
                },
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Chấm dứt hợp đồng'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showTerminateDialog();
                },
              ),
            ],
            if (!isOwner && isActive) ...[
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Trả phòng (Yêu cầu)'),
                onPressed: () {
                  Navigator.pop(ctx);
                  // Need full contract details for checkout, passing ID
                  unawaited(
                    context.push(
                      '/checkout-request',
                      extra: {
                        'contract': {
                          'id': widget.contractId,
                          'roomId': d['roomId'],
                          'startDate': d['startDate'],
                          'endDate': d['endDate'],
                        },
                      },
                    ),
                  );
                },
              ),
            ],
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  void _showContractImages() {
    List<String> images = [];
    try {
      if (_d!['contractImages'] != null) {
        images = List<String>.from(jsonDecode(_d!['contractImages']));
      }
    } catch (e) {
      debugPrint('Error parsing contract images: $e');
    }

    if (images.isEmpty) {
      _showDialog('Thông báo', 'Không có hình ảnh hợp đồng.');
      return;
    }

    unawaited(
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ContractImagesViewerScreen(
            images: images,
            contractId: widget.contractId,
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAndShowInspectionLog() async {
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CupertinoActivityIndicator(
            color: CupertinoColors.white,
            radius: 16,
          ),
        ),
      ),
    );
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get(
        '/v1/contracts/${widget.contractId}/inspection-log',
      );
      if (mounted) {
        Navigator.pop(context); // close loader
        if (res['success'] == true && res['data'] != null) {
          final data = res['data'];
          unawaited(
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => InspectionLogViewerScreen(
                  logData: data,
                  contractId: widget.contractId,
                ),
              ),
            ),
          );
        } else {
          _showDialog('Lỗi', 'Không lấy được biên bản nghiệm thu.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        _showDialog('Lỗi', 'Chưa có biên bản nghiệm thu hoặc lỗi mạng: $e');
      }
    }
  }

  void _showDialog(String title, String message) {
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
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenewDialog() {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Gia Hạn Hợp Đồng'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Bạn có chắc chắn muốn gia hạn hợp đồng thuê phòng thêm 12 tháng?',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text(
                'Gia hạn',
                style: TextStyle(color: AppTheme.kAccentColor),
              ),
              onPressed: () {
                unawaited(
                  ref
                      .read(contractProvider.notifier)
                      .renewContract(widget.contractId, 12),
                );
                Navigator.pop(ctx);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTerminateDialog() {
    final reasonCtrl = TextEditingController();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Chấm Dứt Hợp Đồng'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                const Text(
                  'Vui lòng nhập lý do chấm dứt hợp đồng thuê phòng này:',
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: reasonCtrl,
                  placeholder: 'Lý do chấm dứt...',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.placeholderText,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Chấm dứt'),
              onPressed: () {
                unawaited(
                  ref
                      .read(contractProvider.notifier)
                      .terminateContract(
                        widget.contractId,
                        reasonCtrl.text.trim(),
                      ),
                );
                Navigator.pop(ctx);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

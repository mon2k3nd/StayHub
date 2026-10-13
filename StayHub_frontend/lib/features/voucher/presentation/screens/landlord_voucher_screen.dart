import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/liquid_glass_scaffold.dart';
import '../../data/models/voucher_model.dart';
import '../../data/repositories/voucher_repository.dart';
import 'create_voucher_screen.dart';
import 'dart:async' show unawaited;

final landlordVouchersProvider = FutureProvider.autoDispose<List<VoucherModel>>(
  (ref) async {
    final repo = ref.watch(voucherRepositoryProvider);
    return repo.getLandlordVouchers();
  },
);

class LandlordVoucherScreen extends ConsumerWidget {
  const LandlordVoucherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchersAsync = ref.watch(landlordVouchersProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return LiquidGlassScaffold(
      title: 'Mã Giảm Giá',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.add_circled_solid,
          color: Color(0xFF298FFF),
          size: 28,
        ),
        onPressed: () {
          unawaited(
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const CreateVoucherScreen()),
            ).then((value) {
              if (value == true) ref.invalidate(landlordVouchersProvider);
            }),
          );
        },
      ),
      useScrollView: false,
      child: vouchersAsync.when(
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF298FFF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      CupertinoIcons.ticket,
                      size: 52,
                      color: Color(0xFF298FFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chưa có mã giảm giá',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tạo mã ưu đãi để thu hút\nvà giữ chân khách thuê.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 28),
                  CupertinoButton.filled(
                    onPressed: () {
                      unawaited(
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const CreateVoucherScreen(),
                          ),
                        ).then((value) {
                          if (value == true) {
                            ref.invalidate(landlordVouchersProvider);
                          }
                        }),
                      );
                    },
                    child: const Text('Tạo Mã Ngay'),
                  ),
                ],
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _VoucherCard(
                      voucher: vouchers[i],
                      currencyFormat: currencyFormat,
                    ),
                    childCount: vouchers.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 16)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemRed,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Lỗi: $err',
                style: const TextStyle(color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 12),
              CupertinoButton.filled(
                child: const Text('Thử lại'),
                onPressed: () => ref.invalidate(landlordVouchersProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final NumberFormat currencyFormat;

  const _VoucherCard({required this.voucher, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isFixed = voucher.discountType == 'FIXED_AMOUNT';
    final discountText = isFixed
        ? currencyFormat.format(voucher.discountAmount)
        : '${voucher.discountPercent?.toStringAsFixed(0)}%';
    final isActive = voucher.isActive;
    final activeColor = isActive
        ? const Color(0xFF10B981)
        : const Color(0xFF9CA3AF);
    final usageRatio = (voucher.totalUsageLimit ?? 0) > 0
        ? ((voucher.usedCount ?? 0) / (voucher.totalUsageLimit!)).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Ticket Header (Dashed top) ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [const Color(0xFF298FFF), const Color(0xFF6FA8FF)]
                        : [const Color(0xFF9CA3AF), const Color(0xFFD1D5DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.ticket,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Giảm $discountText × ${voucher.monthsPerTenant ?? 1} tháng',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Ticket Divider (Perforated) ──
            Row(
              children: [
                const _HalfCircle(left: true),
                Expanded(
                  child: Row(
                    children: List.generate(
                      22,
                      (i) => Expanded(
                        child: Container(
                          height: 1,
                          color: i.isEven
                              ? const Color(0xFFE5E7EB)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
                const _HalfCircle(left: false),
              ],
            ),

            // ── Ticket Body ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoPill(
                        icon: CupertinoIcons.person_2,
                        imagePath: 'assets/images/features/ai_roommate.png',
                        label: 'Đã dùng',
                        value:
                            '${voucher.usedCount ?? 0} / ${voucher.totalUsageLimit ?? '∞'}',
                        color: const Color(0xFF6366F1),
                      ),
                      _InfoPill(
                        icon: CupertinoIcons.calendar,
                        imagePath: 'assets/images/features/feat_booking.png',
                        label: 'Hết hạn',
                        value: voucher.endDate != null
                            ? '${voucher.endDate}'
                            : 'Vô hạn',
                        color: const Color(0xFF10B981),
                      ),
                      _InfoPill(
                        icon: isFixed
                            ? CupertinoIcons.money_dollar_circle
                            : CupertinoIcons.percent,
                        imagePath: isFixed
                            ? 'assets/images/features/feat_payments.png'
                            : 'assets/images/features/dynamic_pricing.png',
                        label: 'Loại',
                        value: isFixed ? 'Cố định' : 'Phần trăm',
                        color: const Color(0xFF298FFF),
                      ),
                    ],
                  ),
                  if ((voucher.totalUsageLimit ?? 0) > 0) ...[
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lượt đã dùng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              '${(usageRatio * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: activeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 6,
                            color: const Color(0xFFF3F4F6),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: usageRatio,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      activeColor,
                                      activeColor.withValues(alpha: 0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HalfCircle extends StatelessWidget {
  final bool left;
  const _HalfCircle({required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.horizontal(
          left: left ? Radius.zero : const Radius.circular(12),
          right: left ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? imagePath;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imagePath != null
              ? Image.asset(
                  imagePath!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, size: 18, color: color),
                )
              : Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}

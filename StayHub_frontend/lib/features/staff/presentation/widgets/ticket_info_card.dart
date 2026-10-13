import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../../../../core/utils/ticket_ui_helper.dart';
import '../../../ticket/data/models/ticket_model.dart';

class TicketInfoCard extends StatelessWidget {
  final TicketModel ticket;

  const TicketInfoCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusColor = TicketUIHelper.statusColor(ticket.status);

    return Column(
      children: [
        // Status Badge + Category
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ticket.severity == 'CRITICAL')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        color: CupertinoColors.systemRed,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SỰ CỐ KHẨN CẤP',
                        style: TextStyle(
                          color: CupertinoColors.systemRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      TicketUIHelper.categoryAsset(ticket.category),
                      width: 34,
                      height: 34,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => Icon(
                        TicketUIHelper.categoryIcon(ticket.category),
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TicketUIHelper.categoryLabel(ticket.category),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.branchName ?? "Khu trọ"} - Phòng ${ticket.roomName ?? ticket.roomId}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      TicketUIHelper.statusText(ticket.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Thông tin liên hệ
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    color: LiquidGlassColors.staffAccent,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thông tin liên hệ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.tenantName ??
                              'Khách thuê (ID: ${ticket.tenantId})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.tenantPhone ?? 'Chưa có SĐT',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ticket.tenantPhone != null &&
                      ticket.tenantPhone!.isNotEmpty)
                    CupertinoButton(
                      padding: const EdgeInsets.all(12),
                      color: CupertinoColors.systemGreen,
                      borderRadius: BorderRadius.circular(100),
                      onPressed: () async {
                        final Uri url = Uri.parse('tel:${ticket.tenantPhone}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: const Icon(
                        CupertinoIcons.phone_fill,
                        color: CupertinoColors.white,
                      ),
                    ),
                ],
              ),
              if (ticket.roommatesPhones != null &&
                  ticket.roommatesPhones!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFE5E7EB)),
                const SizedBox(height: 12),
                const Text(
                  'Liên hệ thành viên phòng',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...ticket.roommatesPhones!.map((phone) {
                  if (phone == ticket.tenantPhone) {
                    return const SizedBox.shrink(); // Skip tenant's phone
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.device_phone_portrait,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.phone_fill,
                                size: 14,
                                color: CupertinoColors.systemGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Gọi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () async {
                            final Uri url = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mô tả
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mô tả sự cố',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ticket.description ?? 'Không có mô tả.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF4B5563),
                ),
              ),
              if (ticket.tenantDesire != null &&
                  ticket.tenantDesire!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemYellow.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_text_fill,
                            color: CupertinoColors.systemOrange,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Mong muốn của khách',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ticket.tenantDesire!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ticket.createdAt != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock_fill,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.createdAt!)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

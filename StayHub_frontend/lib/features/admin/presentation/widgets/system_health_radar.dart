import 'package:flutter/cupertino.dart';
import '../../../../core/components/glass_container.dart';
import 'dart:async' show unawaited;

// Widget trạng thái nền tảng – dữ liệu từ backend /v1/admin/dashboard
class SystemHealthRadar extends StatefulWidget {
  final Map<String, dynamic> stats;
  const SystemHealthRadar({super.key, required this.stats});

  @override
  State<SystemHealthRadar> createState() => _SystemHealthRadarState();
}

class _SystemHealthRadarState extends State<SystemHealthRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalOwners = widget.stats['totalOwners'] ?? 0;
    final kycPending = widget.stats['kycPending'] ?? 0;
    final totalRooms = widget.stats['totalRooms'] ?? 0;
    final occupancyRate = (widget.stats['occupancyRate'] ?? 0.0).toDouble();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 20,
      color: const Color(0xCCFFFFFF),
      child: Column(
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF298FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  color: CupertinoColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan nền tảng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.black,
                      ),
                    ),
                    Text(
                      'Dữ liệu real-time từ hệ thống',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              // ONLINE dot
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeGreen.withValues(
                          alpha: _pulseAnim.value,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.activeGreen.withValues(
                              alpha: 0.5 * _pulseAnim.value,
                            ),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.activeGreen,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── KPI Grid ──
          Row(
            children: [
              Expanded(
                child: _buildKpiTile(
                  icon: CupertinoIcons.person_3_fill,
                  label: 'Chủ nhà',
                  value: '$totalOwners',
                  color: const Color(0xFF298FFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  icon: CupertinoIcons.building_2_fill,
                  label: 'Phòng',
                  value: '$totalRooms',
                  color: const Color(0xFF298FFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  icon: CupertinoIcons.time,
                  label: 'KYC chờ',
                  value: '$kycPending',
                  color: kycPending > 0
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.activeGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  icon: CupertinoIcons.chart_pie_fill,
                  label: 'Lấp đầy',
                  value: '${occupancyRate.toStringAsFixed(1)}%',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

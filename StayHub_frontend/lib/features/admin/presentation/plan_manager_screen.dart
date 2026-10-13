import 'dart:math';
import 'package:flutter/cupertino.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({super.key});

  @override
  State<PlanManagerScreen> createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'FREE',
      'price': '0đ',
      'limit': 5,
      'color': CupertinoColors.systemGrey,
      'features': ['Quản lý 5 phòng', 'Cơ bản'],
    },
    {
      'name': 'PRO',
      'price': '99.000đ/tháng',
      'limit': 50,
      'color': CupertinoColors.activeBlue,
      'features': ['Quản lý 50 phòng', 'Thống kê nâng cao', 'Hỗ trợ 24/7'],
    },
    {
      'name': 'ENTERPRISE',
      'price': '299.000đ/tháng',
      'limit': 500,
      'color': CupertinoColors.activeOrange,
      'features': ['Không giới hạn', 'Tùy chỉnh hợp đồng', 'Quản lý nhân viên'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLightGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Cấu hình Gói SaaS',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: _plans.length,
          itemBuilder: (context, index) {
            return _Plan3DCard(plan: _plans[index]);
          },
        ),
      ),
    );
  }
}

class _Plan3DCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  const _Plan3DCard({required this.plan});

  @override
  State<_Plan3DCard> createState() => _Plan3DCardState();
}

class _Plan3DCardState extends State<_Plan3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      unawaited(_controller.forward());
    } else {
      unawaited(_controller.reverse());
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value;
            final isFront = angle < pi / 2;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isFront
                  ? _buildFront()
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildBack(),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront() {
    final color = widget.plan['color'] as Color;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.plan['name'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Icon(CupertinoIcons.cube_box_fill, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.plan['price'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),
          const Spacer(),
          const Text(
            'Chạm để lật & chỉnh sửa cấu hình',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final color = widget.plan['color'] as Color;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Thay đổi giới hạn (Giả lập)',
            style: TextStyle(
              color: CupertinoColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CupertinoButton(
                color: CupertinoColors.systemRed,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(CupertinoIcons.minus),
                onPressed: () {},
              ),
              Text(
                '${widget.plan['limit']} phòng',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
              CupertinoButton(
                color: CupertinoColors.activeGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(CupertinoIcons.add),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassButton(
            text: 'Lưu thay đổi',
            color: color,
            onPressed: () {
              // Simulate save
              _flip();
            },
          ),
        ],
      ),
    );
  }
}

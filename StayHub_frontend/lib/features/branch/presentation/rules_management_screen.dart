import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/branch_rule_provider.dart';

class RulesManagementScreen extends ConsumerStatefulWidget {
  const RulesManagementScreen({super.key});

  @override
  ConsumerState<RulesManagementScreen> createState() =>
      _RulesManagementScreenState();
}

class _RulesManagementScreenState extends ConsumerState<RulesManagementScreen> {
  final _fmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(branchRuleProvider(1));
    return LiquidGlassScaffold(
      title: 'Quản lý Nội Quy',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showCreateRuleDialog,
        child: const Icon(
          CupertinoIcons.add_circled_solid,
          color: LiquidGlassColors.ownerAccent,
          size: 26,
        ),
      ),
      child: rulesAsync.when(
        data: (rules) => rules.isEmpty
            ? const Center(child: Text('Chưa có nội quy nào'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  rule.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.black,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: rule.appliesTo == 'TENANT'
                                      ? CupertinoColors.systemBlue.withValues(
                                          alpha: 0.1,
                                        )
                                      : CupertinoColors.systemPurple.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  rule.appliesTo == 'TENANT'
                                      ? 'Khách thuê'
                                      : 'Nhân sự',
                                  style: TextStyle(
                                    color: rule.appliesTo == 'TENANT'
                                        ? CupertinoColors.systemBlue
                                        : CupertinoColors.systemPurple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rule.description,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.money_dollar_circle_fill,
                                size: 18,
                                color: CupertinoColors.systemRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Phạt: ${_fmt.format(rule.penaltyAmount)}',
                                style: const TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {},
                                minimumSize: const Size(0, 0),
                                child: const Text(
                                  'Sửa',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            err.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _showCreateRuleDialog() {
    // Show dialog to create rule
  }
}

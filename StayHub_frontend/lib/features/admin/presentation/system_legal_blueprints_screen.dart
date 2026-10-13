import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

final legalBlueprintsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get('/v1/admin/legal-blueprints');
  if (response['success'] == true) {
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List — trả [] để màn hình không vỡ.
    final raw = response['data'];
    return raw is List ? raw : const <dynamic>[];
  }
  return [];
});

class SystemLegalBlueprintsScreen extends ConsumerStatefulWidget {
  const SystemLegalBlueprintsScreen({super.key});

  @override
  ConsumerState<SystemLegalBlueprintsScreen> createState() =>
      _SystemLegalBlueprintsScreenState();
}

class _SystemLegalBlueprintsScreenState
    extends ConsumerState<SystemLegalBlueprintsScreen> {
  void _openEditor(BuildContext context, dynamic blueprint) {
    unawaited(
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => _BlueprintEditorScreen(blueprint: blueprint),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blueprintsAsync = ref.watch(legalBlueprintsProvider);

    return LiquidGlassScaffold(
      title: 'Thư viện Pháp lý',
      backgroundColors: AppTheme.kBackgroundLight,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(legalBlueprintsProvider);
              try {
                await ref.read(legalBlueprintsProvider.future);
              } catch (e, st) {
                debugPrint('Error: $e\n$st');
              }
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  child: const Text('Soạn bản hợp đồng mới'),
                  onPressed: () => _openEditor(context, null),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: blueprintsAsync.when(
              data: (blueprints) {
                if (blueprints.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Chưa có mẫu hợp đồng nào',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final bp = blueprints[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Phiên bản: ${bp['id'] ?? 'Mới'}',
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
                                    color: (bp['status'] == 'ACTIVE')
                                        ? CupertinoColors.systemGreen
                                              .withValues(alpha: 0.2)
                                        : CupertinoColors.systemGrey.withValues(
                                            alpha: 0.2,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    bp['status'] ?? 'UNKNOWN',
                                    style: TextStyle(
                                      color: (bp['status'] == 'ACTIVE')
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemGrey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cập nhật: ${bp['createdAt']}',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                color: CupertinoColors.systemGrey6,
                                onPressed: () => _openEditor(context, bp),
                                child: const Text(
                                  'Chỉnh sửa',
                                  style: TextStyle(
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: blueprints.length),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (e, _) =>
                  SliverFillRemaining(child: AppErrorWidget(error: e)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintEditorScreen extends ConsumerStatefulWidget {
  final dynamic blueprint;
  const _BlueprintEditorScreen({this.blueprint});

  @override
  ConsumerState<_BlueprintEditorScreen> createState() =>
      _BlueprintEditorScreenState();
}

class _BlueprintEditorScreenState
    extends ConsumerState<_BlueprintEditorScreen> {
  late TextEditingController _coreContractCtrl;
  late TextEditingController _safetyClausesCtrl;

  @override
  void initState() {
    super.initState();
    _coreContractCtrl = TextEditingController(
      text: widget.blueprint?['coreContract'] ?? '',
    );
    _safetyClausesCtrl = TextEditingController(
      text: widget.blueprint?['safetyClauses'] ?? '',
    );
  }

  Future<void> _saveBlueprint() async {
    final client = ref.read(apiClientProvider);
    try {
      await client.post(
        '/v1/admin/legal-blueprints',
        data: {
          'id': widget.blueprint?['id'],
          'coreContract': _coreContractCtrl.text,
          'safetyClauses': _safetyClausesCtrl.text,
          'status': 'ACTIVE',
        },
      );
      if (mounted) {
        ref.invalidate(legalBlueprintsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (c) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(c),
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
    return LiquidGlassScaffold(
      title: 'Soạn thảo Hợp đồng',
      backgroundColors: AppTheme.kBackgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Văn bản thô Base Contract Template',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _coreContractCtrl,
                    maxLines: 15,
                    padding: const EdgeInsets.all(12),
                    placeholder:
                        'Ví dụ: Hợp đồng thuê phòng giá {{ROOM_PRICE}}...',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Văn bản thô Terms & Conditions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _safetyClausesCtrl,
                    maxLines: 10,
                    padding: const EdgeInsets.all(12),
                    placeholder: 'Điều khoản an toàn pháp lý...',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () => _saveBlueprint(),
                  child: const Text('Áp dụng làm mẫu quốc gia'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

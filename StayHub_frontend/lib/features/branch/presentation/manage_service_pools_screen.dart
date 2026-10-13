import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

// --- Data Model ---------------------------------------------------------------
class ServicePoolModel {
  final int? id;
  final int branchId;
  final String name;
  final String serviceType;
  final String allocationMethod;
  final double? price;

  const ServicePoolModel({
    this.id,
    required this.branchId,
    required this.name,
    required this.serviceType,
    required this.allocationMethod,
    this.price,
  });

  // BUGFIX (data): coerce an toàn — tránh `as int`/`as String` ném TypeError
  // khi backend trả String/null.
  static int? _toIntOrNull(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  factory ServicePoolModel.fromJson(Map<String, dynamic> j) => ServicePoolModel(
    id: _toIntOrNull(j['id']),
    branchId: _toIntOrNull(j['branchId']) ?? 0,
    name: j['name']?.toString() ?? '',
    serviceType: j['serviceType']?.toString() ?? '',
    allocationMethod: j['allocationMethod']?.toString() ?? '',
    price: j['price'] is num
        ? (j['price'] as num).toDouble()
        : double.tryParse(j['price']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'branchId': branchId,
    'name': name,
    'serviceType': serviceType,
    'allocationMethod': allocationMethod,
    if (price != null) 'price': price,
  };
}

// --- Constants ----------------------------------------------------------------
const _serviceTypes = [
  ('ELECTRICITY', '?', 'Dien'),
  ('WATER', '??', 'Nuoc'),
  ('CLEANING', '??', 'Ve sinh'),
  ('ELEVATOR', '??', 'Thang may'),
  ('WIFI', '??', 'Wifi'),
  ('OTHER', '??', 'Khac'),
];

const _allocationMethods = [
  ('FLAT_PER_ROOM', 'Co dinh/Phong', 'Moi phong tra mot so tien co dinh'),
  (
    'FLAT_PER_TENANT',
    'Co dinh/Nguoi',
    'Don gia x so nguoi thuc te trong phong',
  ),
  (
    'SHARED_EQUAL_ROOM',
    'Chia deu theo Phong',
    'Tong thang / so phong trong nhom',
  ),
  (
    'SHARED_EQUAL_HEAD',
    'Chia theo Dau nguoi',
    'Tong x (nguoi phong / tong nguoi nhom)',
  ),
];

String _icon(String t) =>
    _serviceTypes.firstWhere((e) => e.$1 == t, orElse: () => ('', '??', '')).$2;
String _typeLabel(String t) =>
    _serviceTypes.firstWhere((e) => e.$1 == t, orElse: () => ('', '', t)).$3;
String _methodLabel(String m) => _allocationMethods
    .firstWhere((e) => e.$1 == m, orElse: () => ('', m, ''))
    .$2;

final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');

// --- Screen -------------------------------------------------------------------
class ManageServicePoolsScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String branchName;
  const ManageServicePoolsScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  ConsumerState<ManageServicePoolsScreen> createState() =>
      _ManageServicePoolsScreenState();
}

class _ManageServicePoolsScreenState
    extends ConsumerState<ManageServicePoolsScreen> {
  List<ServicePoolModel> _pools = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPools());
  }

  Future<void> _loadPools() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get(
        '/api/service-pools/branch/${widget.branchId}',
      );
      // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi body không
      // phải List hoặc phần tử không phải Map — lọc an toàn bằng whereType.
      final raw = resp.data;
      final list = raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) =>
                      ServicePoolModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : <ServicePoolModel>[];
      if (mounted) {
        setState(() {
          _pools = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _createPool(ServicePoolModel pool) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/service-pools', data: pool.toJson());
      if (!mounted) return;
      ToastUtils.show(context, 'Da tao nhom dich vu!');
      await _loadPools();
    } catch (e) {
      if (!mounted) return;
      ToastUtils.show(context, 'Loi: $e', isError: true);
    }
  }

  Future<void> _updatePoolAmount(int poolId, double amount) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/api/service-pools/$poolId/amount?total=$amount');
      if (!mounted) return;
      ToastUtils.show(context, 'Da cap nhat so tien Pool!');
      await _loadPools();
    } catch (e) {
      if (!mounted) return;
      ToastUtils.show(context, 'Loi: $e', isError: true);
    }
  }

  Future<void> _deletePool(int poolId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/service-pools/$poolId');
      if (!mounted) return;
      ToastUtils.show(context, 'Da xoa nhom dich vu!');
      await _loadPools();
    } catch (e) {
      if (!mounted) return;
      ToastUtils.show(context, 'Loi: $e', isError: true);
    }
  }

  void _showCreatePoolSheet({ServicePoolModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing?.price?.toStringAsFixed(0) ?? '',
    );
    String selType = existing?.serviceType ?? 'ELECTRICITY';
    String selMethod = existing?.allocationMethod ?? 'FLAT_PER_ROOM';

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, ss) => Container(
            height: MediaQuery.of(ctx).size.height * 0.82,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemGroupedBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        existing == null
                            ? '+ Tao Nhom Dich Vu'
                            : 'Cap nhat Pool',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.systemGrey2,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: CupertinoColors.separator, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (existing == null) ...[
                          const Text(
                            'Ten nhom dich vu',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CupertinoTextField(
                            controller: nameCtrl,
                            placeholder: 'VD: Dien chung Tang 2, NVS Tang 3...',
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loai dich vu',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _serviceTypes.map((e) {
                              final sel = selType == e.$1;
                              return GestureDetector(
                                onTap: () => ss(() => selType = e.$1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? const Color(0xFF0EA5E9)
                                        : CupertinoColors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: sel
                                          ? const Color(0xFF0EA5E9)
                                          : CupertinoColors.systemGrey4,
                                    ),
                                  ),
                                  child: Text(
                                    '${e.$2} ${e.$3}',
                                    style: TextStyle(
                                      color: sel
                                          ? CupertinoColors.white
                                          : CupertinoColors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cong thuc chia tien',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._allocationMethods.map((e) {
                            final sel = selMethod == e.$1;
                            return GestureDetector(
                              onTap: () => ss(() => selMethod = e.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(
                                          0xFF0EA5E9,
                                        ).withValues(alpha: 0.07)
                                      : CupertinoColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF0EA5E9)
                                        : CupertinoColors.systemGrey4,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      sel
                                          ? CupertinoIcons.checkmark_circle_fill
                                          : CupertinoIcons.circle,
                                      color: sel
                                          ? const Color(0xFF0EA5E9)
                                          : CupertinoColors.systemGrey3,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.$2,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: sel
                                                  ? const Color(0xFF0EA5E9)
                                                  : CupertinoColors.black,
                                            ),
                                          ),
                                          Text(
                                            e.$3,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                        const Text(
                          'So tien thang nay (VND)',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: 'VD: 600000',
                          padding: const EdgeInsets.all(12),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              'd',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                            ),
                          ),
                        ),
                        if (existing != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.info_circle,
                                  color: Color(0xFF10B981),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'He thong se tu phan bo theo cong thuc "${_methodLabel(existing.allocationMethod)}".',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(14),
                    child: Text(existing == null ? 'Tao Nhom' : 'Luu'),
                    onPressed: () {
                      final price = double.tryParse(
                        priceCtrl.text.replaceAll(',', '').replaceAll('.', ''),
                      );
                      if (nameCtrl.text.trim().isEmpty && existing == null) {
                        ToastUtils.show(
                          context,
                          'Vui long nhap ten nhom!',
                          isError: true,
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      if (existing != null && price != null) {
                        unawaited(_updatePoolAmount(existing.id!, price));
                      } else if (existing == null) {
                        unawaited(
                          _createPool(
                            ServicePoolModel(
                              branchId: widget.branchId,
                              name: nameCtrl.text.trim(),
                              serviceType: selType,
                              allocationMethod: selMethod,
                              price: price,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int poolId) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xoa Nhom Dich Vu'),
          content: const Text(
            'Tat ca phong trong nhom se bi go lien ket. Ban chac chan?',
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Xoa'),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_deletePool(poolId));
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Huy'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Nhom Dich Vu - ${widget.branchName}',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.add_circled_solid,
          color: Color(0xFF0EA5E9),
          size: 28,
        ),
        onPressed: () => _showCreatePoolSheet(),
      ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator(radius: 16))
          : _error != null
          ? _buildError()
          : _pools.isEmpty
          ? _buildEmpty()
          : _buildList(),
    );
  }

  Widget _buildError() => Center(
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
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 16),
        CupertinoButton.filled(
          onPressed: _loadPools,
          child: const Text('Thu lai'),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('?', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text(
          'Chua co Nhom Dich Vu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tao nhom de quan ly dien/nuoc dung chung\ngiua cac phong trong tang hoac toan toa.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        CupertinoButton.filled(
          borderRadius: BorderRadius.circular(14),
          child: const Text('+ Tao Nhom Dau Tien'),
          onPressed: () => _showCreatePoolSheet(),
        ),
      ],
    ),
  );

  Widget _buildList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _pools.length,
    itemBuilder: (ctx, i) => _PoolCard(
      pool: _pools[i],
      onEdit: () => _showCreatePoolSheet(existing: _pools[i]),
      onDelete: () => _confirmDelete(_pools[i].id!),
    ),
  );
}

// --- Pool Card ----------------------------------------------------------------
class _PoolCard extends StatelessWidget {
  final ServicePoolModel pool;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PoolCard({
    required this.pool,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = pool.price != null && pool.price! > 0;
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _icon(pool.serviceType),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pool.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.black,
                        ),
                      ),
                      Text(
                        _typeLabel(pool.serviceType),
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  child: const Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.systemRed,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _methodLabel(pool.allocationMethod),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (hasPrice)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt.format(pool.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                      const Text(
                        'tong thang nay',
                        style: TextStyle(
                          fontSize: 10,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Chua nhap so tien',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

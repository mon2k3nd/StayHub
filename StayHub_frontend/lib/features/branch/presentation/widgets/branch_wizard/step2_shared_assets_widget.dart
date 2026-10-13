import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/glass_container.dart';
import '../../../../../core/utils/image_picker_utils.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../application/branch_notifier.dart';
import '../../../data/models/branch_model.dart';
import 'branch_wizard_theme.dart';
import 'dart:async' show unawaited;

/// BƯỚC 2 — Tài sản chung của cả toà nhà.
///
/// Dựa trên dữ liệu Bước 1 (tiện ích có thu phí = tài sản chung), chủ nhà có thể:
///   • Xem danh sách tài sản chung đã kế thừa từ Bước 1
///   • Thêm tài sản chung mới (tên, số lượng, ghi chú)
///   • Upload ảnh thực tế cho từng tài sản chung
///
/// Tài sản chung thuộc về CẢ TOÀ NHÀ → mọi phòng đều được dùng, không gán riêng
/// cho từng phòng. Dữ liệu lưu trong `description` JSON dưới khoá
/// `sharedAssets` (mảng {name, quantity, note, images}) và được backend đồng bộ
/// vào bảng `shared_facilities` (type = "ASSET") để lưu trữ lâu dài.
class Step2SharedAssetsWidget extends ConsumerStatefulWidget {
  final BranchModel? branch;
  final ValueChanged<BranchModel> onCompleted;

  const Step2SharedAssetsWidget({
    super.key,
    required this.branch,
    required this.onCompleted,
  });

  @override
  ConsumerState<Step2SharedAssetsWidget> createState() =>
      _Step2SharedAssetsWidgetState();
}

/// Một tài sản chung của toà nhà.
class _SharedAsset {
  String name;
  int quantity;
  String note;
  List<String> networkImages; // URL / data-URI đã lưu
  List<Uint8List> localImages; // bytes ảnh mới chọn, chưa lưu

  _SharedAsset({
    required this.name,
    this.quantity = 1,
    this.note = '',
    List<String>? networkImages,
    List<Uint8List>? localImages,
  }) : networkImages = networkImages ?? [],
       localImages = localImages ?? [];

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'note': note,
    'images': networkImages,
  };

  factory _SharedAsset.fromJson(Map<String, dynamic> j) => _SharedAsset(
    name: j['name']?.toString() ?? '',
    quantity: (j['quantity'] is num)
        ? (j['quantity'] as num).toInt()
        : int.tryParse(j['quantity']?.toString() ?? '') ?? 1,
    note: j['note']?.toString() ?? '',
    networkImages: ((j['images'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(),
  );
}

class _Step2SharedAssetsWidgetState
    extends ConsumerState<Step2SharedAssetsWidget> {
  bool _busy = false;
  final List<_SharedAsset> _assets = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFromBranch());
  }

  @override
  void didUpdateWidget(covariant Step2SharedAssetsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nạp lại khi đổi chi nhánh HOẶC khi dữ liệu chi nhánh được cập nhật
    // (ví dụ bấm "xem lại" sau khi lưu) — tránh hiển thị ảnh cũ/thiếu.
    if (oldWidget.branch?.id != widget.branch?.id ||
        oldWidget.branch?.description != widget.branch?.description) {
      _loaded = false;
      unawaited(_loadFromBranch());
    }
  }

  /// Các tiện ích là DỊCH VỤ (không phải tài sản hữu hình) → không kế thừa.
  static const List<String> _serviceKeywords = [
    'vệ sinh',
    'dọn',
    'rác',
    'wifi',
    'internet',
    'mạng',
    'giữ xe',
    'gửi xe',
    'bãi để xe',
    'trông xe',
    'bảo vệ',
    'an ninh',
    'điện',
    'nước',
    'phí dịch vụ',
    'quản lý',
    'pccc',
    'phòng cháy',
    'điều hoà',
    'điều hòa',
  ];

  bool _isService(String name) {
    final lower = name.toLowerCase();
    return _serviceKeywords.any(lower.contains);
  }

  /// Nạp tài sản chung đã lưu.
  ///
  /// Nguồn ưu tiên: bảng `shared_facilities` (type = "ASSET") trên CSDL —
  /// đây là nguồn sự thật, tồn tại vĩnh viễn. Nếu chưa có thì đọc từ
  /// `description` JSON (bản nháp), cuối cùng mới suy ra từ tiện ích Bước 1.
  Future<void> _loadFromBranch() async {
    final b = widget.branch;
    if (b == null) return;
    final meta = _decodeMeta(b.description);

    // 1. Ưu tiên dữ liệu đã lưu trong CSDL.
    List<_SharedAsset>? fromDb;
    try {
      final res = await ref
          .read(branchRemoteDataSourceProvider)
          .getFacilitiesByBranch(b.id);
      final list = (res['data'] as List?) ?? const [];
      final assets = list
          .whereType<Map>()
          .where((f) => (f['type']?.toString() ?? '') == 'ASSET')
          .map((f) {
            final images = <String>[];
            final rawImages = f['images'];
            if (rawImages is String && rawImages.trim().isNotEmpty) {
              try {
                final decoded = jsonDecode(rawImages);
                if (decoded is List) {
                  images.addAll(
                    decoded.map((e) => e.toString()).where((e) => e.isNotEmpty),
                  );
                }
              } catch (_) {}
            } else if (rawImages is List) {
              images.addAll(
                rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty),
              );
            }
            return _SharedAsset(
              name: f['name']?.toString() ?? '',
              quantity: int.tryParse(f['equipment']?.toString() ?? '') ?? 1,
              note: f['notes']?.toString() ?? '',
              networkImages: images,
            );
          })
          .where((a) => a.name.isNotEmpty)
          .toList();
      if (assets.isNotEmpty) fromDb = assets;
    } catch (_) {
      // Bỏ qua lỗi mạng — dùng dữ liệu nháp bên dưới.
    }

    if (!mounted) return;

    if (fromDb != null && fromDb.isNotEmpty) {
      // DB là nguồn sự thật, NHƯNG nếu ảnh trong DB rỗng (do lần lưu trước
      // thất bại giữa chừng) thì bù lại bằng ảnh trong `description` JSON
      // theo tên tài sản — tránh hiển thị thiếu ảnh đã tải lên.
      final metaAssets = (meta['sharedAssets'] as List?) ?? const [];
      final metaByName = <String, List<String>>{};
      for (final e in metaAssets) {
        if (e is! Map) continue;
        final n = e['name']?.toString() ?? '';
        final imgs = ((e['images'] as List?) ?? const [])
            .map((x) => x.toString())
            .where((x) => x.isNotEmpty)
            .toList();
        if (n.isNotEmpty && imgs.isNotEmpty) metaByName[n] = imgs;
      }
      for (final a in fromDb) {
        if (a.networkImages.isEmpty && metaByName.containsKey(a.name)) {
          a.networkImages.addAll(metaByName[a.name]!);
        }
      }
      _assets
        ..clear()
        ..addAll(fromDb);
    } else {
      final saved = (meta['sharedAssets'] as List?) ?? const [];
      if (saved.isNotEmpty) {
        _assets
          ..clear()
          ..addAll(
            saved.whereType<Map>().map(
              (e) => _SharedAsset.fromJson(e.cast<String, dynamic>()),
            ),
          );
      } else {
        // Kế thừa từ Bước 1: chỉ lấy tiện ích là TÀI SẢN hữu hình (bỏ dịch vụ
        // như vệ sinh, wifi, giữ xe, bảo vệ… vì đó không phải tài sản).
        final amenities = (meta['branchAmenities'] as List?) ?? const [];
        for (final a in amenities) {
          if (a is! Map) continue;
          final n = a['name']?.toString() ?? '';
          if (n.isEmpty || _isService(n)) continue;
          _assets.add(_SharedAsset(name: n));
        }
      }
    }
    setState(() => _loaded = true);
  }

  Map<String, dynamic> _decodeMeta(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.branch;
    final done = b?.step2Done ?? false;

    return WzStepScaffold(
      title: 'Bước 2 · Tài sản chung',
      subtitle: 'Tài sản dùng chung cho cả toà nhà',
      bottomBar: _buildActionButton(b, done),
      children: [
        const WzInfoCard(
          icon: CupertinoIcons.cube_box_fill,
          title: 'Tài sản chung toà nhà',
          description:
              'Máy giặt, bình nóng lạnh, camera, thang máy… là tài sản hữu hình '
              'của CẢ TOÀ NHÀ nên mọi phòng đều được dùng. Các dịch vụ như vệ '
              'sinh, wifi, giữ xe… không phải tài sản nên không hiển thị ở đây. '
              'Bạn có thể thêm tài sản khác và tải ảnh thực tế.',
        ),
        const SizedBox(height: WzSpacing.md),
        if (!_loaded)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(WzSpacing.xl),
              child: CupertinoActivityIndicator(),
            ),
          )
        else ...[
          _buildAssetList(),
          const SizedBox(height: WzSpacing.md),
          _buildAddButton(),
        ],
      ],
    );
  }

  Widget _buildAssetList() {
    if (_assets.isEmpty) {
      return const GlassContainer(
        padding: EdgeInsets.symmetric(vertical: WzSpacing.xxl),
        child: Column(
          children: [
            Icon(CupertinoIcons.cube_box, size: 34, color: WzColors.textFaint),
            SizedBox(height: WzSpacing.sm),
            Text('Chưa có tài sản chung nào', style: WzText.body),
            SizedBox(height: 2),
            Text('Bấm "Thêm tài sản chung" để khai báo', style: WzText.caption),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _assets.length; i++) ...[
          _buildAssetCard(_assets[i], i),
          if (i != _assets.length - 1) const SizedBox(height: WzSpacing.md),
        ],
      ],
    );
  }

  Widget _buildAssetCard(_SharedAsset asset, int index) {
    final int photoCount =
        asset.networkImages.length + asset.localImages.length;
    return GlassContainer(
      padding: const EdgeInsets.all(WzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: WzColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(WzRadius.chip),
                ),
                child: const Icon(
                  CupertinoIcons.cube_box_fill,
                  color: WzColors.brand,
                  size: 18,
                ),
              ),
              const SizedBox(width: WzSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name, style: WzText.rowTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Số lượng: ${asset.quantity}'
                      '${asset.note.isNotEmpty ? ' · ${asset.note}' : ''}',
                      style: WzText.caption,
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(0, 0),
                onPressed: () => _editAsset(index),
                child: const Icon(
                  CupertinoIcons.pencil,
                  size: 17,
                  color: WzColors.brand,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(0, 0),
                onPressed: () => setState(() => _assets.removeAt(index)),
                child: const Icon(
                  CupertinoIcons.trash,
                  size: 17,
                  color: WzColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: WzSpacing.md),
          _buildPhotoStrip(asset, index),
          const SizedBox(height: WzSpacing.sm),
          Row(
            children: [
              Icon(
                CupertinoIcons.photo_on_rectangle,
                size: 14,
                color: photoCount == 0 ? WzColors.error : WzColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                photoCount == 0
                    ? 'Chưa có ảnh (bắt buộc tối thiểu 1)'
                    : '$photoCount ảnh',
                style: photoCount == 0
                    ? WzText.caption.copyWith(
                        color: WzColors.error,
                        fontWeight: FontWeight.w600,
                      )
                    : WzText.caption,
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                onPressed: () => _pickImages(index),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.camera_fill,
                      size: 14,
                      color: WzColors.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Thêm ảnh',
                      style: WzText.label.copyWith(color: WzColors.brand),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStrip(_SharedAsset asset, int index) {
    final total = asset.networkImages.length + asset.localImages.length;
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: WzSpacing.sm),
        itemBuilder: (_, i) {
          final bool isNetwork = i < asset.networkImages.length;
          final Widget image = isNetwork
              ? _networkImage(asset.networkImages[i])
              : Image.memory(
                  asset.localImages[i - asset.networkImages.length],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoFallback(),
                );

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(WzRadius.chip),
                child: SizedBox(width: 74, height: 74, child: image),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (isNetwork) {
                      asset.networkImages.removeAt(i);
                    } else {
                      asset.localImages.removeAt(
                        i - asset.networkImages.length,
                      );
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Ảnh đã lưu có thể là URL (http) hoặc data-URI base64 → chọn đúng cách render.
  Widget _networkImage(String src) {
    if (src.startsWith('data:image')) {
      final comma = src.indexOf(',');
      if (comma > 0) {
        try {
          return Image.memory(
            base64Decode(src.substring(comma + 1)),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _photoFallback(),
          );
        } catch (_) {
          return _photoFallback();
        }
      }
      return _photoFallback();
    }
    return Image.network(
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _photoFallback(),
    );
  }

  Widget _photoFallback() => const ColoredBox(
    color: WzColors.surfaceMuted,
    child: Icon(CupertinoIcons.photo, color: WzColors.textFaint),
  );

  Widget _buildAddButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _editAsset(null),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: WzColors.brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WzRadius.tile),
          border: Border.all(color: WzColors.brand.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.add_circled_solid,
              size: 18,
              color: WzColors.brand,
            ),
            const SizedBox(width: 6),
            Text(
              'Thêm tài sản chung',
              style: WzText.cardTitle.copyWith(color: WzColors.brand),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Edit dialog ───────────────────────────

  Future<void> _editAsset(int? index) async {
    final existing = index == null ? null : _assets[index];
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    int quantity = existing?.quantity ?? 1;

    final saved = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: WzColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(WzRadius.card),
            ),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(WzSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? 'Thêm tài sản chung'
                        : 'Sửa tài sản chung',
                    style: WzText.cardTitle,
                  ),
                  const SizedBox(height: WzSpacing.lg),
                  _fieldLabel('Tên tài sản'),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: nameCtrl,
                    placeholder: 'VD: Máy giặt, Camera, Thang máy…',
                    padding: const EdgeInsets.all(WzSpacing.md),
                    decoration: BoxDecoration(
                      color: WzColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(WzRadius.chip),
                      border: Border.all(color: WzColors.border),
                    ),
                  ),
                  const SizedBox(height: WzSpacing.md),
                  _fieldLabel('Số lượng'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _stepperButton(
                        icon: CupertinoIcons.minus,
                        onTap: quantity > 1
                            ? () => setModal(() => quantity--)
                            : null,
                      ),
                      Container(
                        width: 54,
                        alignment: Alignment.center,
                        child: Text('$quantity', style: WzText.rowTitle),
                      ),
                      _stepperButton(
                        icon: CupertinoIcons.plus,
                        onTap: quantity < 999
                            ? () => setModal(() => quantity++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: WzSpacing.md),
                  _fieldLabel('Ghi chú (tuỳ chọn)'),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: noteCtrl,
                    placeholder: 'VD: Đặt tại tầng trệt, hoạt động tốt…',
                    padding: const EdgeInsets.all(WzSpacing.md),
                    decoration: BoxDecoration(
                      color: WzColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(WzRadius.chip),
                      border: Border.all(color: WzColors.border),
                    ),
                  ),
                  const SizedBox(height: WzSpacing.xl),
                  WzPrimaryButton(
                    label: existing == null ? 'Thêm tài sản' : 'Lưu thay đổi',
                    icon: CupertinoIcons.checkmark_alt,
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ToastUtils.show(
                          ctx,
                          'Vui lòng nhập tên tài sản',
                          isError: true,
                        );
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    setState(() {
      final asset = existing ?? _SharedAsset(name: '');
      asset.name = nameCtrl.text.trim();
      asset.quantity = quantity;
      asset.note = noteCtrl.text.trim();
      if (existing == null) _assets.add(asset);
    });
  }

  Widget _fieldLabel(String text) => Text(text, style: WzText.label);

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      onPressed: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? WzColors.brand.withValues(alpha: 0.1)
              : WzColors.surfaceMuted,
          borderRadius: BorderRadius.circular(WzRadius.chip),
          border: Border.all(
            color: enabled
                ? WzColors.brand.withValues(alpha: 0.3)
                : WzColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? WzColors.brand : WzColors.textFaint,
        ),
      ),
    );
  }

  void _pickImages(int index) {
    final asset = _assets[index];
    final remaining = 6 - asset.networkImages.length - asset.localImages.length;
    if (remaining <= 0) {
      ToastUtils.show(context, 'Mỗi tài sản tối đa 6 ảnh', isError: true);
      return;
    }
    unawaited(
      ImagePickerUtils.showPicker(
        context: context,
        limit: remaining,
        onPicked: (picked) async {
          if (picked.isEmpty) return;
          final bytesList = <Uint8List>[];
          for (final f in picked) {
            try {
              final bytes = await f.readAsBytes();
              if (bytes.isNotEmpty) bytesList.add(bytes);
            } catch (_) {
              // bỏ qua ảnh lỗi
            }
          }
          if (!mounted || bytesList.isEmpty) return;
          setState(() => asset.localImages.addAll(bytesList));
        },
      ),
    );
  }

  // ─────────────────────────── Save ───────────────────────────

  Widget _buildActionButton(BranchModel? b, bool done) {
    final enabled = b != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WzPrimaryButton(
          label: done ? 'Cập nhật tài sản chung' : 'Lưu tài sản chung',
          icon: done
              ? CupertinoIcons.checkmark_alt_circle_fill
              : CupertinoIcons.cube_box_fill,
          color: done ? WzColors.success : WzColors.brand,
          loading: _busy,
          enabled: enabled,
          onPressed: enabled ? () => _save(b) : null,
        ),
        if (!enabled) ...[
          const SizedBox(height: WzSpacing.sm),
          const Text(
            'Hoàn tất Bước 1 trước khi khai báo tài sản chung.',
            textAlign: TextAlign.center,
            style: WzText.caption,
          ),
        ],
      ],
    );
  }

  Future<void> _save(BranchModel b) async {
    // Mỗi tài sản chung BẮT BUỘC có tối thiểu 1 ảnh (chống tranh chấp sau này).
    final missing = _assets
        .where((a) => a.networkImages.isEmpty && a.localImages.isEmpty)
        .map((a) => a.name.trim().isEmpty ? '(chưa đặt tên)' : a.name.trim())
        .toList();
    if (missing.isNotEmpty) {
      ToastUtils.show(
        context,
        'Mỗi tài sản cần tối thiểu 1 ảnh. Thiếu: ${missing.join(', ')}',
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Mã hoá ảnh mới thành base64 (data-URI) và gộp với ảnh đã có.
      for (final asset in _assets) {
        if (asset.localImages.isEmpty) continue;
        for (final bytes in asset.localImages) {
          if (bytes.isEmpty) continue;
          asset.networkImages.add(
            'data:image/jpeg;base64,${base64Encode(bytes)}',
          );
        }
        asset.localImages.clear();
      }

      final meta = _decodeMeta(b.description);
      meta['sharedAssets'] = _assets.map((a) => a.toJson()).toList();

      final updated = await ref.read(branchProvider.notifier).updateBranch(
        b.id,
        {'description': jsonEncode(meta)},
      );
      final marked = await ref
          .read(branchProvider.notifier)
          .markStep(b.id, 2, true);
      if (!mounted) return;
      ToastUtils.show(context, 'Đã lưu tài sản chung');
      widget.onCompleted(marked ?? updated ?? b);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          'Không thể lưu tài sản chung: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

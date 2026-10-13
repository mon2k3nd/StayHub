import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/liquid_glass_scaffold.dart';
import '../../../application/branch_notifier.dart';
import '../../../data/models/branch_model.dart';
import 'step3_spatial_structure_widget.dart';
import 'dart:async' show unawaited;

/// MÀN HÌNH CHI TIẾT — BƯỚC 3: Cấu trúc không gian & khu vệ sinh chung.
class Step3SpatialStructureScreen extends ConsumerStatefulWidget {
  final BranchModel branch;

  const Step3SpatialStructureScreen({super.key, required this.branch});

  @override
  ConsumerState<Step3SpatialStructureScreen> createState() =>
      _Step3SpatialStructureScreenState();
}

class _Step3SpatialStructureScreenState
    extends ConsumerState<Step3SpatialStructureScreen> {
  late BranchModel _branch;

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
    // Nạp lại chi nhánh từ server để lấy `description` MỚI NHẤT (chứa sơ đồ
    // tầng/phòng/WC đã lưu). Nếu chỉ dùng model truyền vào, khi bấm "xem lại"
    // có thể thấy dữ liệu cũ hoặc unawaited(trống.)
    unawaited(_refreshFromServer());
  }

  Future<void> _refreshFromServer() async {
    final fresh = await ref
        .read(branchProvider.notifier)
        .getById(widget.branch.id);
    if (!mounted || fresh == null) return;
    setState(() => _branch = fresh);
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      useScrollView: false,
      child: Step3SpatialStructureWidget(
        branch: _branch,
        onCompleted: (updated) {
          setState(() => _branch = updated);
          Navigator.of(context).pop(updated);
        },
      ),
    );
  }
}

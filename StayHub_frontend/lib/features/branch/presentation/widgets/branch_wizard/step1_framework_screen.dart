import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/liquid_glass_scaffold.dart';
import '../../../application/branch_notifier.dart';
import '../../../data/models/branch_model.dart';
import 'step1_framework_widget.dart';
import 'dart:async' show unawaited;

/// MÀN HÌNH CHI TIẾT — BƯỚC 1: Khởi tạo & Thiết lập Khung vận hành Chi nhánh.
///
/// Được mở từ màn hình tổng quan [BranchWizardScreen]. Khi hoàn tất, màn hình
/// này `pop` trả về [BranchModel] đã cập nhật để tổng quan refresh trạng thái.
class Step1FrameworkScreen extends ConsumerStatefulWidget {
  final BranchModel? branch;

  const Step1FrameworkScreen({super.key, this.branch});

  @override
  ConsumerState<Step1FrameworkScreen> createState() =>
      _Step1FrameworkScreenState();
}

class _Step1FrameworkScreenState extends ConsumerState<Step1FrameworkScreen> {
  BranchModel? _branch;

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
    // Nạp lại chi nhánh từ server để lấy `description` MỚI NHẤT (chứa tiện ích
    // đã lưu). Nếu chỉ dùng model truyền vào, khi mở lại Bước 1 có thể thấy dữ
    // liệu cũ/trống → người dùng phải làm 2 lần mới thấy tiện unawaited(ích.)
    unawaited(_refreshFromServer());
  }

  Future<void> _refreshFromServer() async {
    final id = widget.branch?.id;
    if (id == null) return;
    final fresh = await ref.read(branchProvider.notifier).getById(id);
    if (!mounted || fresh == null) return;
    setState(() => _branch = fresh);
  }

  @override
  Widget build(BuildContext context) {
    // Không truyền `title` để tránh thanh nav mặc định — header của bước được
    // vẽ bên trong [Step1FrameworkWidget] theo design system chung.
    return LiquidGlassScaffold(
      useScrollView: false,
      child: Step1FrameworkWidget(
        branch: _branch,
        onCompleted: (updated) {
          setState(() => _branch = updated);
          Navigator.of(context).pop(updated);
        },
      ),
    );
  }
}

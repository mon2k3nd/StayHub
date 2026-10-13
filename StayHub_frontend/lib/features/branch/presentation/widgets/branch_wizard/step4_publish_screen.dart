import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/liquid_glass_scaffold.dart';
import '../../../data/models/branch_model.dart';
import 'step4_publish_widget.dart';

/// MÀN HÌNH CHI TIẾT — BƯỚC 5: Xác nhận & Đăng bài.
///
/// Được mở từ màn hình tổng quan [BranchWizardScreen]. Khi hoàn tất, màn hình
/// này `pop` trả về [BranchModel] đã cập nhật để tổng quan refresh trạng thái.
class Step4PublishScreen extends ConsumerStatefulWidget {
  final BranchModel branch;

  const Step4PublishScreen({super.key, required this.branch});

  @override
  ConsumerState<Step4PublishScreen> createState() => _Step4PublishScreenState();
}

class _Step4PublishScreenState extends ConsumerState<Step4PublishScreen> {
  late BranchModel _branch;

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Bước 5 · Đăng bài',
      useScrollView: false,
      child: Step4PublishWidget(
        branch: _branch,
        onCompleted: (updated) {
          setState(() => _branch = updated);
          Navigator.of(context).pop(updated);
        },
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/liquid_glass_scaffold.dart';
import '../../../data/models/branch_model.dart';
import 'step2_shared_assets_widget.dart';

/// MÀN HÌNH CHI TIẾT — BƯỚC 2: Tài sản chung của cả toà nhà.
class Step2SharedAssetsScreen extends ConsumerStatefulWidget {
  final BranchModel branch;

  const Step2SharedAssetsScreen({super.key, required this.branch});

  @override
  ConsumerState<Step2SharedAssetsScreen> createState() =>
      _Step2SharedAssetsScreenState();
}

class _Step2SharedAssetsScreenState
    extends ConsumerState<Step2SharedAssetsScreen> {
  late BranchModel _branch;

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      useScrollView: false,
      child: Step2SharedAssetsWidget(
        branch: _branch,
        onCompleted: (updated) {
          setState(() => _branch = updated);
          Navigator.of(context).pop(updated);
        },
      ),
    );
  }
}

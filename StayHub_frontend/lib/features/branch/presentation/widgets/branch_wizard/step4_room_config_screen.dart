import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/liquid_glass_scaffold.dart';
import '../../../data/models/branch_model.dart';
import 'step4_room_config_widget.dart';

/// MÀN HÌNH CHI TIẾT — BƯỚC 4: Cấu hình phòng chi tiết.
class Step4RoomConfigScreen extends ConsumerStatefulWidget {
  final BranchModel branch;

  const Step4RoomConfigScreen({super.key, required this.branch});

  @override
  ConsumerState<Step4RoomConfigScreen> createState() =>
      _Step4RoomConfigScreenState();
}

class _Step4RoomConfigScreenState extends ConsumerState<Step4RoomConfigScreen> {
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
      child: Step4RoomConfigWidget(
        branch: _branch,
        onCompleted: (updated) {
          setState(() => _branch = updated);
          Navigator.of(context).pop(updated);
        },
      ),
    );
  }
}

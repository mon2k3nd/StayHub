import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../../../core/utils/identifier_utils.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/branch_notifier.dart';
import '../data/models/branch_model.dart';
import '../../notification/data/notification_provider.dart';
import 'branch_detailed_config_screen.dart';
import '../domain/constants/rental_categories.dart';
import '../../../core/components/in_app_notification_banner.dart';
import '../../../core/services/osm_map_service.dart';
import '../../../core/components/responsive_file_image.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/data/address_data.dart';
import '../../../core/services/address_mapping_service.dart';
import '../../../core/network/api_client.dart';
import 'widgets/map_picker_dialog.dart';
import '../../../core/components/ios_text_field.dart';
import '../../../core/components/ios_grouped_section.dart';

part 'widgets/create_branch/step1_info_widget.dart';
part 'widgets/create_branch/step1_info_logic.dart';
part 'widgets/create_branch/step2_business_model_widget.dart';
part 'widgets/create_branch/step3_operation_scale_widget.dart';
part 'widgets/create_branch/step5_finance_widget.dart';
part 'widgets/create_branch/create_branch_stepper.dart';
part 'widgets/create_branch/create_branch_bottom_bar.dart';
part 'widgets/create_branch/create_branch_dialogs.dart';
part 'widgets/create_branch/create_branch_logic.dart';
part 'create_branch_state.dart';

class FloorDraft {
  int floorNumber;
  List<RoomDraft> rooms;
  FloorDraft(this.floorNumber, this.rooms);
}

class RoomDraft {
  String tempId;
  String code;
  String subType;
  bool isSelfContained;
  String? sharedWcId;
  double price;
  double area;
  RoomDraft({
    required this.tempId,
    this.code = '',
    this.subType = 'PHONG_TRO',
    this.isSelfContained = true,
    this.sharedWcId,
    this.price = 0.0,
    this.area = 0.0,
  });
}

class SharedWcDraft {
  String tempId;
  String code;
  String name;
  SharedWcDraft({required this.tempId, this.code = '', required this.name});
}

class CreateBranchScreen extends ConsumerStatefulWidget {
  final BranchModel? branchToEdit;

  /// Khi `true`, màn hình hoạt động như BƯỚC 1 của wizard "Quản lý chi nhánh":
  /// - Lưu chi nhánh ở trạng thái NHÁP (DRAFT) qua API `createWizardDraft`,
  ///   KHÔNG đẩy thẳng lên chợ trọ / thống kê khi chưa đủ 4 bước.
  /// - Khi lưu xong chỉ `Navigator.pop(branch)` để trả dữ liệu nền cho các
  ///   bước sau, KHÔNG `pushReplacement` sang màn hình cấu hình chi tiết.
  final bool wizardMode;

  const CreateBranchScreen({
    super.key,
    this.branchToEdit,
    this.wizardMode = false,
  });

  @override
  ConsumerState<CreateBranchScreen> createState() => _CreateBranchScreenState();
}

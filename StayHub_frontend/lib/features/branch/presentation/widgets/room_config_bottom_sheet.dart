import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../../../../core/utils/image_picker_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/room_type_codes.dart';
import '../../data/models/branch_model.dart';

part 'room_config_bottom_sheet_state.dart';
part 'room_config_bottom_sheet_helpers.dart';

class RoomConfigBottomSheet extends StatefulWidget {
  final Map<String, dynamic> room;
  final double defaultPrice;
  final BranchModel? branch;
  final List<Map<String, dynamic>>? allFacilities;
  final List<Map<String, dynamic>>? allRooms;
  final Future<void> Function(Map<String, dynamic>, void Function(int, int)?)
  onSaved;
  final Future<void> Function(Map<String, dynamic>, void Function(int, int)?)
  onApplyMultiple;

  const RoomConfigBottomSheet({
    super.key,
    required this.room,
    required this.defaultPrice,
    this.branch,
    this.allFacilities,
    this.allRooms,
    required this.onSaved,
    required this.onApplyMultiple,
  });

  @override
  State<RoomConfigBottomSheet> createState() => _RoomConfigBottomSheetState();
}

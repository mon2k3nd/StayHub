part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

/// Robust area parser shared by the room-config inputs.
///
/// Area is a decimal value (e.g. 25.5 m²). We must NOT blindly convert every
/// comma into a dot, otherwise a thousands-grouped "1,000" would be read as
/// 1.0 m². Rules:
///  * both `,` and `.` present -> the LAST one is the decimal mark;
///  * only `,` present -> treat as decimal unless it looks like grouping
///    (i.e. every group after the first has exactly 3 digits).
double _parseAreaInput(String raw) {
  var cleaned = raw.trim();
  if (cleaned.isEmpty) return 0;
  final hasComma = cleaned.contains(',');
  final hasDot = cleaned.contains('.');
  if (hasComma && hasDot) {
    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');
    if (lastComma > lastDot) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else {
      cleaned = cleaned.replaceAll(',', '');
    }
  } else if (hasComma) {
    final parts = cleaned.split(',');
    final isGrouping =
        parts.length > 1 && parts.skip(1).every((p) => p.length == 3);
    cleaned = isGrouping
        ? cleaned.replaceAll(',', '')
        : cleaned.replaceAll(',', '.');
  }
  return double.tryParse(cleaned) ?? 0;
}

extension CreateBranchLogicExt on _CreateBranchScreenState {
  /// Reactive validity gate for the CURRENT step.
  ///
  /// Mirrors the rules enforced by `_validateCurrentStep()` but WITHOUT showing
  /// dialogs. Used to proactively disable the "Tiếp tục" button so the user can
  /// never advance past an incomplete draft (prevents the "bypass state" bug
  /// where an invalid step still looked actionable).
  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) return false;
        if (widget.branchToEdit == null) {
          if (_selectedDistrict63Province == null) return false;
          if (_selectedDistrict63 == null) return false;
          if (_selectedWard63 == null) return false;
        }
        if (_houseNumberCtrl.text.trim().isEmpty) return false;
        if (_addressDetailCtrl.text.trim().isEmpty) return false;
        // FIX BUG-05: Phải GHIM thật, không chỉ có toạ độ geocode gợi ý.
        if (_latitude == null || _longitude == null || !_isPinned) return false;
        if (_coverPhotos.isEmpty && _networkCoverPhotos.isEmpty) return false;
        // Block while a duplicate-code check is in-flight or the code is taken.
        if (_isCheckingCode || _isBranchCodeTaken) return false;
        return true;
      case 1:
        if (_catId.isEmpty || _subId.isEmpty) return false;
        // Chỉ mô hình vận hành theo phòng mới cần số tầng.
        if (rentalCategoryById(_catId)?.isRoomBased ?? false) {
          final floors = int.tryParse(_floorsCtrl.text.trim());
          if (floors == null || floors < 1) return false;
        }
        return true;
      case 2:
        if (rentalCategoryById(_catId)?.isRoomBased ?? false) {
          final floors = int.tryParse(_floorsCtrl.text);
          final rpf = int.tryParse(_roomsPerFloorCtrl.text);
          if (floors == null || floors < 1) return false;
          if (rpf == null || rpf < 1) return false;
          for (var f in _floors) {
            for (var r in f.rooms) {
              if (r.price <= 0 || r.area <= 0) return false;
              if (r.price > 1000000000) return false;
              if (r.area > 1000) return false;
            }
          }
        }
        return true;
      case 3:
        if (_elecPriceCtrl.text.isEmpty) return false;
        if (_waterPriceCtrl.text.isEmpty) return false;
        final elecPrice =
            double.tryParse(
              _elecPriceCtrl.text.replaceAll(',', '').replaceAll('.', ''),
            ) ??
            0;
        final waterPrice =
            double.tryParse(
              _waterPriceCtrl.text.replaceAll(',', '').replaceAll('.', ''),
            ) ??
            0;
        if (elecPrice <= 0 || elecPrice > 100000) return false;
        if (waterPrice <= 0 || waterPrice > 500000) return false;
        return true;
      default:
        return true;
    }
  }

  void syncSharedWcs(int count) {
    setState(() {
      final prefix = _branchCodeCtrl.text.isNotEmpty
          ? _branchCodeCtrl.text
          : 'CN';
      while (_sharedWcs.length < count) {
        final idx = _sharedWcs.length + 1;
        final tempId = 'WC${idx.toString().padLeft(2, '0')}';
        _sharedWcs.add(
          SharedWcDraft(
            tempId: tempId,
            code: '${prefix}_$tempId',
            name: 'Nhà vệ sinh $idx',
          ),
        );
      }
      if (_sharedWcs.length > count) {
        final removed = _sharedWcs.sublist(count);
        _sharedWcs.removeRange(count, _sharedWcs.length);
        for (var f in _floors) {
          for (var r in f.rooms) {
            if (removed.any((wc) => wc.tempId == r.sharedWcId)) {
              r.sharedWcId = null;
            }
          }
        }
      }
    });
  }

  void cancel() {
    final isEdit = widget.branchToEdit != null;
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(
            isEdit ? 'Huỷ thay đổi' : 'Huỷ thêm mới',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          message: Text(
            isEdit
                ? 'Bạn có chắc chắn muốn thoát? Các thay đổi chưa lưu sẽ bị mất.'
                : 'Bạn có chắc chắn muốn huỷ? Mọi thông tin chưa lưu sẽ bị mất.',
          ),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx); // Đóng ActionSheet
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Đóng màn hình CreateBranchScreen
                } else {
                  context.go('/branch');
                }
              },
              child: Text(isEdit ? 'Thoát không lưu' : 'Huỷ và Xoá'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ),
      ),
    );
  }

  void generateBranchCode(String name) {
    if (name.trim().isEmpty) {
      setState(() => _autoGeneratedCode = '');
      if (!_isBranchCodeManuallyEdited) {
        _lastAutoAssignedCode = '';
        _branchCodeCtrl.text = '';
      }
      return;
    }
    final user = ref.read(authProvider).value;
    final code = IdentifierUtils.generateBranchCodeFromName(
      name,
      hostId: user?.id,
    );
    setState(() {
      _autoGeneratedCode = code;
    });
    if (!_isBranchCodeManuallyEdited) {
      // Ghi nhận mã vừa auto-gen để listener phân biệt được thao tác của
      // người dùng với thao tác gán tự động (tránh bật cờ sửa-tay nhầm).
      _lastAutoAssignedCode = code;
      _branchCodeCtrl.text = code;
    }
  }

  void generateFloors() {
    final numFloors = int.tryParse(_floorsCtrl.text) ?? 0;
    final roomsPerFloor = int.tryParse(_roomsPerFloorCtrl.text) ?? 1;

    if (numFloors <= 0) {
      setState(() => _floors.clear());
      return;
    }

    // Edge case: user reduced the floor count. Remove the extra floors, then
    // re-sync the remaining room codes so they always match the current
    // branch code (the branch code may have changed after floors were created).
    if (numFloors < _floors.length) {
      // FIX BUG-03: Dispose controller của các phòng bị xoá để tránh rò rỉ
      // bộ nhớ khi người dùng liên tục thay đổi số tầng/phòng.
      final removedFloors = _floors.sublist(numFloors);
      for (final floor in removedFloors) {
        for (final room in floor.rooms) {
          _roomPriceCtrls.remove(room.tempId)?.dispose();
          _roomAreaCtrls.remove(room.tempId)?.dispose();
        }
      }
      setState(() {
        _floors.removeRange(numFloors, _floors.length);
        _resyncRoomCodes();
      });
      return;
    }

    setState(() {
      for (int i = _floors.length + 1; i <= numFloors; i++) {
        List<RoomDraft> initialRooms = List.generate(
          roomsPerFloor <= 0 ? 1 : roomsPerFloor,
          (rIdx) {
            final branchCode = _branchCodeCtrl.text.isNotEmpty
                ? _branchCodeCtrl.text
                : 'CN';
            final newRoomCode =
                '${branchCode}_T${i}_${(rIdx + 1).toString().padLeft(2, '0')}';
            return RoomDraft(
              tempId: 'P${i}0${rIdx + 1}',
              subType: _subId,
              code: newRoomCode,
            );
          },
        );
        _floors.add(FloorDraft(i, initialRooms));
      }
      // Keep every existing room code in sync with the (possibly new) branch
      // code so the landlord never ends up with mismatched codes.
      _resyncRoomCodes();
    });
  }

  /// Regenerates the `code` of every room draft so it always reflects the
  /// current branch code and floor/room position. This prevents stale codes
  /// (e.g. `CN01_T1_01`) from lingering after the landlord renames the branch
  /// or edits the branch code. Must be called inside a `setState`.
  void _resyncRoomCodes() {
    final branchCode = _branchCodeCtrl.text.isNotEmpty
        ? _branchCodeCtrl.text
        : 'CN';
    for (final floor in _floors) {
      for (int rIdx = 0; rIdx < floor.rooms.length; rIdx++) {
        final room = floor.rooms[rIdx];
        room.code =
            '${branchCode}_T${floor.floorNumber}_${(rIdx + 1).toString().padLeft(2, '0')}';
      }
    }
  }

  void _updateProgress() {
    if (mounted) setState(() {});

    // Feature 5: Real-time Sync for POIs
    if (_currentStep == 1) {
      _poiDebounce?.cancel();
      _poiDebounce = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) unawaited(_fetchPOIs(isSilent: true));
      });
    }
  }
}

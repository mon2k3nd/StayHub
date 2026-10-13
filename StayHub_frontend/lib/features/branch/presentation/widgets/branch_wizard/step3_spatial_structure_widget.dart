import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/components/glass_container.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../application/branch_notifier.dart';
import '../../../data/models/branch_model.dart';
import '../room_config_bottom_sheet.dart';
import 'branch_wizard_theme.dart';

/// BƯỚC 3 — Cấu trúc không gian (sơ đồ toà nhà) + Khu vực vệ sinh chung.
///
/// Thiết kế lại cho gọn: mỗi tầng là MỘT thẻ, bên trong là lưới phòng.
/// Mọi phòng — kể cả phòng khép kín lẫn khu WC chung — đều có ID ổn định:
///   • Phòng: `<tầng><2 số>` (VD: 101, 102)
///   • WC chung: `WC<tầng><chữ cái>` (VD: WC1A, WC1B)
///
/// Dữ liệu lưu trong `description` JSON (khớp backend BranchServiceImpl):
///   `floors`: [{floorNumber, rooms:[{tempId, code, isSelfContained, sharedWcId}]}]
///   `sharedWcs`: [{tempId, code, name, floorNumber}]
class Step3SpatialStructureWidget extends ConsumerStatefulWidget {
  final BranchModel? branch;
  final ValueChanged<BranchModel> onCompleted;

  const Step3SpatialStructureWidget({
    super.key,
    required this.branch,
    required this.onCompleted,
  });

  @override
  ConsumerState<Step3SpatialStructureWidget> createState() =>
      _Step3SpatialStructureWidgetState();
}

/// Một phòng trong sơ đồ.
class _RoomDraft {
  String id; // tempId, VD: P.101
  String code; // mã hiển thị/lưu DB, VD: P.101
  bool isSelfContained;
  String? sharedWcId;

  /// Cấu hình chi tiết phòng (giá, diện tích, tiện ích, ảnh…) — khớp payload
  /// của `RoomConfigBottomSheet`. Rỗng nghĩa là chưa cấu hình chi tiết.
  Map<String, dynamic> detailedInfo;

  _RoomDraft({
    required this.id,
    required this.code,
    this.isSelfContained = true,
    this.sharedWcId,
    Map<String, dynamic>? detailedInfo,
  }) : detailedInfo = detailedInfo ?? {};

  /// Đã cấu hình chi tiết hay chưa (có ít nhất giá hoặc diện tích).
  bool get hasDetail {
    if (detailedInfo.isEmpty) return false;
    // BUGFIX (data): tránh `as num?` ném TypeError khi price là String.
    final raw = detailedInfo['price'];
    final price = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '') ?? 0.0;
    return price > 0;
  }

  Map<String, dynamic> toJson() => {
    'tempId': id,
    'code': code,
    'isSelfContained': isSelfContained,
    'sharedWcId': sharedWcId,
    if (detailedInfo.isNotEmpty) 'detailedInfo': detailedInfo,
  };

  factory _RoomDraft.fromJson(Map<String, dynamic> j) => _RoomDraft(
    id: j['tempId']?.toString() ?? j['id']?.toString() ?? '',
    code: j['code']?.toString() ?? j['tempId']?.toString() ?? '',
    isSelfContained: j['isSelfContained'] as bool? ?? true,
    sharedWcId: j['sharedWcId']?.toString(),
    detailedInfo: (j['detailedInfo'] as Map?)?.cast<String, dynamic>(),
  );
}

/// Một tầng trong sơ đồ toà nhà.
class _FloorDraft {
  int floorNumber;
  final List<_RoomDraft> rooms;
  _FloorDraft({required this.floorNumber, List<_RoomDraft>? rooms})
    : rooms = rooms ?? [];

  Map<String, dynamic> toJson() => {
    'floorNumber': floorNumber,
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };
}

/// Một khu WC chung — cũng có ID riêng.
class _WcDraft {
  String id; // tempId, VD: WC.101
  String code; // mã hiển thị, VD: WC.101
  String name;
  int floorNumber;
  _WcDraft({
    required this.id,
    required this.code,
    required this.name,
    required this.floorNumber,
  });

  Map<String, dynamic> toJson() => {
    'tempId': id,
    'code': code,
    'name': name,
    'floorNumber': floorNumber,
  };

  factory _WcDraft.fromJson(Map<String, dynamic> j) => _WcDraft(
    id: j['tempId']?.toString() ?? j['id']?.toString() ?? '',
    code: j['code']?.toString() ?? j['tempId']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    floorNumber: (j['floorNumber'] as num?)?.toInt() ?? 1,
  );
}

class _Step3SpatialStructureWidgetState
    extends ConsumerState<Step3SpatialStructureWidget> {
  bool _busy = false;
  bool _loaded = false;

  final List<_FloorDraft> _floors = [];
  final List<_WcDraft> _wcs = [];

  @override
  void initState() {
    super.initState();
    _loadFromBranch();
  }

  @override
  void didUpdateWidget(covariant Step3SpatialStructureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nạp lại khi ĐỔI chi nhánh HOẶC khi `description` được làm mới từ server.
    // Trước đây chỉ so sánh `id` nên khi quay lại Bước 3 với cùng chi nhánh
    // nhưng description đã cập nhật, màn hình vẫn giữ dữ liệu cũ → "xem lại"
    // không thấy cấu trúc đã lưu.
    final idChanged = oldWidget.branch?.id != widget.branch?.id;
    final descChanged =
        oldWidget.branch?.description != widget.branch?.description;
    if (idChanged || descChanged) {
      setState(_loadFromBranch);
    }
  }

  // ─────────────────────────── Load ───────────────────────────

  void _loadFromBranch() {
    final b = widget.branch;
    if (b == null) return;
    final meta = _decodeMeta(b.description);

    _floors.clear();
    final rawFloors = (meta['floors'] as List?) ?? const [];
    for (final f in rawFloors) {
      if (f is! Map) continue;
      final fm = Map<String, dynamic>.from(f);
      final fNum = (fm['floorNumber'] as num?)?.toInt() ?? 1;
      final rooms = <_RoomDraft>[];
      final rawRooms = (fm['rooms'] as List?) ?? const [];
      for (final r in rawRooms) {
        if (r is Map) {
          rooms.add(_RoomDraft.fromJson(Map<String, dynamic>.from(r)));
        }
      }
      // Tương thích dữ liệu cũ: chỉ có roomCount → sinh phòng khép kín.
      if (rooms.isEmpty) {
        final count = (fm['roomCount'] as num?)?.toInt() ?? 0;
        for (var i = 0; i < count; i++) {
          final code = _roomCode(fNum, i);
          rooms.add(_RoomDraft(id: code, code: code));
        }
      }
      _floors.add(_FloorDraft(floorNumber: fNum, rooms: rooms));
    }

    // Nếu chưa có dữ liệu, khởi tạo từ số tầng của chi nhánh.
    //
    // LƯU Ý: `numberOfFloors` là @Transient ở backend nên KHÔNG được lưu —
    // khi nạp lại từ server nó luôn null. Vì vậy ta ưu tiên đọc số tầng từ
    // chính JSON `description` (đã lưu trong `meta['numberOfFloors']`), rồi
    // mới tới `b.numberOfFloors`, cuối cùng mặc định 1 tầng.
    //
    // Trước đây chỉ khởi tạo khi `step3Done == false`. Điều này khiến các
    // chi nhánh NHÁP bị lỗi lưu trước đó (step3Done=true nhưng description
    // rỗng do backend nuốt lỗi) hiển thị TRỐNG và người dùng phải cấu hình
    // lại từ đầu. Nay nếu đã đánh dấu hoàn tất mà vẫn không có tầng nào,
    // ta dựng lại sơ đồ từ `totalRooms` đã lưu để người dùng chỉ cần kiểm
    // tra và bấm lưu lại, không phải làm lại từ số 0.
    if (_floors.isEmpty) {
      final metaFloors = (meta['numberOfFloors'] as num?)?.toInt();
      final n = metaFloors ?? b.numberOfFloors ?? 1;
      final safeFloors = n < 1 ? 1 : n;
      // Nếu đã từng lưu (step3Done) và biết tổng số phòng, chia đều phòng
      // cho các tầng để tái dựng gần đúng cấu trúc cũ.
      final savedTotal = (meta['totalRooms'] as num?)?.toInt() ?? b.totalRooms;
      final perFloor = (b.step3Done && savedTotal > 0)
          ? (savedTotal / safeFloors).ceil()
          : 2;
      for (var i = 1; i <= safeFloors; i++) {
        _floors.add(
          _FloorDraft(
            floorNumber: i,
            rooms: _defaultRooms(i, perFloor < 1 ? 1 : perFloor),
          ),
        );
      }
    }

    _wcs.clear();
    final rawWcs = (meta['sharedWcs'] as List?) ?? const [];
    for (final w in rawWcs) {
      if (w is Map) _wcs.add(_WcDraft.fromJson(Map<String, dynamic>.from(w)));
    }

    // Áp bản đồ gán WC cũ (roomWcMap) nếu có.
    final rawMap = meta['roomWcMap'];
    if (rawMap is Map) {
      for (final f in _floors) {
        for (final r in f.rooms) {
          final v = rawMap[r.code] ?? rawMap[r.id];
          if (v != null) {
            r.sharedWcId = v.toString();
            r.isSelfContained = false;
          }
        }
      }
    }

    _loaded = true;
  }

  Map<String, dynamic> _decodeMeta(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  // ─────────────────────────── Helpers ───────────────────────────

  /// Chữ cái phòng: 0→A, 1→B, … 25→Z, 26→AA…
  String _letter(int index) {
    var n = index;
    final buf = StringBuffer();
    do {
      buf.write(String.fromCharCode(65 + (n % 26)));
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return buf.toString().split('').reversed.join();
  }

  /// Mã phòng: <tầng><2 số thứ tự> — VD tầng 1 phòng 1 → 101, phòng 2 → 102.
  ///
  /// Đây chỉ là TÊN NGẮN hiển thị. Mã phòng duy nhất toàn hệ thống do backend
  /// ghép thêm tiền tố branchCode (`{branchCode}_101`) để không trùng giữa
  /// các chi nhánh và không đụng hoá đơn/hợp đồng.
  String _roomCode(int floorNumber, int index) =>
      '$floorNumber${(index + 1).toString().padLeft(2, '0')}';

  /// Mã WC chung: WC<tầng><chữ cái> — VD tầng 1 khu 1 → WC1A, khu 2 → WC1B.
  String _wcCode(int floorNumber, int index) =>
      'WC$floorNumber${_letter(index)}';

  /// Tên mặc định của khu WC = chính MÃ WC (VD: WC1A, WC1B) để người dùng
  /// nhìn là biết ngay khu nào, thay vì chỉ hiện số tầng "1"/"2" gây khó hiểu.
  /// Nếu mã đã tồn tại (hiếm), thêm hậu tố trong ngoặc.
  String _defaultWcName(int floorNumber) {
    final base = _nextWcCode(floorNumber);
    final used = _wcs.map((w) => w.name).toSet();
    if (!used.contains(base)) return base;
    var n = 2;
    var candidate = '$base ($n)';
    while (used.contains(candidate)) {
      n++;
      candidate = '$base ($n)';
    }
    return candidate;
  }

  List<_RoomDraft> _defaultRooms(int floorNumber, int count) {
    return List.generate(count, (i) {
      final code = _roomCode(floorNumber, i);
      return _RoomDraft(id: code, code: code);
    });
  }

  /// Sinh mã phòng kế tiếp CHƯA tồn tại trên tầng — tránh trùng ID sau khi xoá.
  String _nextRoomCode(_FloorDraft f) {
    final used = f.rooms.map((r) => r.id).toSet();
    var i = f.rooms.length;
    var code = _roomCode(f.floorNumber, i);
    while (used.contains(code)) {
      i++;
      code = _roomCode(f.floorNumber, i);
    }
    return code;
  }

  /// Sinh mã WC kế tiếp CHƯA tồn tại trên tầng — tránh trùng ID.
  String _nextWcCode(int floorNumber) {
    final used = _wcs.map((w) => w.id).toSet();
    var i = _wcs.where((w) => w.floorNumber == floorNumber).length;
    var code = _wcCode(floorNumber, i);
    while (used.contains(code)) {
      i++;
      code = _wcCode(floorNumber, i);
    }
    return code;
  }

  int get _totalRooms => _floors.fold(0, (s, f) => s + f.rooms.length);

  int get _unassignedCount => _floors
      .expand((f) => f.rooms)
      .where((r) => !r.isSelfContained && (r.sharedWcId ?? '').isEmpty)
      .length;

  _WcDraft? _wcById(String? id) {
    if (id == null) return null;
    for (final w in _wcs) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Tìm số tầng chứa phòng.
  int _floorOfRoom(_RoomDraft room) {
    for (final f in _floors) {
      if (f.rooms.contains(room)) return f.floorNumber;
    }
    return 1;
  }

  /// Tiền tố mã chi nhánh — dùng để dựng ID đầy đủ lưu DB.
  String get _branchPrefix {
    final code = widget.branch?.branchCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    return 'CN';
  }

  /// ID ĐẦY ĐỦ của phòng, khớp đúng giá trị backend lưu vào `Room.roomCode`:
  /// `{branchCode}_{mã ngắn}` — VD: NHA_101.
  String _fullRoomId(String shortCode) => '${_branchPrefix}_$shortCode';

  /// ID ĐẦY ĐỦ của khu WC chung — VD: NHA_WC1A.
  String _fullWcId(String shortCode) => '${_branchPrefix}_$shortCode';

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final b = widget.branch;
    final done = b?.step3Done ?? false;

    return WzStepScaffold(
      title: 'Bước 3 · Cấu trúc không gian',
      subtitle: 'Sơ đồ toà nhà, phòng & khu vệ sinh chung',
      bottomBar: _buildActionButton(b, done),
      children: [
        _buildSummary(),
        const SizedBox(height: WzSpacing.lg),
        _buildFloorSection(),
      ],
    );
  }

  Widget _buildSummary() {
    return GlassContainer(
      padding: const EdgeInsets.all(WzSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: WzStatTile(
              value: '${_floors.length}',
              label: 'Số tầng',
              color: WzColors.brand,
            ),
          ),
          Container(width: 1, height: 40, color: WzColors.border),
          Expanded(
            child: WzStatTile(
              value: '$_totalRooms',
              label: 'Tổng số phòng',
              color: WzColors.success,
            ),
          ),
          Container(width: 1, height: 40, color: WzColors.border),
          Expanded(
            child: WzStatTile(
              value: '${_wcs.length}',
              label: 'Khu WC chung',
              color: WzColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Floors ───────────────────────────

  Widget _buildFloorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WzSectionRow(
          icon: CupertinoIcons.square_stack_3d_up_fill,
          title: 'Sơ đồ tầng & phòng',
          subtitle:
              'Mỗi tầng hiển thị danh sách Phòng và WC chung — mỗi phòng/WC là một dòng riêng, cấu hình theo ID. Chạm dòng phòng để chọn khép kín hoặc dùng WC (có thể dùng WC của tầng khác).',
        ),
        const SizedBox(height: WzSpacing.md),
        for (var i = 0; i < _floors.length; i++) ...[
          _buildFloorCard(i),
          const SizedBox(height: WzSpacing.sm),
        ],
        _buildAddFloorButton(),
      ],
    );
  }

  Widget _buildFloorCard(int index) {
    final f = _floors[index];
    final floorWcs = _wcs.where((w) => w.floorNumber == f.floorNumber).toList();
    return GlassContainer(
      padding: const EdgeInsets.all(WzSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header tầng ──
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WzColors.brand,
                      WzColors.brand.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(WzRadius.chip),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${f.floorNumber}',
                  style: WzText.statValue.copyWith(
                    fontSize: 19,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: WzSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tầng ${f.floorNumber}', style: WzText.cardTitle),
                    Text(
                      '${f.rooms.length} phòng'
                      '${floorWcs.isEmpty ? '' : ' · ${floorWcs.length} WC chung'}',
                      style: WzText.caption,
                    ),
                  ],
                ),
              ),
              _stepperButton(
                CupertinoIcons.minus,
                f.rooms.length <= 1 ? null : () => _removeRoom(f),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${f.rooms.length}',
                  textAlign: TextAlign.center,
                  style: WzText.cardTitle,
                ),
              ),
              _stepperButton(CupertinoIcons.plus, () => _addRoom(f)),
              const SizedBox(width: WzSpacing.sm),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                onPressed: _floors.length <= 1
                    ? null
                    : () => _removeFloor(index),
                child: Icon(
                  CupertinoIcons.trash,
                  size: 22,
                  color: _floors.length <= 1
                      ? WzColors.textFaint
                      : WzColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: WzSpacing.md),
          // ── Danh sách PHÒNG — mỗi phòng một dòng, cấu hình theo ID ──
          _buildRoomList(f),
          const SizedBox(height: WzSpacing.md),
          // ── Danh sách WC CHUNG — mỗi khu một dòng, cấu hình theo ID ──
          _buildWcList(f, floorWcs),
        ],
      ),
    );
  }

  /// Danh sách PHÒNG của tầng: mỗi phòng là một dòng đầy đủ, dễ chạm,
  /// hiển thị ID đầy đủ và trạng thái WC — chạm để cấu hình riêng từng phòng.
  Widget _buildRoomList(_FloorDraft f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.house_fill,
              size: 15,
              color: WzColors.brand,
            ),
            const SizedBox(width: 5),
            Text(
              'Phòng (${f.rooms.length})',
              style: WzText.label.copyWith(color: WzColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: WzSpacing.sm),
        for (final r in f.rooms) ...[
          _buildRoomRow(r),
          const SizedBox(height: WzSpacing.sm),
        ],
      ],
    );
  }

  /// Danh sách WC CHUNG của tầng: mỗi khu là một dòng đầy đủ, có nút thêm.
  Widget _buildWcList(_FloorDraft f, List<_WcDraft> floorWcs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.drop_fill,
              size: 15,
              color: WzColors.warning,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'WC chung (${floorWcs.length})',
                style: WzText.label.copyWith(color: WzColors.textSecondary),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              onPressed: () => _addWcForFloor(f.floorNumber),
              child: const Icon(
                CupertinoIcons.add_circled_solid,
                size: 22,
                color: WzColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: WzSpacing.sm),
        if (floorWcs.isEmpty)
          Text(
            'Chưa có WC. Phòng mặc định khép kín.',
            style: WzText.caption.copyWith(height: 1.35),
          )
        else
          for (final wc in floorWcs) ...[
            _buildWcRow(wc),
            const SizedBox(height: WzSpacing.sm),
          ],
      ],
    );
  }

  /// Dòng WC chung: mỗi khu là một hàng đầy đủ — cấu hình theo ID.
  Widget _buildWcRow(_WcDraft wc) {
    final assigned = _floors
        .expand((f) => f.rooms)
        .where((r) => r.sharedWcId == wc.id)
        .length;
    return GestureDetector(
      onTap: () => _editWc(_wcs.indexOf(wc)),
      child: Container(
        padding: const EdgeInsets.all(WzSpacing.sm),
        decoration: BoxDecoration(
          color: WzColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(WzRadius.chip),
          border: Border.all(color: WzColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // Tên khu WC (ngắn) — nổi bật.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: WzSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: WzColors.warning,
                borderRadius: BorderRadius.circular(WzRadius.chip),
              ),
              child: Text(
                wc.code,
                style: WzText.label.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: WzSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    wc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WzText.cardTitle.copyWith(color: WzColors.warning),
                  ),
                  const SizedBox(height: 1),
                  // ID đầy đủ (khớp DB) — nhãn phụ nhỏ.
                  Text(
                    _fullWcId(wc.code),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WzText.caption.copyWith(
                      color: WzColors.warning.withValues(alpha: 0.85),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('$assigned phòng đang dùng', style: WzText.caption),
                ],
              ),
            ),
            const SizedBox(width: WzSpacing.sm),
            GestureDetector(
              onTap: () => _editWc(_wcs.indexOf(wc)),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 20,
                  color: WzColors.brand,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _removeWc(_wcs.indexOf(wc)),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 20,
                  color: WzColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dòng PHÒNG: mỗi phòng là một hàng đầy đủ — cấu hình riêng theo ID.
  ///
  /// Chạm vào thân dòng → mở cấu hình CHI TIẾT của riêng phòng đó
  /// (giá, cọc, diện tích, phí dịch vụ, loại phòng, tiện ích, ảnh…).
  /// Nút WC bên phải → chọn khép kín / dùng WC chung.
  Widget _buildRoomRow(_RoomDraft room) {
    final wc = _wcById(room.sharedWcId);
    final bool shared = !room.isSelfContained && wc != null;
    final bool needsWc = !room.isSelfContained && wc == null;

    final Color accent = needsWc
        ? WzColors.error
        : (shared ? WzColors.warning : WzColors.brand);

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WzRadius.chip),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hàng chính: badge ID + tóm tắt + nút WC ──
          GestureDetector(
            onTap: () => _openDetailConfigForRoom(room),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(WzSpacing.sm),
              child: Row(
                children: [
                  // Tên phòng (ngắn) — hiển thị nổi bật.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WzSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(WzRadius.chip),
                    ),
                    child: Text(
                      room.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WzText.label.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: WzSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ID đầy đủ (khớp DB) — nhãn chính.
                        Text(
                          _fullRoomId(room.code),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WzText.rowTitle.copyWith(
                            color: accent,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.hasDetail
                              ? _detailSummary(room)
                              : 'Chưa cấu hình chi tiết — chạm để nhập',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WzText.caption.copyWith(
                            color: room.hasDetail
                                ? WzColors.success
                                : WzColors.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: WzSpacing.sm),
                  // Nút chọn WC (khép kín / WC chung) — không mở chi tiết.
                  GestureDetector(
                    onTap: () => _editRoom(room),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WzSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(WzRadius.chip),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            shared
                                ? CupertinoIcons.drop_fill
                                : (needsWc
                                      ? CupertinoIcons
                                            .exclamationmark_circle_fill
                                      : CupertinoIcons.house_fill),
                            size: 14,
                            color: accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            shared
                                ? wc.code
                                : (needsWc ? 'Chọn WC' : 'Khép kín'),
                            style: WzText.label.copyWith(color: accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Dải thông tin chi tiết đã cấu hình (nếu có) ──
          if (room.hasDetail) _buildRoomDetailStrip(room),
        ],
      ),
    );
  }

  /// Dải chip thông tin chi tiết của phòng: giá · cọc · diện tích · phí DV ·
  /// loại phòng · số người · tiện ích · số ảnh.
  Widget _buildRoomDetailStrip(_RoomDraft room) {
    final info = room.detailedInfo;
    final money = NumberFormat('#,###', 'vi_VN');

    double numOf(String k) => (info[k] as num?)?.toDouble() ?? 0;
    int intOf(String k) => (info[k] as num?)?.toInt() ?? 0;

    final chips = <Widget>[];

    void addChip(IconData icon, String text, Color color) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WzSpacing.sm,
            vertical: WzSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(WzRadius.chip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                text,
                style: WzText.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final price = numOf('price');
    final deposit = numOf('deposit');
    final area = numOf('area');
    final serviceFee = numOf('serviceFee');
    final occupants = intOf('maxOccupants');
    final vehicles = intOf('maxVehicles');

    if (price > 0) {
      addChip(
        CupertinoIcons.money_dollar_circle_fill,
        '${money.format(price)}đ',
        WzColors.brand,
      );
    }
    if (deposit > 0) {
      addChip(
        CupertinoIcons.lock_shield_fill,
        'Cọc ${money.format(deposit)}đ',
        WzColors.warning,
      );
    }
    if (area > 0) {
      addChip(
        CupertinoIcons.arrow_up_right_square_fill,
        '${area.toStringAsFixed(area % 1 == 0 ? 0 : 1)}m²',
        WzColors.success,
      );
    }
    if (serviceFee > 0) {
      addChip(
        CupertinoIcons.wrench_fill,
        'DV ${money.format(serviceFee)}đ',
        WzColors.textSecondary,
      );
    }
    if (occupants > 0) {
      addChip(
        CupertinoIcons.person_2_fill,
        '$occupants người',
        WzColors.textSecondary,
      );
    }
    if (vehicles > 0) {
      addChip(CupertinoIcons.car_fill, '$vehicles xe', WzColors.textSecondary);
    }

    // Tiện ích nổi bật.
    final features = <String>[];
    if (info['hasMezzanine'] == true) features.add('Gác');
    if (info['hasBalcony'] == true) features.add('Ban công');
    if (info['hasWindow'] == true) features.add('Cửa sổ');
    if (info['hasKitchen'] == true) features.add('Bếp');
    if (features.isNotEmpty) {
      addChip(CupertinoIcons.star_fill, features.join(' · '), WzColors.brand);
    }

    // Số ảnh đã tải.
    final photos = (info['photos'] as List?)?.length ?? 0;
    if (photos > 0) {
      addChip(CupertinoIcons.photo_fill, '$photos ảnh', WzColors.success);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WzSpacing.sm,
        0,
        WzSpacing.sm,
        WzSpacing.sm,
      ),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }

  /// Tóm tắt ngắn cấu hình chi tiết: giá · diện tích.
  String _detailSummary(_RoomDraft room) {
    final info = room.detailedInfo;
    final price = (info['price'] as num?)?.toDouble() ?? 0;
    final area = (info['area'] as num?)?.toDouble() ?? 0;
    final parts = <String>[];
    if (price > 0) {
      parts.add('${NumberFormat('#,###', 'vi_VN').format(price)}đ');
    }
    if (area > 0) {
      parts.add('${area.toStringAsFixed(area % 1 == 0 ? 0 : 1)}m²');
    }
    return parts.isEmpty ? 'Đã cấu hình' : parts.join(' · ');
  }

  Widget _buildAddFloorButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => setState(() {
        final next = _floors.isEmpty
            ? 1
            : _floors
                      .map((f) => f.floorNumber)
                      .reduce((a, b) => a > b ? a : b) +
                  1;
        _floors.add(
          _FloorDraft(floorNumber: next, rooms: _defaultRooms(next, 2)),
        );
      }),
      child: Container(
        height: 56,
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
              size: 21,
              color: WzColors.brand,
            ),
            const SizedBox(width: WzSpacing.sm),
            Text(
              'Thêm tầng',
              style: WzText.cardTitle.copyWith(color: WzColors.brand),
            ),
          ],
        ),
      ),
    );
  }

  void _addRoom(_FloorDraft f) {
    setState(() {
      final code = _nextRoomCode(f);
      f.rooms.add(_RoomDraft(id: code, code: code));
    });
  }

  void _removeRoom(_FloorDraft f) {
    if (f.rooms.length <= 1) return;
    setState(() => f.rooms.removeLast());
  }

  void _removeFloor(int index) {
    setState(() => _floors.removeAt(index));
  }

  // ─────────────────────────── Shared WCs ───────────────────────────

  /// Thêm WC ngay trong tầng được bấm — tên mặc định chính là số tầng.
  void _addWcForFloor(int floorNumber) {
    setState(() {
      final code = _nextWcCode(floorNumber);
      _wcs.add(
        _WcDraft(
          id: code,
          code: code,
          name: _defaultWcName(floorNumber),
          floorNumber: floorNumber,
        ),
      );
    });
  }

  Future<void> _editWc(int? index) async {
    final existing = index == null ? null : _wcs[index];
    final floor =
        existing?.floorNumber ?? (_floors.firstOrNull?.floorNumber ?? 1);
    final nameCtrl = TextEditingController(
      text: existing?.name ?? _defaultWcName(floor),
    );

    final saved = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
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
                  existing == null ? 'Thêm khu WC chung' : 'Sửa khu WC chung',
                  style: WzText.cardTitle,
                ),
                const SizedBox(height: 4),
                Text('Thuộc tầng $floor', style: WzText.caption),
                const SizedBox(height: WzSpacing.lg),
                const Text('Tên khu WC', style: WzText.label),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: nameCtrl,
                  placeholder: 'VD: WC1A, WC1B…',
                  padding: const EdgeInsets.all(WzSpacing.md),
                  decoration: BoxDecoration(
                    color: WzColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(WzRadius.chip),
                    border: Border.all(color: WzColors.border),
                  ),
                ),
                const SizedBox(height: WzSpacing.xl),
                WzPrimaryButton(
                  label: existing == null ? 'Thêm khu WC' : 'Lưu thay đổi',
                  icon: CupertinoIcons.checkmark_alt,
                  color: WzColors.warning,
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      ToastUtils.show(
                        ctx,
                        'Vui lòng nhập tên khu WC',
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
    );

    if (saved != true) return;
    setState(() {
      if (existing == null) {
        final code = _nextWcCode(floor);
        _wcs.add(
          _WcDraft(
            id: code,
            code: code,
            name: nameCtrl.text.trim(),
            floorNumber: floor,
          ),
        );
      } else {
        existing.name = nameCtrl.text.trim();
      }
    });
  }

  void _removeWc(int index) {
    final removed = _wcs.removeAt(index);
    setState(() {
      for (final f in _floors) {
        for (final r in f.rooms) {
          if (r.sharedWcId == removed.id) {
            r.sharedWcId = null;
            r.isSelfContained = true;
          }
        }
      }
    });
  }

  // ─────────────────────────── Room edit ───────────────────────────

  Future<void> _editRoom(_RoomDraft room) async {
    // Cho phép dùng WC của BẤT KỲ tầng nào — sắp xếp theo tầng để dễ chọn.
    final floorNumber = _floorOfRoom(room);
    final sortedWcs = [..._wcs]
      ..sort((a, b) => a.floorNumber.compareTo(b.floorNumber));

    final picked = await showCupertinoModalPopup<String?>(
      context: context,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: WzColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WzRadius.card),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              WzSpacing.lg,
              WzSpacing.md,
              WzSpacing.lg,
              WzSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tay nắm kéo.
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: WzColors.border,
                      borderRadius: BorderRadius.circular(WzRadius.chip),
                    ),
                  ),
                ),
                const SizedBox(height: WzSpacing.lg),
                // ── Tiêu đề: ID phòng nổi bật ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WzSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: WzColors.brand,
                        borderRadius: BorderRadius.circular(WzRadius.chip),
                      ),
                      child: Text(
                        _fullRoomId(room.code),
                        style: WzText.label.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: WzSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cấu hình vệ sinh',
                            style: WzText.cardTitle,
                          ),
                          Text('Tầng $floorNumber', style: WzText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WzSpacing.lg),
                // ── Lựa chọn: Khép kín ──
                _buildRoomOptionTile(
                  ctx: ctx,
                  value: '__self__',
                  selected: room.isSelfContained,
                  icon: CupertinoIcons.house_fill,
                  color: WzColors.brand,
                  title: 'Khép kín',
                  subtitle: 'WC riêng bên trong phòng',
                ),
                const SizedBox(height: WzSpacing.lg),
                // ── Lựa chọn: WC chung ──
                if (sortedWcs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(WzSpacing.md),
                    decoration: BoxDecoration(
                      color: WzColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(WzRadius.chip),
                      border: Border.all(
                        color: WzColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          size: 18,
                          color: WzColors.warning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chưa có khu WC chung. Hãy thêm WC ở cột bên phải của tầng.',
                            style: WzText.caption,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const Text('Dùng WC chung', style: WzText.label),
                  const SizedBox(height: WzSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final wc in sortedWcs) ...[
                            _buildRoomOptionTile(
                              ctx: ctx,
                              value: wc.id,
                              selected:
                                  !room.isSelfContained &&
                                  room.sharedWcId == wc.id,
                              icon: CupertinoIcons.drop_fill,
                              color: WzColors.warning,
                              // Hiện TÊN khu WC (VD: WC1A) làm tiêu đề, còn ID
                              // đầy đủ + tầng làm phụ đề — tránh gây khó hiểu.
                              title: wc.name,
                              subtitle:
                                  '${_fullWcId(wc.code)} · '
                                  '${wc.floorNumber == floorNumber ? 'Cùng tầng $floorNumber' : 'Tầng ${wc.floorNumber}'}',
                            ),
                            const SizedBox(height: WzSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (picked == null) return;
    setState(() {
      if (picked == '__self__') {
        room.isSelfContained = true;
        room.sharedWcId = null;
      } else {
        room.isSelfContained = false;
        room.sharedWcId = picked;
      }
    });
  }

  /// Ô lựa chọn lớn, dễ chạm cho hộp thoại cấu hình vệ sinh phòng.
  Widget _buildRoomOptionTile({
    required BuildContext ctx,
    required String value,
    required bool selected,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, value),
      child: Container(
        padding: const EdgeInsets.all(WzSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : WzColors.surfaceSoft,
          borderRadius: BorderRadius.circular(WzRadius.chip),
          border: Border.all(
            color: selected ? color : WzColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(WzRadius.chip),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: WzSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WzText.cardTitle.copyWith(
                      color: selected ? color : WzColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: WzText.caption),
                ],
              ),
            ),
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 22,
              color: selected ? color : WzColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }

  /// Mở cấu hình CHI TIẾT của một phòng cụ thể (từ dòng phòng).
  ///
  /// Mỗi phòng lưu `detailedInfo` riêng — không ảnh hưởng phòng khác.
  Future<void> _openDetailConfigForRoom(_RoomDraft room) =>
      _openDetailConfig(room);

  /// Mở `RoomConfigBottomSheet` để cấu hình chi tiết, lưu vào `detailedInfo`.
  ///
  /// [ctx] chỉ truyền khi cần đóng một sheet đang mở trước đó (luồng cũ).
  Future<void> _openDetailConfig(_RoomDraft room, {BuildContext? ctx}) async {
    // Đóng sheet đang mở (nếu có) trước khi mở sheet chi tiết.
    if (ctx != null) Navigator.pop(ctx);

    final roomMap = <String, dynamic>{
      'roomName': room.code,
      'isSelfContained': room.isSelfContained,
      'detailedInfo': room.detailedInfo,
      ...room.detailedInfo,
    };

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetCtx) => RoomConfigBottomSheet(
        room: roomMap,
        defaultPrice: 0,
        branch: widget.branch,
        onSaved: (data, _) async {
          setState(() {
            room.detailedInfo = Map<String, dynamic>.from(data);
          });
        },
        onApplyMultiple: (data, _) async {
          setState(() {
            room.detailedInfo = Map<String, dynamic>.from(data);
          });
        },
      ),
    );
    if (mounted) setState(() {});
  }

  // ─────────────────────────── Shared widgets ───────────────────────────

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      onPressed: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: WzColors.surfaceSoft,
          borderRadius: BorderRadius.circular(WzRadius.chip),
          border: Border.all(color: WzColors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? WzColors.brand : WzColors.textFaint,
        ),
      ),
    );
  }

  // ─────────────────────────── Save ───────────────────────────

  Widget _buildActionButton(BranchModel? b, bool done) {
    final enabled = b != null && _loaded;
    final blocked = _unassignedCount > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (blocked) ...[
          WzNoticeCard(
            tone: WzNoticeTone.warning,
            message:
                'Còn $_unassignedCount phòng chọn "dùng WC chung" nhưng chưa gán khu WC.',
          ),
          const SizedBox(height: WzSpacing.sm),
        ],
        WzPrimaryButton(
          label: done ? 'Cập nhật cấu trúc' : 'Lưu cấu trúc không gian',
          icon: done
              ? CupertinoIcons.checkmark_alt_circle_fill
              : CupertinoIcons.rectangle_grid_1x2_fill,
          color: done ? WzColors.success : WzColors.brand,
          loading: _busy,
          enabled: enabled && !blocked,
          onPressed: enabled && !blocked ? () => _save(b) : null,
        ),
        if (b == null) ...[
          const SizedBox(height: WzSpacing.sm),
          const Text(
            'Hoàn tất Bước 1 trước khi cấu hình cấu trúc không gian.',
            textAlign: TextAlign.center,
            style: WzText.caption,
          ),
        ],
      ],
    );
  }

  Future<void> _save(BranchModel b) async {
    setState(() => _busy = true);
    try {
      final meta = _decodeMeta(b.description);
      meta['floors'] = _floors.map((f) => f.toJson()).toList();
      meta['sharedWcs'] = _wcs.map((w) => w.toJson()).toList();
      meta['numberOfFloors'] = _floors.length;
      meta['totalRooms'] = _totalRooms;

      final updated = await ref
          .read(branchProvider.notifier)
          .updateBranch(b.id, {
            'description': jsonEncode(meta),
            'numberOfFloors': _floors.length,
            'totalRooms': _totalRooms,
          });
      // Nếu API trả về null (không có user / lỗi) thì DỪNG NGAY: tuyệt đối
      // không đánh dấu bước 3 hoàn tất và không hiện toast thành công, nếu
      // không người dùng sẽ tưởng đã lưu trong khi bước 4 trống trơn.
      if (updated == null) {
        throw Exception('Máy chủ không trả về dữ liệu chi nhánh sau khi lưu.');
      }
      final marked = await ref
          .read(branchProvider.notifier)
          .markStep(b.id, 3, true);
      if (!mounted) return;
      ToastUtils.show(context, 'Đã lưu cấu trúc không gian');
      widget.onCompleted(marked ?? updated);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Không thể lưu cấu trúc: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

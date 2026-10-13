part of 'room_config_bottom_sheet.dart';

/// Pure (setState-free) UI builders for [_RoomConfigBottomSheetState].
///
/// These methods only read state and return widgets; they never mutate state
/// directly. Callbacks that mutate state are passed in by the caller.
extension _RoomConfigHelpers on _RoomConfigBottomSheetState {
  Widget _buildFeatureCard({
    required String label,
    required String icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String photoGroup,
  }) {
    final photoCount =
        _photoUrls[photoGroup]!.length + _photoLocals[photoGroup]!.length;
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                )
              : null,
          color: value ? null : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 4),
            if (value && photoCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$photoCount ảnh',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                value
                    ? CupertinoIcons.checkmark_alt_circle_fill
                    : CupertinoIcons.circle,
                color: value ? Colors.white : const Color(0xFFD1D5DB),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlinePhotoUpload(
    String group,
    String title, {
    String colorScheme = 'GREEN',
  }) {
    final urls = _photoUrls[group]!;
    final locals = _photoLocals[group]!;
    final total = urls.length + locals.length;

    final bg = colorScheme == 'BLUE'
        ? const Color(0xFFF2F8FF)
        : const Color(0xFFF0FDF4);
    final border = colorScheme == 'BLUE'
        ? const Color(0xFFC7E2FF)
        : const Color(0xFFBBF7D0);
    final text = colorScheme == 'BLUE'
        ? const Color(0xFF0369A1)
        : const Color(0xFF065F46);
    final btn = colorScheme == 'BLUE'
        ? const Color(0xFF0EA5E9)
        : const Color(0xFF10B981);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
                const Spacer(),
                if (total < 2)
                  GestureDetector(
                    onTap: () => _pickPhotos(group, max: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: btn,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        '+ Ảnh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (total == 0)
              GestureDetector(
                onTap: () => _pickPhotos(group, max: 2),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.camera_fill, size: 16, color: btn),
                      const SizedBox(width: 6),
                      Text(
                        'Chạm để tải ảnh',
                        style: TextStyle(
                          fontSize: 12,
                          color: text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildThumbnailRow(group, max: 2),
          ],
        ),
      ),
    );
  }

  // ─── WC riêng (self-contained) ───
  Widget _buildWcSection() {
    final wcPhotoCount = _photoUrls['WC']!.length + _photoLocals['WC']!.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚿', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WC Riêng',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      'Phòng khép kín – cần ảnh nhà vệ sinh',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
              if (wcPhotoCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$wcPhotoCount ảnh',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Cần ảnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPhotoGrid('WC', max: 4, emptyHeight: 75),
        ],
      ),
    );
  }

  Widget _buildSharedWcNote() {
    String noteText =
        'Phòng này sử dụng WC chung. Vui lòng cấu hình ở mục WC của chi nhánh.';

    // Check if WC is already assigned
    final facs = widget.allFacilities ?? [];
    Map<String, dynamic>? assignedFacility;
    // BUGFIX (data): `id` có thể là String/null → tránh TypeError.
    final rawRoomId = widget.room['id'];
    final roomId = rawRoomId is num
        ? rawRoomId.toInt()
        : int.tryParse(rawRoomId?.toString() ?? '') ?? 0;

    // Check via rooms in facility or via sharedFacilities in room
    for (var f in facs) {
      bool isAssigned = false;

      // 1. Check if backend provided roomIds explicitly (the reliable way)
      if (f['roomIds'] != null && f['roomIds'] is List) {
        if ((f['roomIds'] as List).any((rId) => rId == roomId)) {
          isAssigned = true;
        }
      }

      // 2. Fallback: Check via old 'rooms' array if available
      // BUGFIX (data): guard phần tử là Map trước khi truy cập `r['id']` —
      // tránh NoSuchMethodError khi phần tử là String/số.
      if (!isAssigned && f['rooms'] != null && f['rooms'] is List) {
        if ((f['rooms'] as List).whereType<Map>().any(
          (r) => r['id'] == roomId,
        )) {
          isAssigned = true;
        }
      }

      // 3. Fallback: Check via sharedFacilities in room
      if (!isAssigned) {
        final sf = widget.room['sharedFacilities'];
        if (sf != null && sf is List) {
          if (sf.whereType<Map>().any((s) => s['id'] == f['id'])) {
            isAssigned = true;
          }
        }
      }

      if (isAssigned) {
        assignedFacility = f;
        break;
      }
    }

    List<String> imageList = [];
    List<Map<String, String>> displayPhotos = [];
    String sharedRoomNames = '';
    List<int> sharedRoomIds = [];

    if (assignedFacility != null) {
      final eq = assignedFacility['equipment'];
      List<dynamic> equip = [];
      if (eq is List) {
        equip = eq;
      } else if (eq is String && eq.isNotEmpty) {
        try {
          equip = jsonDecode(eq) as List<dynamic>;
        } catch (_) {}
      }
      final name = assignedFacility['name']?.toString() ?? 'WC Chung';
      final notes = assignedFacility['notes']?.toString() ?? '';

      final Map<String, String> wcMap = {
        'BINH_NONG_LANH': 'Bình nóng lạnh',
        'VOI_SEN': 'Vòi sen',
        'BET': 'Bồn cầu bệt',
        'BON_CAU_BET': 'Bồn cầu bệt',
        'BON_CAU_XOM': 'Bồn cầu xổm',
        'GUONG': 'Gương soi',
        'CHAU_RUA': 'Chậu rửa mặt',
        'QUAT_THONG_GIO': 'Quạt thông gió',
        'MAY_GIAT': 'Máy giặt',
        'SAY_QUAN_AO': 'Máy sấy',
        'ELECTRIC_METER': 'Công tơ điện',
        'WATER_METER': 'Đồng hồ nước',
      };

      final equipStr = equip.map((e) => wcMap[e] ?? e).join(', ');
      noteText =
          '$name ${notes.isNotEmpty ? '($notes)' : ''}\nThiết bị: ${equipStr.isEmpty ? 'Trống' : equipStr}';

      final imgs = assignedFacility['images'];
      if (imgs is List) {
        imageList = imgs.map((e) => e.toString()).toList();
      } else if (imgs is String && imgs.isNotEmpty) {
        try {
          final decoded = jsonDecode(imgs);
          if (decoded is List) {
            imageList = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }

      for (var img in imageList) {
        displayPhotos.add({'url': img, 'label': 'Chung'});
      }

      final fPhotos = assignedFacility['featurePhotos'];
      Map<String, List<String>> featureImages = {};
      if (fPhotos is Map) {
        fPhotos.forEach((k, v) {
          if (v is List) {
            featureImages[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
      } else if (fPhotos is String && fPhotos.isNotEmpty) {
        try {
          final decoded = jsonDecode(fPhotos);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              if (v is List) {
                featureImages[k.toString()] = v
                    .map((e) => e.toString())
                    .toList();
              }
            });
          }
        } catch (_) {}
      }

      featureImages.forEach((key, urls) {
        final eqCode = key.replaceAll('EQUIPMENT_', '');
        final eqName = wcMap[eqCode] ?? eqCode;
        for (var url in urls) {
          displayPhotos.add({'url': url, 'label': eqName});
        }
      });

      final rIds = assignedFacility['roomIds'];
      if (rIds is List) {
        sharedRoomIds = rIds
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .toList();
      } else {
        final rArray = assignedFacility['rooms'];
        if (rArray is List) {
          sharedRoomIds = rArray
              .map((e) => int.tryParse(e['id']?.toString() ?? '0') ?? 0)
              .toList();
        }
      }

      sharedRoomIds.removeWhere((id) => id == roomId || id == 0);

      if (sharedRoomIds.isNotEmpty && widget.allRooms != null) {
        List<String> names = [];
        for (var rid in sharedRoomIds) {
          final found = widget.allRooms!.firstWhere(
            (r) => r['id'] == rid,
            orElse: () => <String, dynamic>{},
          );
          if (found.isNotEmpty) {
            names.add(
              found['roomName']?.toString() ??
                  found['name']?.toString() ??
                  'Phòng $rid',
            );
          } else {
            names.add('Phòng $rid');
          }
        }
        sharedRoomNames = names.join(', ');
      }
    }

    if (assignedFacility == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    noteText,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context, 'OPEN_WC_CONFIG'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Chuyển đến cấu hình WC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  CupertinoIcons.info_circle_fill,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  noteText,
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (sharedRoomIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 24),
              child: Text(
                '👥 Đang chia sẻ chung với ${sharedRoomIds.length} phòng khác${sharedRoomNames.isNotEmpty ? ' ($sharedRoomNames)' : ''}',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (displayPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14, left: 24, bottom: 4),
              child: SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final photo = displayPhotos[idx];
                    final src = photo['url']!;
                    Widget imgWidget;
                    if (src.startsWith('http')) {
                      imgWidget = Image.network(
                        src,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    } else {
                      try {
                        String b64 = src;
                        if (b64.contains(',')) b64 = b64.split(',').last;
                        imgWidget = Image.memory(
                          base64Decode(b64),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72,
                            height: 72,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      } catch (_) {
                        imgWidget = Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 20,
                            color: Colors.grey,
                          ),
                        );
                      }
                    }

                    return SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.black12,
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imgWidget,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            photo['label']!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ánh xạ chuẩn giữa MÃ loại phòng (lưu trong DB: `rooms.room_sub_type`)
/// và NHÃN hiển thị cho người dùng.
///
/// QUY TẮC BẤT DI BẤT DỊCH:
/// - Mọi request gửi lên backend PHẢI dùng MÃ (vd: `PHONG_TRO`).
/// - Mọi chỗ hiển thị cho người dùng PHẢI dùng NHÃN (vd: `Phòng trọ`).
///
/// Trước đây UI gửi thẳng nhãn (`'Phòng trọ / CHDV'`) lên backend, trong khi
/// `RoomPostSpecification` so khớp `upper(room_sub_type) = 'PHÒNG TRỌ / CHDV'`
/// → không bao giờ khớp → bộ lọc "im lặng" trả về rỗng. File này là nguồn
/// chân lý duy nhất để tránh tái diễn lỗi đó.
class RoomTypeCodes {
  RoomTypeCodes._();

  /// Mã → Nhãn hiển thị.
  static const Map<String, String> codeToLabel = {
    // ── Phòng trọ / CHDV ──────────────────────────────────────────────
    'PHONG_TRO': 'Phòng trọ',
    'PHONG_TRO_THUONG': 'Phòng trọ thường',
    'PHONG_THUONG': 'Phòng trọ',
    'PHONG_DON': 'Phòng đơn',
    'CHDV': 'CHDV (Chung cư dịch vụ)',
    'STUDIO': 'Studio',
    'PHONG_STUDIO': 'Studio',
    'CHUNG_CU_MINI': 'Chung cư mini',
    'CAN_HO_MINI': 'Căn hộ mini',
    'PHONG_GAC_XEP': 'Phòng gác xép',
    'GAC_LUNG': 'Phòng gác lửng',
    // ── Căn hộ / Chung cư ─────────────────────────────────────────────
    'CHUNG_CU': 'Chung cư',
    'CAN_HO_CC': 'Căn hộ cao cấp',
    'CAN_HO_DICH_VU': 'Căn hộ dịch vụ',
    'CHUNG_CU_GIA_DINH': 'Chung cư gia đình',
    'PENTHOUSE_DUPLEX': 'Penthouse / Duplex',
    'OFFICETEL': 'Officetel',
    '1PN': 'Căn hộ 1 phòng ngủ',
    // ── Nhà nguyên căn ────────────────────────────────────────────────
    'NHA_NGUYEN_CAN': 'Nhà nguyên căn',
    'NHA_NGO': 'Nhà ngõ / Hẻm',
    'NHA_PHO': 'Nhà phố / Mặt tiền',
    'SHOPHOUSE': 'Nhà phố',
    'VILLA': 'Biệt thự / Villa',
    // ── Ở ghép / Ký túc xá ────────────────────────────────────────────
    'KY_TUC_XA': 'Ký túc xá',
    'O_GHEP': 'Ở ghép',
    'O_GHEP_KTX': 'Ở ghép / Ký túc xá',
    // ── Khác ──────────────────────────────────────────────────────────
    'OFFICE': 'Văn phòng',
    'KIOT': 'Kiot / Mặt bằng',
    'MAT_BANG': 'Mặt bằng kinh doanh',
    'KHO_BAI': 'Kho bãi / Nhà xưởng',
  };

  /// Nhãn → Mã (đảo ngược).
  ///
  /// BUGFIX: [codeToLabel] có NHIỀU mã dùng CHUNG một nhãn (vd 'Phòng trọ' ←
  /// PHONG_TRO / PHONG_TRO_THUONG / PHONG_THUONG; 'Studio' ← STUDIO /
  /// PHONG_STUDIO). Bản `for` cũ để entry SAU ghi đè entry TRƯỚC → nhãn
  /// 'Phòng trọ' bị ánh xạ nhầm sang PHONG_TRO_THUONG (alias) thay vì mã
  /// canonical PHONG_TRO. Nay chỉ ghi nếu nhãn CHƯA tồn tại để giữ mã xuất
  /// hiện ĐẦU TIÊN (canonical) — khớp quy tắc "DB chỉ lưu mã canonical".
  static final Map<String, String> labelToCode = {
    for (final e in codeToLabel.entries)
      if (!_seenLabels.contains(e.value)) e.value: e.key,
  };

  /// Tập nhãn đã gặp — dùng nội bộ để [labelToCode] giữ entry đầu tiên.
  static final Set<String> _seenLabels = {};

  /// Alias (mã cũ / mã rút gọn) → MÃ canonical.
  ///
  /// QUY TẮC: DB chỉ được lưu MÃ canonical. Mọi alias phải được quy về canonical
  /// trước khi ghi. Danh sách này PHẢI khớp với `RoomTypeCodes.java` ở backend.
  static const Map<String, String> aliasToCanonical = {
    // Phòng trọ
    'PHONG_THUONG': 'PHONG_TRO',
    'PHONG_TRO_THUONG': 'PHONG_TRO',
    'PHONG_DON': 'PHONG_TRO',
    // Studio
    'PHONG_STUDIO': 'STUDIO',
    // Căn hộ / Chung cư
    'CAN_HO_MINI': 'CHUNG_CU_MINI',
    'CAN_HO_CC': 'CHUNG_CU',
    'CAN_HO': 'CHUNG_CU',
    'CAN_HO_DICH_VU': 'CHUNG_CU',
    'CHUNG_CU_GIA_DINH': 'CHUNG_CU',
    'PENTHOUSE_DUPLEX': 'CHUNG_CU',
    'OFFICETEL': 'CHUNG_CU',
    '1PN': 'CHUNG_CU',
    '2PN': 'CHUNG_CU',
    // Nhà
    'NHA_NGO': 'NHA_NGUYEN_CAN',
    'NHA_PHO': 'NHA_NGUYEN_CAN',
    'SHOPHOUSE': 'NHA_NGUYEN_CAN',
    'VILLA': 'NHA_NGUYEN_CAN',
    // Ở ghép / KTX
    'KY_TUC_XA': 'O_GHEP_KTX',
    'O_GHEP': 'O_GHEP_KTX',
    // Khác
    'VAN_PHONG': 'OFFICE',
    'KIOT_BAN_LE': 'KIOT',
    'MAT_BANG': 'KIOT',
    'KHO_XUONG': 'KHO_BAI',
  };

  /// Tập MÃ canonical hợp lệ (đích của mọi alias + các mã gốc).
  static const Set<String> canonicalCodes = {
    'PHONG_TRO',
    'CHDV',
    'STUDIO',
    'GAC_LUNG',
    'PHONG_GAC_XEP',
    'CHUNG_CU_MINI',
    'CHUNG_CU',
    'NHA_NGUYEN_CAN',
    'O_GHEP_KTX',
    'OFFICE',
    'KIOT',
    'KHO_BAI',
    'KHONG_GIAN_CD',
    'LUU_TRU',
    'DAT_CHO_THUE',
  };

  /// Trả về nhãn hiển thị cho [code]. Nếu không nhận diện được thì trả về
  /// chính [code] (đã trim) để không hiển thị rỗng.
  static String labelOf(String? code) {
    if (code == null || code.trim().isEmpty) return '';
    final key = code.trim().toUpperCase();
    return codeToLabel[key] ?? code.trim();
  }

  /// Chuẩn hoá một giá trị bất kỳ (mã HOẶC nhãn) về MÃ canonical.
  /// Trả về null nếu không nhận diện được.
  static String? toCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();
    // 1) Alias → canonical (ưu tiên cao nhất).
    final alias = aliasToCanonical[upper];
    if (alias != null) return alias;
    // 2) Đã là mã canonical.
    if (canonicalCodes.contains(upper)) return upper;
    // 3) Là mã hợp lệ trong bảng tra (nhưng chưa canonical hoá) → quy về canonical.
    if (codeToLabel.containsKey(upper)) {
      return aliasToCanonical[upper] ?? upper;
    }
    // 4) Khớp theo NHÃN (không phân biệt hoa/thường).
    final byLabel = labelToCode[trimmed];
    if (byLabel != null) return aliasToCanonical[byLabel] ?? byLabel;
    for (final e in codeToLabel.entries) {
      if (e.value.toLowerCase() == trimmed.toLowerCase()) {
        return aliasToCanonical[e.key] ?? e.key;
      }
    }
    return null;
  }

  /// Chuẩn hoá danh sách (mã hoặc nhãn) → danh sách MÃ canonical, loại trùng.
  static List<String> toCodes(Iterable<String>? raw) {
    if (raw == null) return const [];
    final out = <String>[];
    for (final r in raw) {
      final code = toCode(r);
      if (code != null && !out.contains(code)) out.add(code);
    }
    return out;
  }

  /// Nhóm loại phòng để quyết định hiển thị các section điều kiện trong bộ lọc.
  ///
  /// LƯU Ý: [toCode] đã quy mọi alias về MÃ canonical, nên các tập dưới đây
  /// CHỈ được chứa MÃ canonical. Trước đây chúng còn chứa alias (CAN_HO_CC,
  /// PHONG_THUONG, KY_TUC_XA...) — những alias này KHÔNG BAO GIỜ khớp sau khi
  /// canonical hoá, khiến logic chỉ đúng nhờ trùng hợp. Đây là bug tiềm ẩn.
  static bool isApartmentLike(String? code) {
    final c = toCode(code);
    if (c == null) return false;
    return const {'CHUNG_CU_MINI', 'CHUNG_CU', 'NHA_NGUYEN_CAN'}.contains(c);
  }

  static bool isDormLike(String? code) {
    final c = toCode(code);
    if (c == null) return false;
    return const {'O_GHEP_KTX'}.contains(c);
  }

  static bool isRoomLike(String? code) {
    final c = toCode(code);
    if (c == null) return false;
    return const {'PHONG_TRO', 'CHDV', 'STUDIO', 'GAC_LUNG'}.contains(c);
  }
}

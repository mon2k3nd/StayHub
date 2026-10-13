import 'package:flutter/cupertino.dart';

/// Loại hình bất động sản cho thuê (cấp 1) — "Mô hình chi nhánh".
///
/// Mỗi [RentalCategory] là một NHÓM lớn (VD: Phòng trọ/CHDV, Nhà nguyên căn…).
/// Bên trong là các [RentalSubModel] — "loại hình chi tiết" mô tả đúng bản chất
/// tài sản của chi nhánh.
///
/// LƯU Ý QUAN TRỌNG VỀ THIẾT KẾ:
///   • "Khép kín" / "Không khép kín" KHÔNG phải là loại hình chi nhánh. Một chi
///     nhánh hoàn toàn có thể vừa có phòng khép kín vừa có phòng dùng WC chung.
///     Đây là thuộc tính CẤP PHÒNG, được cấu hình ở Bước 3 (Cấu trúc không gian)
///     và Bước 4 (Cấu hình phòng). Vì vậy chúng đã được loại bỏ khỏi danh sách
///     loại hình để tránh trùng lặp và gây hiểu nhầm.
///   • Các mô hình trùng bản chất đã được gộp lại (VD: CHDV phổ thông & cao cấp
///     chỉ khác mức độ nội thất — không phải loại hình khác nhau).
class RentalCategory {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;

  /// Mô tả ngắn gọn, súc tích dùng cho thẻ chọn mô hình (UI mới).
  final String desc;

  /// Icon đại diện (dùng cho UI dạng thẻ).
  final IconData icon;

  /// Màu nhấn của nhóm (dùng cho UI dạng thẻ).
  final Color accent;

  final List<RentalSubModel> subModels;

  const RentalCategory({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.desc,
    required this.icon,
    required this.accent,
    required this.subModels,
  });

  /// True nếu mô hình này vận hành theo từng PHÒNG (cần cấu hình tầng/phòng).
  ///
  /// Nhà nguyên căn, Kiot bán lẻ, Kho xưởng, Đất trống cho thuê nguyên khối nên không cần chia phòng.
  bool get isRoomBased =>
      id != 'NHA_NGUYEN_CAN' &&
      id != 'KIOT_BAN_LE' &&
      id != 'DAT_CHO_THUE' &&
      id != 'KHO_XUONG';
}

class RentalSubModel {
  final String id;
  final String title;
  final String desc;

  const RentalSubModel({
    required this.id,
    required this.title,
    required this.desc,
  });
}

const List<RentalCategory> kRentalCategories = [
  // ─────────────────────────────────────────────────────────────
  // 1. PHÒNG TRỌ / CHDV  (mô hình phổ biến nhất — vận hành theo phòng)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'PHONG_TRO',
    emoji: '🚪',
    icon: CupertinoIcons.building_2_fill,
    accent: Color(0xFF298FFF),
    title: 'Phòng trọ / CHDV',
    subtitle:
        'Dãy phòng cho thuê theo phòng — phù hợp sinh viên, công nhân, người đi làm.',
    desc: 'Cho thuê theo từng phòng, có thể chia tầng.',
    subModels: [
      RentalSubModel(
        id: 'PHONG_TRO_THUONG',
        title: 'Phòng trọ thường',
        desc: 'Phòng cơ bản, có thể dùng WC chung hoặc WC riêng tuỳ phòng',
      ),
      RentalSubModel(
        id: 'CHDV',
        title: 'CHDV (Chung cư dịch vụ)',
        desc: 'Phòng đầy đủ tiện nghi, dịch vụ dọn dẹp, bảo vệ',
      ),
      RentalSubModel(
        id: 'STUDIO',
        title: 'Studio',
        desc: 'Bếp + WC + phòng ngủ liền mạch, không gian mở hiện đại',
      ),
      RentalSubModel(
        id: 'CHUNG_CU_MINI',
        title: 'Chung cư mini',
        desc: 'Toà nhà nhiều tầng, thang máy, nhiều phòng độc lập',
      ),
      RentalSubModel(
        id: 'PHONG_GAC_XEP',
        title: 'Phòng gác xép',
        desc: 'Có gác ngủ phía trên, tối ưu diện tích nhỏ',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 2. CĂN HỘ / CHUNG CƯ CAO CẤP  (phân khúc nhu cầu lớn)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'CHUNG_CU',
    emoji: '🏢',
    icon: CupertinoIcons.building_2_fill,
    accent: Color(0xFF6366F1),
    title: 'Căn hộ / Chung cư',
    subtitle: 'Căn hộ chung cư, penthouse, duplex, officetel cao cấp.',
    desc: 'Cho thuê căn hộ cao cấp hoặc gia đình.',
    subModels: [
      RentalSubModel(
        id: 'CAN_HO_CC',
        title: 'Căn hộ cao cấp',
        desc: 'Đầy đủ tiện ích nội khu, hồ bơi, an ninh 24/7',
      ),
      RentalSubModel(
        id: 'CHUNG_CU_GIA_DINH',
        title: 'Chung cư 2-3 phòng ngủ',
        desc: 'Phù hợp gia đình trẻ, không gian sinh hoạt ấm cúng',
      ),
      RentalSubModel(
        id: 'PENTHOUSE_DUPLEX',
        title: 'Penthouse / Duplex',
        desc: 'Không gian sống thượng lưu, view toàn cảnh',
      ),
      RentalSubModel(
        id: 'OFFICETEL',
        title: 'Officetel',
        desc: 'Kết hợp vừa ở vừa làm văn phòng công ty',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 3. NHÀ NGUYÊN CĂN / BĐS RIÊNG  (cho thuê nguyên khối)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'NHA_NGUYEN_CAN',
    emoji: '🏠',
    icon: CupertinoIcons.house_fill,
    accent: Color(0xFF10B981),
    title: 'Nhà nguyên căn',
    subtitle:
        'Cho thuê trọn căn — nhà riêng, nhà phố, biệt thự, chung cư nguyên căn.',
    desc: 'Cho thuê nguyên căn, không chia phòng.',
    subModels: [
      RentalSubModel(
        id: 'NHA_NGO',
        title: 'Nhà ngõ / Hẻm',
        desc: 'Cho gia đình hoặc nhóm bạn thuê trọn căn',
      ),
      RentalSubModel(
        id: 'NHA_PHO',
        title: 'Nhà phố / Mặt tiền',
        desc: 'Vừa ở vừa kinh doanh, vị trí đắc địa',
      ),
      RentalSubModel(
        id: 'CHUNG_CU',
        title: 'Chung cư nguyên căn',
        desc: 'Căn hộ chung cư cho thuê trọn gói',
      ),
      RentalSubModel(
        id: 'VILLA',
        title: 'Biệt thự / Villa',
        desc: 'Nghỉ dưỡng hoặc làm trụ sở công ty',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 3. Ở GHÉP / KÝ TÚC XÁ / BOX  (vận hành theo giường/phòng)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'O_GHEP_KTX',
    emoji: '🛌',
    icon: CupertinoIcons.person_2_fill,
    accent: Color(0xFF8B5CF6),
    title: 'Ở ghép / KTX / Box',
    subtitle:
        'Ký túc xá, sleepbox, phòng ở ghép — cho thuê theo giường hoặc theo phòng tập thể.',
    desc: 'Cho thuê theo giường hoặc phòng tập thể.',
    subModels: [
      RentalSubModel(
        id: 'KTX_TU_NHAN',
        title: 'KTX tư nhân',
        desc: 'Giường tầng có tủ đồ riêng, phòng tập thể',
      ),
      RentalSubModel(
        id: 'KTX_SINH_VIEN',
        title: 'KTX sinh viên',
        desc: 'Phòng 4–8 người, nội quy chặt, giá rẻ',
      ),
      RentalSubModel(
        id: 'SLEEPBOX',
        title: 'Sleepbox cá nhân',
        desc: 'Pod ngủ có khoá riêng, theo giờ hoặc theo đêm',
      ),
      RentalSubModel(
        id: 'O_GHEP',
        title: 'Phòng ở ghép',
        desc: 'Ghép người thuê, chia sẻ chi phí phòng lớn',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 4. KIOT / THƯƠNG MẠI / BÁN LẺ  (cho thuê nguyên khối)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'KIOT_BAN_LE',
    emoji: '🏪',
    icon: CupertinoIcons.bag_fill,
    accent: Color(0xFFF59E0B),
    title: 'Kiot / Bán lẻ',
    subtitle:
        'Kiot chợ, cửa hàng mặt phố, shophouse, showroom — cho thuê mặt bằng kinh doanh.',
    desc: 'Cho thuê mặt bằng kinh doanh nguyên khối.',
    subModels: [
      RentalSubModel(
        id: 'KIOT_CHO',
        title: 'Kiot chợ / Sạp hàng',
        desc: 'Trong chợ truyền thống hoặc trung tâm thương mại',
      ),
      RentalSubModel(
        id: 'CUA_HANG_PHO',
        title: 'Cửa hàng mặt phố',
        desc: 'Nhà phố hoặc toà nhà, 20–200m², giá theo vị trí',
      ),
      RentalSubModel(
        id: 'SHOPHOUSE',
        title: 'Shophouse',
        desc: 'Khu đô thị mới, vừa ở vừa kinh doanh',
      ),
      RentalSubModel(
        id: 'SHOWROOM',
        title: 'Showroom / Trưng bày',
        desc: 'Trưng bày sản phẩm, thời trang, xe cộ…',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 5. VĂN PHÒNG / CO-WORKING  (vận hành theo chỗ ngồi/phòng)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'VAN_PHONG',
    emoji: '💼',
    icon: CupertinoIcons.briefcase_fill,
    accent: Color(0xFF0EA5E9),
    title: 'Văn phòng / Co-working',
    subtitle: 'Văn phòng riêng, co-working, chỗ ngồi làm việc, văn phòng ảo.',
    desc: 'Cho thuê không gian làm việc theo phòng hoặc chỗ ngồi.',
    subModels: [
      RentalSubModel(
        id: 'VP_RIENG',
        title: 'Văn phòng riêng',
        desc: 'Phòng khép kín cho nhóm 2–20 người',
      ),
      RentalSubModel(
        id: 'COWORKING',
        title: 'Co-working / Hot desk',
        desc: 'Không gian mở, thuê theo ngày hoặc theo tháng',
      ),
      RentalSubModel(
        id: 'CHO_NGOI_CD',
        title: 'Chỗ ngồi cố định',
        desc: 'Bàn riêng, tủ khoá, dành cho cá nhân',
      ),
      RentalSubModel(
        id: 'VP_AO',
        title: 'Văn phòng ảo',
        desc: 'Địa chỉ pháp lý + lễ tân, không có chỗ ngồi',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 6. KHO BÃI / NHÀ XƯỞNG  (cho thuê nguyên khối)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'KHO_XUONG',
    emoji: '🏭',
    icon: CupertinoIcons.archivebox_fill,
    accent: Color(0xFF64748B),
    title: 'Kho bãi / Nhà xưởng',
    subtitle:
        'Kho chứa hàng, nhà xưởng sản xuất, bãi đỗ xe — cho thuê mặt bằng công nghiệp.',
    desc: 'Cho thuê mặt bằng công nghiệp nguyên khối.',
    subModels: [
      RentalSubModel(
        id: 'KHO_CA_NHAN',
        title: 'Kho tự quản cá nhân',
        desc: 'Lưu đồ gia đình, hàng TMĐT, mini storage',
      ),
      RentalSubModel(
        id: 'KHO_DN',
        title: 'Kho doanh nghiệp',
        desc: 'Kho hàng lớn, nhập/xuất hàng hoá',
      ),
      RentalSubModel(
        id: 'NHA_XUONG',
        title: 'Nhà xưởng sản xuất',
        desc: 'Gia công, sản xuất nhỏ lẻ',
      ),
      RentalSubModel(
        id: 'BAI_XE',
        title: 'Bãi giữ xe / Đỗ xe',
        desc: 'Gửi xe theo tháng hoặc theo giờ',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 7. KHÔNG GIAN CHUYÊN DỤNG  (cho thuê theo giờ/ngày)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'KHONG_GIAN_CD',
    emoji: '🎬',
    icon: CupertinoIcons.videocam_fill,
    accent: Color(0xFFEC4899),
    title: 'Không gian chuyên dụng',
    subtitle:
        'Studio chụp ảnh, phòng livestream, phòng dạy học, gym/yoga, không gian sự kiện.',
    desc: 'Cho thuê không gian phục vụ mục đích chuyên biệt.',
    subModels: [
      RentalSubModel(
        id: 'STUDIO_CHUP',
        title: 'Studio chụp ảnh',
        desc: 'Phông nền, đèn, phụ kiện chuyên nghiệp',
      ),
      RentalSubModel(
        id: 'PHONG_LIVE',
        title: 'Phòng livestream / Podcast',
        desc: 'Cách âm, greenscreen, thiết bị streaming',
      ),
      RentalSubModel(
        id: 'PHONG_DAY',
        title: 'Phòng dạy học / Đào tạo',
        desc: 'Bảng, máy chiếu, bàn ghế học viên',
      ),
      RentalSubModel(
        id: 'GYM_YOGA',
        title: 'Studio Gym / Yoga',
        desc: 'Sàn gỗ/thảm, gương, không gian tập',
      ),
      RentalSubModel(
        id: 'SU_KIEN',
        title: 'Không gian sự kiện',
        desc: 'Hội nghị, tiệc nhỏ, workshop',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 8. LƯU TRÚ NGẮN HẠN  (cho thuê theo giờ/ngày)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'LUU_TRU',
    emoji: '⏱️',
    icon: CupertinoIcons.clock_fill,
    accent: Color(0xFF14B8A6),
    title: 'Lưu trú ngắn hạn',
    subtitle:
        'Homestay, căn hộ du lịch, phòng theo giờ/ngày, nhà nghỉ tư nhân.',
    desc: 'Cho thuê theo giờ hoặc theo ngày.',
    subModels: [
      RentalSubModel(
        id: 'HOMESTAY',
        title: 'Homestay',
        desc: 'Gia chủ cùng ở, trải nghiệm văn hoá địa phương',
      ),
      RentalSubModel(
        id: 'CANHO_DU_LICH',
        title: 'Căn hộ du lịch',
        desc: 'Airbnb-style, trọn căn hộ, tự nhận phòng',
      ),
      RentalSubModel(
        id: 'PHONG_GIO',
        title: 'Phòng theo giờ',
        desc: 'Nghỉ ngơi ngắn, trả theo từng giờ',
      ),
      RentalSubModel(
        id: 'NHA_NGHI',
        title: 'Nhà nghỉ tư nhân',
        desc: 'Phòng riêng có WC, tự quản lý',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────
  // 10. ĐẤT TRỐNG / MẶT BẰNG BÃI  (cho thuê nguyên khối/mặt bằng)
  // ─────────────────────────────────────────────────────────────
  RentalCategory(
    id: 'DAT_CHO_THUE',
    emoji: '⛳',
    icon: CupertinoIcons.map_pin_ellipse,
    accent: Color(0xFF84CC16),
    title: 'Đất trống / Mặt bằng bãi',
    subtitle:
        'Mặt bằng bãi đất, bãi đỗ xe, sân thể thao, đất vườn nông nghiệp, glamping.',
    desc: 'Cho thuê mặt bằng đất trống theo mét vuông hoặc trọn khu.',
    subModels: [
      RentalSubModel(
        id: 'SAN_THE_THAO',
        title: 'Sân thể thao / Pickleball / Bóng đá',
        desc: 'Đất làm sân tập thể thao, kinh doanh dịch vụ',
      ),
      RentalSubModel(
        id: 'BAI_DO_KHO_BAI',
        title: 'Bãi đỗ xe / Kho lộ thiên',
        desc: 'Bãi giữ xe tải, container, vật liệu xây dựng',
      ),
      RentalSubModel(
        id: 'DAT_NONG_NGHIEP',
        title: 'Vườn sinh thái / Nông trại / Glamping',
        desc: 'Trang trại hữu cơ, khu cắm trại ngoài trời',
      ),
      RentalSubModel(
        id: 'DAT_TRONG_DA_DUNG',
        title: 'Đất trống đa dụng',
        desc: 'Tuỳ biến mục đích sử dụng theo hợp đồng',
      ),
    ],
  ),
];

/// Tra cứu nhanh loại hình cấp 1 theo [id]. Trả về null nếu không tìm thấy.
RentalCategory? rentalCategoryById(String id) {
  for (final c in kRentalCategories) {
    if (c.id == id) return c;
  }
  return null;
}

/// Tra cứu loại hình chi tiết (cấp 2) theo [subId].
///
/// Trả về bản ghi (category, subModel) hoặc null nếu không tìm thấy.
({RentalCategory category, RentalSubModel sub})? rentalSubModelById(
  String subId,
) {
  for (final c in kRentalCategories) {
    for (final s in c.subModels) {
      if (s.id == subId) return (category: c, sub: s);
    }
  }
  return null;
}

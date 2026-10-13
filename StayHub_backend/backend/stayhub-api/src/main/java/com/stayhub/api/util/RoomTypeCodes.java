package com.stayhub.api.util;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Nguồn chân lý DUY NHẤT cho mã loại phòng ở backend.
 *
 * <p>QUY TẮC BẤT DI BẤT DỊCH (đồng bộ với {@code room_type_codes.dart}):</p>
 * <ul>
 *   <li>Mọi request/DB PHẢI dùng MÃ canonical (vd {@code PHONG_TRO}).</li>
 *   <li>Mọi chỗ hiển thị cho người dùng PHẢI dùng NHÃN (vd {@code Phòng trọ}).</li>
 *   <li>Lọc dữ liệu PHẢI theo MÃ (id mô hình) — TUYỆT ĐỐI không lọc theo chữ.</li>
 * </ul>
 *
 * <p>Lớp này thay thế các map nhãn rải rác trước đây và là điểm quy đổi duy
 * nhất giữa mã canonical ↔ nhãn tiếng Việt.</p>
 */
public final class RoomTypeCodes {

    /**
     * Độ dài tối đa của cột {@code rooms.room_sub_type} (length = 30).
     * Mọi mã canonical PHẢI ngắn hơn hoặc bằng ngưỡng này, nếu không sẽ bị
     * PostgreSQL cắt cụt âm thầm → bộ lọc so khớp BẰNG sẽ trượt.
     */
    public static final int MAX_CODE_LENGTH = 30;

    private RoomTypeCodes() {
        // utility class
    }

    /** Mã canonical → Nhãn hiển thị. */
    public static final Map<String, String> CODE_TO_LABEL;

    static {
        Map<String, String> m = new LinkedHashMap<>();
        // ── Phòng trọ / CHDV ──────────────────────────────────────────────
        m.put("PHONG_TRO", "Phòng trọ");
        m.put("CHDV", "CHDV (Chung cư dịch vụ)");
        m.put("STUDIO", "Studio");
        m.put("GAC_LUNG", "Phòng gác lửng");
        // ── Căn hộ / Chung cư ─────────────────────────────────────────────
        m.put("CHUNG_CU_MINI", "Chung cư mini");
        m.put("CHUNG_CU", "Chung cư");
        // ── Nhà nguyên căn ────────────────────────────────────────────────
        m.put("NHA_NGUYEN_CAN", "Nhà nguyên căn");
        // ── Ở ghép / Ký túc xá ────────────────────────────────────────────
        m.put("O_GHEP_KTX", "Ở ghép / Ký túc xá");
        // ── Khác ──────────────────────────────────────────────────────────
        m.put("OFFICE", "Văn phòng");
        m.put("KIOT", "Kiot / Mặt bằng");
        m.put("KHO_BAI", "Kho bãi / Nhà xưởng");
        m.put("KHONG_GIAN_CD", "Không gian");
        m.put("LUU_TRU", "Lưu trú");
        m.put("DAT_CHO_THUE", "Đất trống");
        // Bucket dự phòng: phòng chưa xác định loại (NULL) hoặc loại lạ.
        // Giữ cho phòng vẫn hiển thị/lọc được thay vì biến mất âm thầm.
        m.put("KHAC", "Khác");
        CODE_TO_LABEL = java.util.Collections.unmodifiableMap(m);
    }

    /** Nhãn → Mã canonical (đảo ngược). */
    private static final Map<String, String> LABEL_TO_CODE;

    static {
        Map<String, String> m = new LinkedHashMap<>();
        for (Map.Entry<String, String> e : CODE_TO_LABEL.entrySet()) {
            m.putIfAbsent(e.getValue(), e.getKey());
        }
        LABEL_TO_CODE = java.util.Collections.unmodifiableMap(m);
    }

    /**
     * Quy một giá trị bất kỳ (mã HOẶC nhãn, kể cả alias cũ) về MÃ canonical.
     *
     * @return mã canonical, hoặc {@code null} nếu không nhận diện được.
     */
    public static String toCode(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String trimmed = raw.trim();
        String upper = trimmed.toUpperCase();

        // 1) Đã là mã canonical.
        if (CODE_TO_LABEL.containsKey(upper)) return upper;

        // 2) Là nhãn hiển thị (khớp chính xác).
        String byLabel = LABEL_TO_CODE.get(trimmed);
        if (byLabel != null) return byLabel;

        // 3) Nhãn không phân biệt hoa/thường.
        for (Map.Entry<String, String> e : CODE_TO_LABEL.entrySet()) {
            if (e.getValue().equalsIgnoreCase(trimmed)) return e.getKey();
        }

        // 4) Alias cũ / mã đồng nghĩa → gom về canonical.
        return aliasToCanonical(upper);
    }

    /**
     * Quy một mã (hoặc alias) về tập MÃ CANONICAL dùng để so khớp BẰNG với cột
     * {@code rooms.room_sub_type}. Không chứa nhãn, không dùng LIKE.
     */
    public static Set<String> canonicalCodes(String raw) {
        String code = toCode(raw);
        if (code == null) return Set.of();
        return new LinkedHashSet<>(List.of(code));
    }

    /** Nhãn hiển thị cho một mã. Trả về chính mã nếu không nhận diện được. */
    public static String labelOf(String code) {
        if (code == null || code.isBlank()) return "";
        String key = code.trim().toUpperCase();
        return CODE_TO_LABEL.getOrDefault(key, code.trim());
    }

    /**
     * Trả về mã canonical AN TOÀN để ghi xuống cột {@code room_sub_type}.
     *
     * <p>EDGE CASE: cột DB chỉ dài {@value #MAX_CODE_LENGTH} ký tự. Nếu một mã
     * canonical (do cấu hình sai trong tương lai) vượt ngưỡng, PostgreSQL sẽ
     * cắt cụt âm thầm khiến bộ lọc so khớp BẰNG trượt. Hàm này chặn trước:
     * mã quá dài bị coi là không hợp lệ (trả {@code null}) thay vì ghi rác.</p>
     *
     * @return mã canonical hợp lệ và đủ ngắn, hoặc {@code null}.
     */
    public static String safeCode(String raw) {
        String code = toCode(raw);
        if (code == null) return null;
        if (code.length() > MAX_CODE_LENGTH) return null;
        return code;
    }

    /** Ánh xạ alias/mã đồng nghĩa → mã canonical. */
    private static String aliasToCanonical(String upper) {
        return switch (upper) {
            // ── Phòng trọ / CHDV ──────────────────────────────────────────
            case "PHONG_TRO", "PHONG_TRO_THUONG", "PHONG_THUONG", "PHONG_DON",
                 "PHONG_TRO_DON" -> "PHONG_TRO";
            case "CHDV", "CHUNG_CU_DICH_VU", "CAN_HO_DICH_VU" -> "CHDV";
            case "STUDIO", "PHONG_STUDIO" -> "STUDIO";
            case "GAC_LUNG", "PHONG_GAC_XEP", "PHONG_GAC_LUNG" -> "GAC_LUNG";
            // ── Căn hộ / Chung cư ─────────────────────────────────────────
            case "CHUNG_CU_MINI", "CAN_HO_MINI" -> "CHUNG_CU_MINI";
            case "CHUNG_CU", "CAN_HO_CC", "CHUNG_CU_GIA_DINH", "CAN_HO",
                 "PENTHOUSE_DUPLEX", "OFFICETEL", "1PN" -> "CHUNG_CU";
            // ── Nhà nguyên căn ────────────────────────────────────────────
            case "NHA_NGUYEN_CAN", "NHA_NGO", "NHA_PHO", "SHOPHOUSE", "VILLA",
                 "NHA_RIENG" -> "NHA_NGUYEN_CAN";
            // ── Ở ghép / Ký túc xá ────────────────────────────────────────
            case "KY_TUC_XA", "O_GHEP", "O_GHEP_KTX" -> "O_GHEP_KTX";
            // ── Khác ──────────────────────────────────────────────────────
            case "OFFICE", "VAN_PHONG" -> "OFFICE";
            case "KIOT", "KIOT_BAN_LE", "MAT_BANG" -> "KIOT";
            case "KHO_BAI", "KHO_XUONG" -> "KHO_BAI";
            case "KHONG_GIAN_CD" -> "KHONG_GIAN_CD";
            case "LUU_TRU" -> "LUU_TRU";
            case "DAT_CHO_THUE" -> "DAT_CHO_THUE";
            default -> null;
        };
    }
}

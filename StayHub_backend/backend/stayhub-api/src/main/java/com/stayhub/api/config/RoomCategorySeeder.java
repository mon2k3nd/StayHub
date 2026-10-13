package com.stayhub.api.config;

import com.stayhub.api.util.RoomTypeCodes;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Seeder tạo BẢN GHI MẪU cho MỖI HẠNG MỤC loại phòng của chủ nhà 0326078558
 * (ownerId = 5, branchId = 102) để phân biệt dữ liệu và kiểm chứng bộ lọc.
 *
 * <p>QUY TẮC: mỗi phòng được ghi {@code room_sub_type} = MÃ canonical và
 * {@code detailed_info.roomType} = cùng MÃ canonical. Nhờ vậy bộ lọc guest
 * (lọc theo MÃ, không theo chữ) luôn khớp chính xác 100%.</p>
 *
 * <p>Seeder idempotent: chỉ tạo nếu phòng đánh dấu {@code room_code} tương ứng
 * chưa tồn tại, nên chạy lại nhiều lần không sinh trùng.</p>
 */
@Component
@Order(20) // chạy SAU DatabaseSeeder (mặc định) và sau backfill trong StayhubApplication
@RequiredArgsConstructor
@Slf4j
public class RoomCategorySeeder implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    /**
     * Cờ bật/tắt seeder. MẶC ĐỊNH TẮT để không bao giờ gieo dữ liệu mẫu vào
     * môi trường thật. Bật bằng {@code stayhub.seed.room-categories=true}
     * (vd trong application-dev.yml hoặc qua biến môi trường khi test).
     */
    @Value("${stayhub.seed.room-categories:false}")
    private boolean seedEnabled;

    /** ownerId của chủ nhà 0326078558. */
    private static final long OWNER_ID = 5L;
    /** branchId của chi nhánh chứa các phòng 180/181/182. */
    private static final long BRANCH_ID = 102L;

    /**
     * Danh sách hạng mục mẫu: mã canonical → (tên phòng, giá, diện tích).
     * Dùng LinkedHashMap để thứ tự tạo ổn định, dễ đọc log.
     */
    private static final Map<String, Object[]> CATEGORIES = new LinkedHashMap<>();

    static {
        // mã canonical, tên phòng, giá thuê, diện tích (m2)
        CATEGORIES.put("PHONG_TRO", new Object[]{"P-TRO", 2_500_000.0, 25.0});
        CATEGORIES.put("CHDV", new Object[]{"P-CHDV", 4_500_000.0, 35.0});
        CATEGORIES.put("STUDIO", new Object[]{"P-STUDIO", 5_000_000.0, 30.0});
        CATEGORIES.put("GAC_LUNG", new Object[]{"P-GACLUNG", 3_200_000.0, 28.0});
        CATEGORIES.put("CHUNG_CU_MINI", new Object[]{"P-CCMINI", 6_000_000.0, 45.0});
        CATEGORIES.put("CHUNG_CU", new Object[]{"P-CHUNGCU", 9_000_000.0, 70.0});
        CATEGORIES.put("NHA_NGUYEN_CAN", new Object[]{"P-NHANGUYENCAN", 15_000_000.0, 120.0});
        CATEGORIES.put("O_GHEP_KTX", new Object[]{"P-OGHEP", 1_500_000.0, 20.0});
        CATEGORIES.put("OFFICE", new Object[]{"P-OFFICE", 12_000_000.0, 80.0});
        CATEGORIES.put("KIOT", new Object[]{"P-KIOT", 7_000_000.0, 40.0});
        CATEGORIES.put("KHO_BAI", new Object[]{"P-KHOBAI", 10_000_000.0, 200.0});
    }

    @Override
    public void run(String... args) {
        // EDGE CASE: tuyệt đối không gieo dữ liệu mẫu vào môi trường thật.
        if (!seedEnabled) {
            log.info("[RoomCategorySeeder] Bỏ qua (đặt stayhub.seed.room-categories=true để bật).");
            return;
        }
        try {
            // Chỉ seed khi chủ nhà tồn tại (tránh tạo mồ côi khi DB trống).
            Integer ownerExists = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM rooms WHERE owner_id = ?", Integer.class, OWNER_ID);
            if (ownerExists == null || ownerExists == 0) {
                log.info("[RoomCategorySeeder] Không tìm thấy phòng của owner {} — bỏ qua.", OWNER_ID);
                return;
            }

            int created = 0;
            for (Map.Entry<String, Object[]> e : CATEGORIES.entrySet()) {
                String code = e.getKey();
                String roomName = (String) e.getValue()[0];
                Double price = (Double) e.getValue()[1];
                Double area = (Double) e.getValue()[2];
                String label = RoomTypeCodes.labelOf(code);

                // Idempotent: đã có phòng mẫu (theo room_code) thì bỏ qua.
                Integer exists = jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM rooms WHERE room_code = ?", Integer.class, roomName);
                if (exists != null && exists > 0) {
                    continue;
                }

                // 1) Tạo phòng với room_sub_type = MÃ canonical + detailed_info.roomType = MÃ.
                Long roomId = jdbcTemplate.queryForObject(
                        "INSERT INTO rooms (owner_id, branch_id, room_name, room_code, price, "
                                + "floor_area, status, is_deleted, approval_status, is_public, "
                                + "room_sub_type, detailed_info, created_at, address) "
                                + "VALUES (?, ?, ?, ?, ?, ?, 'TRONG', false, 'APPROVED', true, ?, "
                                + "jsonb_build_object('roomType', ?, 'roomTypeLabel', ?), NOW(), "
                                + "(SELECT address FROM properties WHERE id = ?)) "
                                + "RETURNING id",
                        Long.class,
                        OWNER_ID, BRANCH_ID, roomName, roomName, price, area,
                        code, code, label, BRANCH_ID);

                // 2) Tạo tin đăng ACTIVE để phòng xuất hiện trong tìm kiếm guest.
                jdbcTemplate.update(
                        "INSERT INTO room_posts (room_id, owner_id, post_title, "
                                + "post_description, renting_price, deposit, status, created_at) "
                                + "VALUES (?, ?, ?, ?, ?, ?, 'ACTIVE', NOW())",
                        roomId, OWNER_ID,
                        "[" + label + "] " + roomName + " — phòng mẫu hạng mục " + code,
                        "Bản ghi mẫu cho hạng mục " + label + " (mã " + code + ").",
                        price, price);

                created++;
                log.info("[RoomCategorySeeder] Đã tạo phòng mẫu: id={} code={} ({})",
                        roomId, code, label);
            }

            log.info("[RoomCategorySeeder] Hoàn tất: tạo mới {} phòng mẫu cho owner {} (branch {}).",
                    created, OWNER_ID, BRANCH_ID);
        } catch (Exception ex) {
            log.warn("[RoomCategorySeeder] Lỗi khi tạo phòng mẫu: {}", ex.getMessage());
        }
    }
}

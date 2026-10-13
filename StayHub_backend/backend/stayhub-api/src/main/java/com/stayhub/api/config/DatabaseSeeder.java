package com.stayhub.api.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class DatabaseSeeder implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        log.info("Starting DatabaseSeeder for PropTech 2.0 features...");

        // 1. Seed Reviews if empty
        Integer reviewCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'reviews'", Integer.class);
        
        if (reviewCount != null && reviewCount > 0) {
            Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM reviews", Integer.class);
            if (count != null && count == 0) {
                log.info("Seeding Reviews...");
                // Insert dummy reviews for existing rooms
                jdbcTemplate.update("INSERT INTO reviews (room_id, reviewer_name, content, rating, created_at) " +
                        "SELECT id, 'Nguyễn Văn A', 'Phòng rất sạch sẽ và thoáng mát, chủ nhà nhiệt tình. Gần chỗ làm nên rất tiện.', 5.0, NOW() FROM rooms LIMIT 10");
                jdbcTemplate.update("INSERT INTO reviews (room_id, reviewer_name, content, rating, created_at) " +
                        "SELECT id, 'Trần Thị B', 'An ninh khu vực khá tốt, không ồn ào. Tuy nhiên chỗ để xe hơi hẹp.', 4.0, NOW() - INTERVAL '2 days' FROM rooms LIMIT 10");
                jdbcTemplate.update("INSERT INTO reviews (room_id, reviewer_name, content, rating, created_at) " +
                        "SELECT id, 'Lê Văn C', 'Phòng đúng như mô tả, nội thất mới. Giá hợp lý so với khu vực trung tâm.', 4.5, NOW() - INTERVAL '5 days' FROM rooms LIMIT 10");
            }
        }

        // 2. Update Rooms with Video and POIs
        Integer roomCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM rooms", Integer.class);
        if (roomCount != null && roomCount > 0) {
            log.info("Updating Rooms with Video URL and POIs...");
            jdbcTemplate.update("UPDATE rooms SET video_url = 'https://www.w3schools.com/html/mov_bbb.mp4' WHERE id IN (SELECT id FROM rooms LIMIT 5)");
            jdbcTemplate.update("UPDATE rooms SET pois = '[\"Đại học Quốc gia Hà Nội (500m)\", \"CircleK (50m)\", \"Trạm xe buýt (100m)\", \"Chợ Dịch Vọng (1km)\"]' WHERE pois IS NULL OR pois = '[]' OR pois = ''");
            jdbcTemplate.update("UPDATE rooms SET furniture = '[\"WIFI\", \"AC\", \"HEATER\", \"FRIDGE\", \"WASHER\", \"TV\", \"BED\", \"WARDROBE\", \"PARKING\", \"SECURITY\", \"CAMERA\"]' WHERE furniture IS NULL OR furniture = '[]' OR furniture = ''");
            jdbcTemplate.update("UPDATE rooms SET address = '351, Cầu Giấy, Dịch Vọng, Cầu Giấy, Thành phố Hà Nội' WHERE address IS NULL OR address = ''");
        }

        // 3. Set Super Landlord
        Integer ownerCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'owner_profiles'", Integer.class);
        if (ownerCount != null && ownerCount > 0) {
            log.info("Updating Super Landlords...");
            jdbcTemplate.update("UPDATE owner_profiles SET is_super_landlord = true WHERE id IN (SELECT id FROM owner_profiles LIMIT 2)");
        }

        // 4. Update Tenants with MBTI
        Integer tenantCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'tenant_profiles'", Integer.class);
        if (tenantCount != null && tenantCount > 0) {
            log.info("Updating MBTI for Tenants...");
            jdbcTemplate.update("UPDATE tenant_profiles SET mbti_type = 'ENFP' WHERE id IN (SELECT id FROM tenant_profiles LIMIT 2)");
            jdbcTemplate.update("UPDATE tenant_profiles SET mbti_type = 'INTJ' WHERE mbti_type IS NULL");
            // BUGFIX (data-integrity/security): trước đây câu lệnh này ép TOÀN BỘ
            // tenant_profiles sang kyc_status = 'APPROVED' mỗi lần khởi động, phá
            // hủy trạng thái KYC hợp lệ (PENDING/REJECTED/UNVERIFIED) và vô hiệu
            // hóa toàn bộ luồng xác minh eKYC. Nay chỉ seed demo cho hồ sơ CHƯA
            // từng được xử lý (chưa có CCCD) và đang ở trạng thái UNVERIFIED.
            jdbcTemplate.update("UPDATE tenant_profiles SET kyc_status = 'APPROVED' " +
                    "WHERE kyc_status = 'UNVERIFIED' AND (cccd_number IS NULL OR cccd_number = '')");
        }

        log.info("DatabaseSeeder completed successfully.");
    }
}

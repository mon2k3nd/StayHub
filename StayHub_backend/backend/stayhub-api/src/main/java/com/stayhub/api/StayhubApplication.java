package com.stayhub.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;

import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableScheduling
@EnableCaching
public class StayhubApplication {

	public static void main(String[] args) {
		SpringApplication.run(StayhubApplication.class, args);
	}

	@Bean
	public CommandLineRunner alterTableSchema(JdbcTemplate jdbcTemplate) {
		return args -> {
			try {
				// PostgreSQL: Xoá ràng buộc NOT NULL của cột phone_number (nếu có) do thay đổi logic đăng nhập Google/Facebook/WhatsApp
				jdbcTemplate.execute("ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;");
				System.out.println("Đã xoá ràng buộc NOT NULL cho phone_number thành công.");
			} catch (Exception e) {
				System.out.println("Lỗi khi ALTER TABLE: " + e.getMessage());
			}

			// ── TỰ CHỮA DỮ LIỆU LOẠI PHÒNG ─────────────────────────────────
			// Trước đây luồng cập nhật phòng chỉ ghi `detailed_info.roomType` mà
			// KHÔNG đồng bộ xuống cột canonical `rooms.room_sub_type` → cột NULL
			// → bộ lọc guest (lọc theo MÃ trên room_sub_type) trả về rỗng và
			// phòng hiển thị sai loại. Backfill một lần: quy mọi giá trị cũ
			// (alias/nhãn) về MÃ canonical rồi ghi lại cột.
			try {
				java.util.List<java.util.Map<String, Object>> rows = jdbcTemplate.queryForList(
						"SELECT id, room_sub_type, detailed_info->>'roomType' AS di_type "
								+ "FROM rooms WHERE room_sub_type IS NULL "
								+ "OR room_sub_type = '' "
								+ "OR room_sub_type <> UPPER(room_sub_type)");
				int fixed = 0;
				for (java.util.Map<String, Object> row : rows) {
					Object idObj = row.get("id");
					String current = row.get("room_sub_type") != null
							? row.get("room_sub_type").toString() : null;
					String diType = row.get("di_type") != null
							? row.get("di_type").toString() : null;
					String canonical = com.stayhub.api.util.RoomTypeCodes.toCode(
							current != null && !current.isBlank() ? current : diType);
					if (canonical == null) continue;
					if (canonical.equals(current)) continue;
					jdbcTemplate.update(
							"UPDATE rooms SET room_sub_type = ? WHERE id = ?",
							canonical, idObj);
					fixed++;
				}
				System.out.println("[RoomTypeBackfill] Đã chuẩn hoá room_sub_type cho "
						+ fixed + " phòng (quét " + rows.size() + " bản ghi).");
			} catch (Exception e) {
				System.out.println("[RoomTypeBackfill] Lỗi: " + e.getMessage());
			}
		};
	}
}

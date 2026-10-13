package com.stayhub.api.config;

import com.stayhub.api.entity.Branch;
import com.stayhub.api.entity.Room;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.PropertyRepository;
import com.stayhub.api.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.List;

import com.stayhub.api.entity.SystemFeatureFlag;
import com.stayhub.api.repository.FeatureFlagRepository;

@Component
@RequiredArgsConstructor
@Slf4j
public class DatabaseInitializer {

    private final BranchRepository branchRepository;
    private final PropertyRepository propertyRepository;
    private final RoomRepository roomRepository;
    private final FeatureFlagRepository featureFlagRepository;
    private final org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @EventListener(ApplicationReadyEvent.class)
    public void init() {
        log.info("Starting database initialization and sync...");

        // Seed Feature Flags
        seedFeatureFlags();

        // Drop legacy notification constraint
        try {
            jdbcTemplate.execute("ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check");
            log.info("Dropped notifications_type_check constraint if it existed.");
            
            // Cleanup stuck deleted branches/rooms.
            // LUU Y: chi them hau to _OFF_<id> MOT LAN duy nhat (tranh nhan doi
            // khi app restart nhieu lan). Dung ESCAPE de '_' khong bi hieu la
            // wildcard cua LIKE.
            //
            // QUY TAC 2 LUONG:
            //   • DRAFT da xoa mem  -> xoa cung (coi nhu chua tung ton tai).
            //   • COMPLETED da xoa mem -> SUSPENDED + hau to _OFF_<id>.
            //   • SUSPENDED con ma goc -> gan hau to _OFF_<id>.

            // (1) DRAFT da xoa mem -> xoa cung de giai phong ma hoan toan.
            jdbcTemplate.execute("DELETE FROM shared_facilities WHERE branch_id IN (" +
                    "SELECT id FROM branches WHERE is_deleted = true " +
                    "AND (creation_status IS NULL OR creation_status <> 'COMPLETED'))");
            jdbcTemplate.execute("DELETE FROM rooms WHERE branch_id IN (" +
                    "SELECT id FROM branches WHERE is_deleted = true " +
                    "AND (creation_status IS NULL OR creation_status <> 'COMPLETED'))");
            jdbcTemplate.execute("DELETE FROM branches WHERE is_deleted = true " +
                    "AND (creation_status IS NULL OR creation_status <> 'COMPLETED')");

            // (2) COMPLETED da xoa mem -> SUSPENDED + hau to _OFF_<id>.
            jdbcTemplate.execute("UPDATE branches SET branch_code = branch_code || '_OFF_' || id " +
                    "WHERE is_deleted = true " +
                    "AND creation_status = 'COMPLETED' " +
                    "AND branch_code IS NOT NULL " +
                    "AND branch_code NOT LIKE '%\\_OFF\\_%' ESCAPE '\\' " +
                    "AND branch_code NOT LIKE '%\\_DEL\\_%' ESCAPE '\\'");
            jdbcTemplate.execute("UPDATE branches SET creation_status = 'SUSPENDED', is_deleted = false " +
                    "WHERE is_deleted = true AND creation_status = 'COMPLETED'");

            // (3) Phong cua branch da ngung hoat dong -> dong cua + hau to _OFF_<id>.
            jdbcTemplate.execute("UPDATE rooms SET room_code = room_code || '_OFF_' || id " +
                    "WHERE status = 'DONG_CUA' " +
                    "AND room_code IS NOT NULL " +
                    "AND room_code NOT LIKE '%\\_OFF\\_%' ESCAPE '\\' " +
                    "AND room_code NOT LIKE '%\\_DEL\\_%' ESCAPE '\\'");

            // (4) Branch SUSPENDED con giu ma goc -> gan hau to _OFF_<id>.
            jdbcTemplate.execute("UPDATE branches SET branch_code = branch_code || '_OFF_' || id " +
                    "WHERE creation_status = 'SUSPENDED' " +
                    "AND branch_code IS NOT NULL " +
                    "AND branch_code NOT LIKE '%\\_OFF\\_%' ESCAPE '\\' " +
                    "AND branch_code NOT LIKE '%\\_DEL\\_%' ESCAPE '\\'");
            log.info("Cleaned up stuck deleted room/branch codes.");
        } catch (Exception e) {
            log.warn("Could not drop notifications_type_check constraint or cleanup codes: {}", e.getMessage());
        }

        // 1. Sync branches to properties (each record independently — never crash startup)
        //
        // BUGFIX: trước đây dùng propertyRepository.saveAndFlush(property) với ID
        // được gán tường minh (= branch.getId()). Vì Property.id là
        // @GeneratedValue(IDENTITY), Hibernate coi entity có ID sẵn là DETACHED và
        // phát UPDATE thay vì INSERT. Khi hàng chưa tồn tại, UPDATE khớp 0 dòng →
        // StaleObjectStateException ("Row was updated or deleted by another
        // transaction") cho Property#101/#102 như trong log khởi động, khiến việc
        // đồng bộ properties IM LẶNG thất bại. Nay dùng INSERT native
        // ON CONFLICT DO NOTHING để giữ đúng ID và idempotent, không phụ thuộc
        // trạng thái persistence context.
        try {
            List<Branch> branches = branchRepository.findAll();
            for (Branch branch : branches) {
                try {
                    if (!propertyRepository.existsById(branch.getId())) {
                        int inserted = jdbcTemplate.update(
                                "INSERT INTO properties (id, owner_id, name, address, description, created_at) "
                                        + "VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING",
                                branch.getId(),
                                branch.getOwnerId(),
                                branch.getBranchName(),
                                branch.getAddress(),
                                branch.getDescription(),
                                branch.getCreatedAt() != null
                                        ? java.sql.Timestamp.valueOf(branch.getCreatedAt())
                                        : java.sql.Timestamp.valueOf(java.time.LocalDateTime.now()));
                        if (inserted > 0) {
                            log.info("Synced branch ID {} to properties table", branch.getId());
                        }
                    }
                } catch (Exception ex) {
                    log.warn("Skipping sync for branch ID {} (already up-to-date or concurrent update): {}",
                            branch.getId(), ex.getMessage());
                }
            }
        } catch (Exception e) {
            log.warn("Could not load branches for sync: {}", e.getMessage());
        }

        // 2. Sync rooms property_id (each record independently)
        try {
            List<Room> rooms = roomRepository.findAll();
            for (Room room : rooms) {
                try {
                    if (room.getPropertyId() == null && room.getBranchId() != null) {
                        // Re-fetch to get latest snapshot and avoid StaleObjectState
                        roomRepository.findById(room.getId()).ifPresent(freshRoom -> {
                            if (freshRoom.getPropertyId() == null) {
                                freshRoom.setPropertyId(freshRoom.getBranchId());
                                roomRepository.saveAndFlush(freshRoom);
                                log.info("Set property_id = {} for room ID {}", freshRoom.getBranchId(), freshRoom.getId());
                            }
                        });
                    }
                } catch (Exception ex) {
                    log.warn("Skipping property_id sync for room ID {}: {}", room.getId(), ex.getMessage());
                }
            }
        } catch (Exception e) {
            log.warn("Could not load rooms for sync: {}", e.getMessage());
        }

        // ── Dọn WC chung bị nhân bản do auto-save nhiều lần ──
        try {
            int deleted = jdbcTemplate.update(
                "DELETE FROM shared_facilities WHERE id NOT IN (" +
                "  SELECT min_id FROM (" +
                "    SELECT MIN(id) as min_id " +
                "    FROM shared_facilities " +
                "    GROUP BY branch_id, name, type" +
                "  ) AS keep" +
                ")"
            );
            if (deleted > 0) {
                log.info("Cleaned up {} duplicate shared facility (WC) records.", deleted);
            }
        } catch (Exception e) {
            log.warn("Could not clean up duplicate WC records: {}", e.getMessage());
        }

        log.info("Database initialization completed.");
    }

    private void seedFeatureFlags() {
        try {
            if (!featureFlagRepository.existsById("FEATURE_AI_CHAT")) {
                featureFlagRepository.save(SystemFeatureFlag.builder().featureKey("FEATURE_AI_CHAT").isEnabled(true).description("AI Assistant (Trợ lý ảo)").updatedAt(java.time.LocalDateTime.now()).build());
            }
            if (!featureFlagRepository.existsById("FEATURE_IOT_DEVICES")) {
                featureFlagRepository.save(SystemFeatureFlag.builder().featureKey("FEATURE_IOT_DEVICES").isEnabled(true).description("Smart IoT (Khóa & Công tơ)").updatedAt(java.time.LocalDateTime.now()).build());
            }
            if (!featureFlagRepository.existsById("FEATURE_AUTO_PAYMENT")) {
                featureFlagRepository.save(SystemFeatureFlag.builder().featureKey("FEATURE_AUTO_PAYMENT").isEnabled(true).description("Auto-Reconciliation (VietQR)").updatedAt(java.time.LocalDateTime.now()).build());
            }
            if (!featureFlagRepository.existsById("FEATURE_TRUST_SCORE")) {
                featureFlagRepository.save(SystemFeatureFlag.builder().featureKey("FEATURE_TRUST_SCORE").isEnabled(true).description("Global Trust Score").updatedAt(java.time.LocalDateTime.now()).build());
            }
            log.info("Seed feature flags completed.");
        } catch (Exception e) {
            log.warn("Could not seed feature flags: {}", e.getMessage());
        }
    }
}


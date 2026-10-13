package com.stayhub.api.controller;

import com.stayhub.api.entity.*;
import com.stayhub.api.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/v1/system")
@RequiredArgsConstructor
public class V1DatabaseSeederController {

    private final JdbcTemplate jdbcTemplate;
    private final UserRepository userRepository;
    private final BranchRepository branchRepository;
    private final RoomRepository roomRepository;
    private final ContractRepository contractRepository;
    private final BillRepository billRepository;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/seed")
    public ResponseEntity<String> seedDatabase() {
        try {
            // 1. Truncate tables
            jdbcTemplate.execute("TRUNCATE TABLE branches, rooms, contracts, bills, maintenances, tenant_profiles, owner_profiles, direct_messages, branch_group_messages, thread_messages, conversations, checkout_requests, rental_requests, room_assets, room_devices, room_handovers, reviews, notifications, kyc_requests CASCADE;");

            // 2. Set Owner
            User owner = userRepository.findByPhoneNumber("0774337738").orElseGet(() -> {
                User u = new User();
                u.setName("Phùng Hữu Đô");
                u.setPhoneNumber("0774337738");
                u.setPasswordHash(passwordEncoder.encode("123456"));
                return u;
            });
            owner.setRoleId("OWNER");
            owner.setStatus(User.UserStatus.ACTIVE);
            userRepository.save(owner);

            // Native query for owner_profiles (no repo)
            jdbcTemplate.update("INSERT INTO owner_profiles (user_id) VALUES (?)", owner.getId());

            User tenant1 = userRepository.findByPhoneNumber("0901234567").orElseGet(() -> {
                User u = new User();
                u.setName("Trần Ngọc Trinh");
                u.setPhoneNumber("0901234567");
                u.setPasswordHash(passwordEncoder.encode("123456"));
                return u;
            });
            tenant1.setRoleId("TENANT");
            tenant1.setStatus(User.UserStatus.ACTIVE);
            userRepository.save(tenant1);

            jdbcTemplate.update("INSERT INTO tenant_profiles (user_id, date_of_birth, gender, cccd_number, kyc_status, trust_score) VALUES (?, '2000-01-01', 'FEMALE', '012345678912', 'APPROVED', 100)", tenant1.getId());

            User tenant2 = userRepository.findByPhoneNumber("0988777666").orElseGet(() -> {
                User u = new User();
                u.setName("Nguyễn Văn A");
                u.setPhoneNumber("0988777666");
                u.setPasswordHash(passwordEncoder.encode("123456"));
                return u;
            });
            tenant2.setRoleId("TENANT");
            tenant2.setStatus(User.UserStatus.ACTIVE);
            userRepository.save(tenant2);

            jdbcTemplate.update("INSERT INTO tenant_profiles (user_id, date_of_birth, gender, cccd_number, kyc_status, trust_score) VALUES (?, '1995-05-05', 'MALE', '098765432109', 'APPROVED', 80)", tenant2.getId());

            // Branch
            Branch branch = new Branch();
            branch.setOwnerId(owner.getId());
            branch.setBranchName("StayHub Alpha - Quận 7");
            branch.setAddress("123 Nguyễn Văn Linh");
            branch.setBranchCode("B-ALPHA");
            branch.setTotalRooms(20);
            branch.setIsActive(true);
            branch.setCreationStatus("COMPLETED");
            branchRepository.save(branch);

            // Room 101
            Room room101 = new Room();
            room101.setBranchId(branch.getId());
            room101.setOwnerId(owner.getId());
            room101.setRoomName("101");
            room101.setPrice(3500000.0);
            room101.setStatus(RoomStatus.DA_THUE);
            room101.setCurrentTenantId(tenant1.getId());
            roomRepository.save(room101);

            // Room 102
            Room room102 = new Room();
            room102.setBranchId(branch.getId());
            room102.setOwnerId(owner.getId());
            room102.setRoomName("102");
            room102.setPrice(3500000.0);
            room102.setStatus(RoomStatus.DA_THUE);
            room102.setCurrentTenantId(tenant2.getId());
            roomRepository.save(room102);

            // Room 103
            Room room103 = new Room();
            room103.setBranchId(branch.getId());
            room103.setOwnerId(owner.getId());
            room103.setRoomName("103");
            room103.setPrice(4000000.0);
            room103.setStatus(RoomStatus.TRONG);
            roomRepository.save(room103);

            // Contracts
            Contract c1 = new Contract();
            c1.setRoomId(room101.getId());
            c1.setTenantId(tenant1.getId());
            c1.setOwnerId(owner.getId());
            c1.setStatus(ContractStatus.ACTIVE);
            c1.setStartDate(LocalDate.now().minusMonths(3));
            c1.setEndDate(LocalDate.now().plusMonths(9));
            c1.setDepositAmount(3500000.0);
            c1.setMonthlyRent(3500000.0);
            c1.setElectricityPrice(3500.0);
            c1.setWaterPrice(20000.0);
            c1.setServiceFee(100000.0);
            contractRepository.save(c1);
            
            room101.setCurrentContractId(c1.getId());
            roomRepository.save(room101);

            Contract c2 = new Contract();
            c2.setRoomId(room102.getId());
            c2.setTenantId(tenant2.getId());
            c2.setOwnerId(owner.getId());
            c2.setStatus(ContractStatus.ACTIVE);
            c2.setStartDate(LocalDate.now().minusMonths(1));
            c2.setEndDate(LocalDate.now().plusMonths(11));
            c2.setDepositAmount(3500000.0);
            c2.setMonthlyRent(3500000.0);
            c2.setElectricityPrice(3500.0);
            c2.setWaterPrice(20000.0);
            c2.setServiceFee(100000.0);
            contractRepository.save(c2);

            room102.setCurrentContractId(c2.getId());
            roomRepository.save(room102);

            // Bills
            Bill b1 = new Bill();
            b1.setRoomId(room101.getId());
            b1.setTenantId(tenant1.getId());
            b1.setMonth(LocalDateTime.now().minusMonths(1).getMonthValue());
            b1.setYear(LocalDateTime.now().minusMonths(1).getYear());
            b1.setRentAmount(3500000.0);
            b1.setTotalAmount(3850000.0);
            b1.setIsPaid(true);
            b1.setStatus("PAID");
            b1.setDueDate(LocalDateTime.now().minusDays(15));
            billRepository.save(b1);

            Bill b2 = new Bill();
            b2.setRoomId(room101.getId());
            b2.setTenantId(tenant1.getId());
            b2.setMonth(LocalDateTime.now().getMonthValue());
            b2.setYear(LocalDateTime.now().getYear());
            b2.setRentAmount(3500000.0);
            b2.setTotalAmount(3900000.0);
            b2.setIsPaid(false);
            b2.setStatus("PENDING");
            b2.setDueDate(LocalDateTime.now().plusDays(5));
            billRepository.save(b2);

            Bill b3 = new Bill();
            b3.setRoomId(room102.getId());
            b3.setTenantId(tenant2.getId());
            b3.setMonth(LocalDateTime.now().getMonthValue());
            b3.setYear(LocalDateTime.now().getYear());
            b3.setRentAmount(3500000.0);
            b3.setTotalAmount(3500000.0);
            b3.setIsPaid(true);
            b3.setStatus("PAID");
            b3.setDueDate(LocalDateTime.now().plusDays(2));
            billRepository.save(b3);

            jdbcTemplate.update("INSERT INTO maintenances (room_id, tenant_id, category, description, status, severity, created_at) VALUES (?, ?, 'Sửa chữa', 'Vòi nước nhà vệ sinh bị rỉ', 'NEW', 'HIGH', NOW())", room101.getId(), tenant1.getId());

            // === HISTORICAL DATA FOR CHARTS ===
            
            // Historical Bills for Room 101 (last 6 months)
            for (int i = 6; i >= 2; i--) {
                Bill b = new Bill();
                b.setRoomId(room101.getId());
                b.setTenantId(tenant1.getId());
                b.setMonth(LocalDateTime.now().minusMonths(i).getMonthValue());
                b.setYear(LocalDateTime.now().minusMonths(i).getYear());
                b.setRentAmount(3500000.0);
                b.setTotalAmount(3500000.0 + (i * 150000.0));
                b.setIsPaid(true);
                b.setStatus("PAID");
                b.setPaidAt(LocalDateTime.now().minusMonths(i).plusDays(5));
                b.setDueDate(LocalDateTime.now().minusMonths(i).plusDays(10));
                b.setCreatedAt(LocalDateTime.now().minusMonths(i));
                billRepository.save(b);
            }

            // Historical Bills for Room 102 (last 5 months)
            for (int i = 5; i >= 1; i--) {
                Bill b = new Bill();
                b.setRoomId(room102.getId());
                b.setTenantId(tenant2.getId());
                b.setMonth(LocalDateTime.now().minusMonths(i).getMonthValue());
                b.setYear(LocalDateTime.now().minusMonths(i).getYear());
                b.setRentAmount(3500000.0);
                b.setTotalAmount(3500000.0 + (i * 80000.0));
                b.setIsPaid(true);
                b.setStatus("PAID");
                b.setPaidAt(LocalDateTime.now().minusMonths(i).plusDays(3));
                b.setDueDate(LocalDateTime.now().minusMonths(i).plusDays(10));
                b.setCreatedAt(LocalDateTime.now().minusMonths(i));
                billRepository.save(b);
            }

            // Historical Maintenances
            jdbcTemplate.update("INSERT INTO maintenances (room_id, tenant_id, category, description, status, severity, created_at) VALUES (?, ?, 'Điện', 'Hỏng bóng đèn', 'COMPLETED', 'LOW', NOW() - INTERVAL '4 months')", room101.getId(), tenant1.getId());
            jdbcTemplate.update("INSERT INTO maintenances (room_id, tenant_id, category, description, status, severity, created_at) VALUES (?, ?, 'Nước', 'Nghẹt cống', 'COMPLETED', 'MEDIUM', NOW() - INTERVAL '2 months')", room102.getId(), tenant2.getId());

            // 7. Seed Notifications
            // Unread Rental Request
            jdbcTemplate.update("INSERT INTO notifications (sender_id, receiver_id, title, content, type, is_actionable, action_status, action_metadata, is_read, created_at) VALUES (?, ?, 'Yêu cầu thuê phòng mới', 'Phòng 102 - Tòa A có khách muốn thuê', 'RENTAL_REQUESTED', true, 'PENDING', '{\"endpoint\":\"/v1/rentals/101/approve\",\"method\":\"POST\",\"payload\":{\"customerName\":\"Ngọc Trinh\",\"phoneNumber\":\"0987654321\",\"roomName\":\"Phòng 102 - Tòa A\",\"startDate\":\"2026-06-15\",\"duration\":\"12 tháng\",\"price\":5000000,\"deposit\":5000000,\"note\":\"Khách muốn dọn vào ở ngay đầu tháng sau\"}}', false, NOW())", tenant1.getId(), owner.getId());

            // Read Checkout Request
            jdbcTemplate.update("INSERT INTO notifications (sender_id, receiver_id, title, content, type, is_actionable, action_status, action_metadata, is_read, created_at) VALUES (?, ?, 'Yêu cầu trả phòng', 'Khách hàng phòng 101 muốn trả phòng', 'CHECKOUT_REQUESTED', true, 'PENDING', '{\"endpoint\":\"/v1/checkouts/101/approve\",\"method\":\"POST\",\"payload\":{\"customerName\":\"Khách hàng 1\",\"phoneNumber\":\"0123456789\",\"roomName\":\"Phòng 101 - Tòa A\",\"contractCode\":\"HD-101\",\"startDate\":\"2025-01-01\",\"endDate\":\"2025-12-31\",\"deposit\":3000000,\"targetDate\":\"2025-06-30\",\"note\":\"Chuyển chỗ làm\"}}', true, NOW())", tenant1.getId(), owner.getId());

            // Unread Maintenance
            jdbcTemplate.update("INSERT INTO notifications (sender_id, receiver_id, title, content, type, is_read, created_at) VALUES (?, ?, 'Yêu cầu sửa chữa', 'Phòng 101 bị hỏng vòi nước', 'MAINTENANCE_ASSIGNED', false, NOW())", tenant1.getId(), owner.getId());

            return ResponseEntity.ok("Database seeded successfully via Spring Data JPA!");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Error: " + e.getMessage());
        }
    }
}

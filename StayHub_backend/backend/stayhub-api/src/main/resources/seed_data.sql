-- 1. Xóa toàn bộ dữ liệu (ngoại trừ users để giữ phiên đăng nhập)
TRUNCATE TABLE branches, rooms, contracts, bills, maintenances, tenant_profiles, owner_profiles, direct_messages, branch_group_messages, thread_messages, conversations, checkout_requests, rental_requests, room_assets, room_devices, room_handovers, reviews, notifications, kyc_requests CASCADE;

-- 2. Đảm bảo Owner Phùng Hữu Đô có role OWNER và lấy ID
UPDATE users SET role_id = 'OWNER', status = 'ACTIVE' WHERE phone_number = '0774337738';

DO $$ 
DECLARE 
    owner_id BIGINT;
    branch_id BIGINT;
    room_101 BIGINT;
    room_102 BIGINT;
    room_103 BIGINT;
    tenant_1 BIGINT;
    tenant_2 BIGINT;
BEGIN 
    SELECT id INTO owner_id FROM users WHERE phone_number = '0774337738' LIMIT 1;
    IF owner_id IS NULL THEN
        INSERT INTO users (name, phone_number, password_hash, role_id, status, created_at, updated_at)
        VALUES ('Phùng Hữu Đô', '0774337738', '$2a$10$dummyHash', 'OWNER', 'ACTIVE', NOW(), NOW())
        RETURNING id INTO owner_id;
    END IF;

    -- Tạo profile cho owner
    INSERT INTO owner_profiles (user_id, trust_score, joined_date, owner_name) 
    VALUES (owner_id, 5, NOW(), 'Phùng Hữu Đô');

    -- Insert Khách thuê mẫu
    INSERT INTO users (name, phone_number, password_hash, role_id, status, created_at, updated_at)
    VALUES ('Trần Ngọc Trinh', '0901234567', '$2a$10$dummy', 'TENANT', 'ACTIVE', NOW(), NOW())
    RETURNING id INTO tenant_1;

    INSERT INTO tenant_profiles (user_id, dob, gender, id_card_number, kyc_status, trust_score)
    VALUES (tenant_1, '2000-01-01', 'FEMALE', '012345678912', 'VERIFIED', 5);

    INSERT INTO users (name, phone_number, password_hash, role_id, status, created_at, updated_at)
    VALUES ('Nguyễn Văn A', '0988777666', '$2a$10$dummy', 'TENANT', 'ACTIVE', NOW(), NOW())
    RETURNING id INTO tenant_2;

    INSERT INTO tenant_profiles (user_id, dob, gender, id_card_number, kyc_status, trust_score)
    VALUES (tenant_2, '1995-05-05', 'MALE', '098765432109', 'VERIFIED', 4);

    -- Insert Branch
    INSERT INTO branches (owner_id, name, branch_code, address, city, district, ward, total_rooms, is_active, created_at, updated_at, creation_status)
    VALUES (owner_id, 'StayHub Alpha - Quận 7', 'B-ALPHA', '123 Nguyễn Văn Linh', 'Hồ Chí Minh', 'Quận 7', 'Tân Phong', 20, true, NOW(), NOW(), 'COMPLETED')
    RETURNING id INTO branch_id;

    -- Insert Rooms
    INSERT INTO rooms (branch_id, owner_id, room_name, floor, room_area, base_price, status, current_tenant_id, created_at, updated_at)
    VALUES (branch_id, owner_id, '101', 1, 25.0, 3500000, 'DA_THUE', tenant_1, NOW(), NOW())
    RETURNING id INTO room_101;

    INSERT INTO rooms (branch_id, owner_id, room_name, floor, room_area, base_price, status, current_tenant_id, created_at, updated_at)
    VALUES (branch_id, owner_id, '102', 1, 25.0, 3500000, 'DA_THUE', tenant_2, NOW(), NOW())
    RETURNING id INTO room_102;

    INSERT INTO rooms (branch_id, owner_id, room_name, floor, room_area, base_price, status, current_tenant_id, created_at, updated_at)
    VALUES (branch_id, owner_id, '103', 1, 30.0, 4000000, 'TRONG', null, NOW(), NOW())
    RETURNING id INTO room_103;

    -- Insert Contracts
    INSERT INTO contracts (room_id, tenant_id, owner_id, status, start_date, end_date, deposit_amount, monthly_rent, created_at, updated_at)
    VALUES (room_101, tenant_1, owner_id, 'ACTIVE', NOW() - INTERVAL '3 months', NOW() + INTERVAL '9 months', 3500000, 3500000, NOW(), NOW());

    INSERT INTO contracts (room_id, tenant_id, owner_id, status, start_date, end_date, deposit_amount, monthly_rent, created_at, updated_at)
    VALUES (room_102, tenant_2, owner_id, 'ACTIVE', NOW() - INTERVAL '1 months', NOW() + INTERVAL '11 months', 3500000, 3500000, NOW(), NOW());

    -- Insert Bills (Hóa đơn)
    -- Hóa đơn tháng trước cho phòng 101 (Đã thanh toán)
    INSERT INTO bills (room_id, tenant_id, title, month, year, base_rent, total_amount, is_paid, status, created_at, due_date)
    VALUES (room_101, tenant_1, 'Tiền phòng Tháng trước', EXTRACT(MONTH FROM NOW() - INTERVAL '1 month'), EXTRACT(YEAR FROM NOW() - INTERVAL '1 month'), 3500000, 3850000, true, 'PAID', NOW() - INTERVAL '20 days', NOW() - INTERVAL '15 days');
    
    -- Hóa đơn tháng này cho phòng 101 (Chưa thanh toán)
    INSERT INTO bills (room_id, tenant_id, title, month, year, base_rent, total_amount, is_paid, status, created_at, due_date)
    VALUES (room_101, tenant_1, 'Tiền phòng Tháng này', EXTRACT(MONTH FROM NOW()), EXTRACT(YEAR FROM NOW()), 3500000, 3900000, false, 'UNPAID', NOW() - INTERVAL '2 days', NOW() + INTERVAL '5 days');

    -- Hóa đơn tháng này cho phòng 102 (Đã thanh toán)
    INSERT INTO bills (room_id, tenant_id, title, month, year, base_rent, total_amount, is_paid, status, created_at, due_date)
    VALUES (room_102, tenant_2, 'Tiền phòng Tháng này', EXTRACT(MONTH FROM NOW()), EXTRACT(YEAR FROM NOW()), 3500000, 3500000, true, 'PAID', NOW() - INTERVAL '3 days', NOW() + INTERVAL '2 days');

    -- Insert Maintainance
    INSERT INTO maintenances (owner_id, room_id, tenant_id, title, description, status, priority, created_at)
    VALUES (owner_id, room_101, tenant_1, 'Hỏng vòi nước', 'Vòi nước nhà vệ sinh bị rỉ', 'NEW', 'HIGH', NOW() - INTERVAL '1 days');

    INSERT INTO maintenances (owner_id, room_id, tenant_id, title, description, status, priority, created_at)
    VALUES (owner_id, room_102, tenant_2, 'Điều hòa không mát', 'Điều hòa phòng 102 phả ra hơi nóng', 'IN_PROGRESS', 'MEDIUM', NOW() - INTERVAL '2 days');

    -- Insert more bills
    INSERT INTO bills (room_id, tenant_id, contract_id, type, month, year, rent_amount, total_amount, is_paid, status, created_at, due_date)
    VALUES (room_101, tenant_1, null, 'MONTHLY', EXTRACT(MONTH FROM NOW() - INTERVAL '2 month'), EXTRACT(YEAR FROM NOW() - INTERVAL '2 month'), 3500000, 3900000, true, 'PAID', NOW() - INTERVAL '50 days', NOW() - INTERVAL '45 days');

    -- Insert Direct Messages (Chat Owner - Tenant)
    INSERT INTO direct_messages (sender_id, receiver_id, content, created_at, message_type)
    VALUES (tenant_1, owner_id, 'Chào anh/chị, cho em hỏi tiền phòng tháng này bao nhiêu ạ?', NOW() - INTERVAL '2 hours', 'TEXT');
    
    INSERT INTO direct_messages (sender_id, receiver_id, content, created_at, message_type)
    VALUES (owner_id, tenant_1, 'Chào em, tiền phòng tháng này là 3tr9 nhé. Em check trong app phần hóa đơn nha.', NOW() - INTERVAL '1 hours', 'TEXT');

    INSERT INTO direct_messages (sender_id, receiver_id, content, created_at, message_type)
    VALUES (tenant_2, owner_id, 'Anh ơi hôm qua em báo sửa điều hòa, bao giờ thợ qua ạ?', NOW() - INTERVAL '1 days', 'TEXT');

    -- Insert Branch Group Messages
    INSERT INTO branch_group_messages (branch_id, content, created_at, message_type, room_number, sender_id, sender_name, sender_role)
    VALUES (branch_id, 'Chào mọi người, tôi là chủ nhà. Có vấn đề gì về điện nước mọi người cứ nhắn lên đây nhé!', NOW() - INTERVAL '7 days', 'TEXT', null, owner_id, 'Phùng Hữu Đô', 'OWNER');

    INSERT INTO branch_group_messages (branch_id, content, created_at, message_type, room_number, sender_id, sender_name, sender_role)
    VALUES (branch_id, 'Người thuê mới đã tham gia nhóm nhà từ Phòng 101', NOW() - INTERVAL '6 days', 'TEXT', null, null, null, 'SYSTEM');

    INSERT INTO branch_group_messages (branch_id, content, created_at, message_type, room_number, sender_id, sender_name, sender_role)
    VALUES (branch_id, 'Chào cả nhà, mình mới chuyển đến phòng 101 ạ.', NOW() - INTERVAL '6 days', 'TEXT', '101', tenant_1, 'Trần Ngọc Trinh', 'TENANT');
    
    INSERT INTO branch_group_messages (branch_id, content, created_at, message_type, room_number, sender_id, sender_name, sender_role)
    VALUES (branch_id, 'Chào bạn nha', NOW() - INTERVAL '5 days', 'TEXT', '102', tenant_2, 'Nguyễn Văn A', 'TENANT');

END $$;

package com.stayhub.api.service.impl;

import com.stayhub.api.entity.*;
import com.stayhub.api.repository.*;
import com.stayhub.api.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.LinkedHashMap;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@RequiredArgsConstructor
@Slf4j
public class V1TicketServiceImpl implements V1TicketService {

    private final MaintenanceRepository maintenanceRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final StaffWalletRepository staffWalletRepository;
    private final FinancialReportRepository financialReportRepository;
    private final CloudStorageService cloudStorageService;
    private final NotificationService notificationService;
    private final WebSocketSessionManager webSocketSessionManager;
    private final StaffAssignmentRepository staffAssignmentRepository;
    private final BranchRepository branchRepository;
    private final ExpenseRepository expenseRepository;
    private final RoommateRepository roommateRepository;
    private final RoomServicePoolRepository roomServicePoolRepository;
    private final SharedFacilityRepository sharedFacilityRepository;
    private final BillRepository billRepository;
    private final ObjectMapper objectMapper;

    @Override
    public java.util.List<Maintenance> getTicketsByTenant(Long tenantId) {
        java.util.List<Maintenance> list = maintenanceRepository.findByTenantId(tenantId);
        return populateTransientFieldsBatch(list);
    }

    @Override
    public java.util.List<Maintenance> getTicketsByOwner(Long ownerId) {
        java.util.List<Maintenance> list = maintenanceRepository.findByOwnerId(ownerId);
        return populateTransientFieldsBatch(list);
    }

    @Override
    public java.util.List<Maintenance> getTicketsByStaff(Long staffId) {
        java.util.List<Long> branchIds = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(staffId)
                .stream()
                .map(StaffAssignment::getBranchId)
                .collect(java.util.stream.Collectors.toList());
        if (branchIds.isEmpty()) {
            branchIds = java.util.Collections.singletonList(-1L);
        }
        java.util.List<Maintenance> list = maintenanceRepository.findForStaff(staffId, branchIds);
        return populateTransientFieldsBatch(list);
    }

    @Override
    public Maintenance getTicketById(Long id) {
        Maintenance m = maintenanceRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố ID: " + id));
        return populateTransientFields(m);
    }

    @Override
    @Transactional
    public Maintenance createTicket(Long tenantId, Long roomId, String category, String description, String severity, String tenantDesire, MultipartFile image) {
        return createTicket(tenantId, roomId, null, null, category, description, severity, tenantDesire, image);
    }

    @Override
    @Transactional
    public Maintenance createTicketWithPool(Long tenantId, Long roomId, Long poolId, String category, String description, String severity, String tenantDesire, MultipartFile image) {
        return createTicket(tenantId, roomId, poolId, null, category, description, severity, tenantDesire, image);
    }

    @Override
    @Transactional
    public Maintenance createTicketWithFacility(Long tenantId, Long roomId, Long facilityId, String category, String description, String severity, String tenantDesire, MultipartFile image) {
        return createTicket(tenantId, roomId, null, facilityId, category, description, severity, tenantDesire, image);
    }

    @Transactional
    private Maintenance createTicket(Long tenantId, Long roomId, Long poolId, Long sharedFacilityId, String category, String description, String severity, String tenantDesire, MultipartFile image) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng trọ ID: " + roomId));

        // 1. Upload ảnh (nếu có)
        String imageUrl = (image != null && !image.isEmpty()) ? cloudStorageService.uploadFile(image) : null;

        // 2. Lưu sự cố
        Maintenance maintenance = Maintenance.builder()
                .roomId(roomId)
                .tenantId(tenantId)
                .poolId(poolId)
                .sharedFacilityId(sharedFacilityId)
                .category(category)
                .description(description)
                .severity(severity != null ? severity : "MEDIUM")
                .tenantDesire(tenantDesire)
                .proofImageUrl(imageUrl)
                .status("NEW")
                .build();
        maintenance = maintenanceRepository.save(maintenance);

        // 3. Gửi thông báo đến chủ nhà (owner)
        Long ownerId = room.getOwnerId();
        String title = "Yêu cầu sửa chữa mới";
        String body = "Có yêu cầu sửa chữa mới tại phòng " + room.getRoomName() + ": " + description;

        // Build Action Metadata Payload
        Map<String, Object> payloadMap = new LinkedHashMap<>();
        payloadMap.put("roomName", room.getRoomName());
        
        String branchName = "";
        if (room.getBranchId() != null) {
            Branch branch = branchRepository.findById(room.getBranchId()).orElse(null);
            if (branch != null) branchName = branch.getBranchName();
        }
        payloadMap.put("branchName", branchName);
        
        User tenant = userRepository.findById(tenantId).orElse(null);
        payloadMap.put("customerName", tenant != null ? tenant.getName() : "Khách hàng");
        payloadMap.put("phoneNumber", tenant != null ? tenant.getPhoneNumber() : "");
        
        payloadMap.put("issueType", category);
        payloadMap.put("priority", severity != null ? severity : "MEDIUM");
        payloadMap.put("imageCount", (imageUrl != null && !imageUrl.isEmpty()) ? 1 : 0);
        payloadMap.put("imageUrl", imageUrl);
        payloadMap.put("description", description);

        Map<String, Object> metaMap = new LinkedHashMap<>();
        metaMap.put("payload", payloadMap);
        String metadataStr = null;
        try {
            metadataStr = objectMapper.writeValueAsString(metaMap);
        } catch (Exception e) {
            log.error("Failed to parse ticket metadata", e);
        }

        // Lưu vào DB notifications
        notificationService.send(tenantId, ownerId, NotificationScope.INDIVIDUAL, title, body, NotificationType.MAINTENANCE_ASSIGNED, maintenance.getId(), true, NotificationActionStatus.PENDING, metadataStr);

        // WebSocket push to owner
        webSocketSessionManager.sendEvent(ownerId, "{\"event\": \"new_ticket\", \"ticketId\": " + maintenance.getId() + "}");

        // 4. Nếu sự cố thuộc Pool → gửi thông báo đến tất cả tenant các phòng trong Pool
        if (poolId != null) {
            String poolTitle = "⚠️ Thông báo sự cố điện/nước chung";
            String poolBody = category + ": " + description + " - Đang xử lý. Xin lỗi về sự bất tiện này!";
            final String finalMetadata = metadataStr;
            final Long ticketId = maintenance.getId();
            roomServicePoolRepository.findByPoolId(poolId).forEach(rsp -> {
                try {
                    Room affectedRoom = roomRepository.findById(rsp.getRoomId()).orElse(null);
                    if (affectedRoom != null && affectedRoom.getCurrentTenantId() != null
                            && !affectedRoom.getCurrentTenantId().equals(tenantId)) {
                        notificationService.send(
                            tenantId,
                            affectedRoom.getCurrentTenantId(),
                            NotificationScope.INDIVIDUAL,
                            poolTitle,
                            poolBody,
                            NotificationType.MAINTENANCE_ASSIGNED,
                            ticketId,
                            false,
                            NotificationActionStatus.PENDING,
                            finalMetadata
                        );
                        webSocketSessionManager.sendEvent(affectedRoom.getCurrentTenantId(),
                            "{\"event\": \"pool_incident\", \"ticketId\": " + ticketId + "}");
                    }
                } catch (Exception ex) {
                    log.warn("Failed to notify room {} for pool incident", rsp.getRoomId(), ex);
                }
            });
        }

        return populateTransientFields(maintenance);
    }

    @Override
    @Transactional
    public Maintenance assignTicket(Long ownerId, Long ticketId, Long assignedStaffId) {
        Maintenance maintenance = maintenanceRepository.findById(ticketId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố ID: " + ticketId));

        Room room = roomRepository.findById(maintenance.getRoomId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng trọ"));

        if (!room.getOwnerId().equals(ownerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền giao việc cho sự cố này");
        }

        // Cập nhật status và nhân viên phân công
        maintenance.setStatus("ASSIGNED");
        maintenance.setAssignedStaffId(assignedStaffId);
        maintenance = maintenanceRepository.save(maintenance);

        // Thông báo cho nhân viên
        String title = "Bạn nhận ca sửa chữa mới";
        String body = "Chủ nhà đã giao ca sửa chữa mới cho bạn tại phòng " + room.getRoomName();
        notificationService.send(ownerId, assignedStaffId, NotificationScope.INDIVIDUAL, title, body, NotificationType.MAINTENANCE_ASSIGNED, ticketId, false, null, null);

        webSocketSessionManager.sendEvent(assignedStaffId, "{\"event\": \"ticket_assigned\", \"ticketId\": " + ticketId + "}");

        return populateTransientFields(maintenance);
    }

    @Override
    @Transactional
    public Maintenance completeTicket(Long staffId, Long ticketId, Double materialCost, Boolean isSuccessful, String repairDetails, MultipartFile image) {
        Maintenance maintenance = maintenanceRepository.findById(ticketId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố ID: " + ticketId));

        if (maintenance.getAssignedStaffId() == null || !maintenance.getAssignedStaffId().equals(staffId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ca sửa chữa này không được phân công cho bạn");
        }

        // Upload ảnh nghiệm thu (nếu có)
        if (image != null && !image.isEmpty()) {
            String imageUrl = cloudStorageService.uploadFile(image);
            maintenance.setProofImageUrl(imageUrl);
        }

        maintenance.setStatus("COMPLETED");
        maintenance.setIsSuccessful(isSuccessful != null ? isSuccessful : true);
        
        String timestampStr = "[" + java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").format(java.time.LocalDateTime.now()) + "]";
        String prefix = isSuccessful != null && !isSuccessful ? "[BÁO CÁO THẤT BẠI] " : "[BÁO CÁO THÀNH CÔNG] ";
        String currentDetails = maintenance.getRepairDetails() == null ? "" : maintenance.getRepairDetails() + "\n";
        maintenance.setRepairDetails(currentDetails + timestampStr + " " + prefix + (repairDetails != null ? repairDetails : ""));
        
        maintenance.setMaterialCost(materialCost != null ? materialCost : 0.0);
        maintenance = maintenanceRepository.save(maintenance);

        // Thông báo cho chủ phòng trọ
        Room room = roomRepository.findById(maintenance.getRoomId()).orElse(null);
        if (room != null) {
            Long ownerId = room.getOwnerId();
            String title = "Ca sửa chữa hoàn thành";
            String body = "Nhân viên đã hoàn thành sửa chữa phòng " + room.getRoomName() + ". Vui lòng phê duyệt chi phí.";
            notificationService.send(staffId, ownerId, NotificationScope.INDIVIDUAL, title, body, NotificationType.MAINTENANCE_RESOLVED, ticketId, false, null, null);
            webSocketSessionManager.sendEvent(ownerId, "{\"event\": \"ticket_resolved\", \"ticketId\": " + maintenance.getId() + "}");
        }

        return populateTransientFields(maintenance);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Maintenance ownerCompleteTicket(Long ownerId, Long ticketId, Double materialCost, Boolean isSuccessful, String repairDetails, MultipartFile image) {
        Maintenance maintenance = maintenanceRepository.findById(ticketId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố ID: " + ticketId));

        Room room = roomRepository.findById(maintenance.getRoomId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng trọ"));

        if (!room.getOwnerId().equals(ownerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xử lý sự cố này");
        }

        // Tải ảnh lên (nếu có)
        if (image != null && !image.isEmpty()) {
            String imageUrl = cloudStorageService.uploadFile(image);
            maintenance.setProofImageUrl(imageUrl);
        }

        maintenance.setStatus("CLOSED");
        maintenance.setIsSuccessful(isSuccessful != null ? isSuccessful : true);
        
        String timestampStr = "[" + java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").format(java.time.LocalDateTime.now()) + "]";
        String currentDetails = maintenance.getRepairDetails() == null ? "" : maintenance.getRepairDetails() + "\n";
        maintenance.setRepairDetails(currentDetails + timestampStr + " [CHỦ NHÀ NGHIỆM THU] " + (repairDetails != null ? repairDetails : ""));
        
        maintenance.setMaterialCost(materialCost != null ? materialCost : 0.0);
        maintenance.setStaffBonus(0.0); // Tự làm nên không có thưởng nhân viên
        maintenance = maintenanceRepository.save(maintenance);

        double totalExpense = maintenance.getMaterialCost();
        
        if (totalExpense > 0) {
            // Lưu vào FinancialReport
            FinancialReport report = FinancialReport.builder()
                    .ownerId(ownerId)
                    .type("EXPENSE")
                    .amount(totalExpense)
                    .description("Chi phí tự sửa chữa phòng " + room.getRoomName() + " (Vật tư: " + materialCost + ")")
                    .build();
            financialReportRepository.save(report);

            // Lưu trực tiếp vào sổ Thu Chi (Expense)
            Expense expense = Expense.builder()
                    .ownerId(ownerId)
                    .branchId(room.getBranchId())
                    .category("REPAIR")
                    .description("Tự sửa chữa phòng " + room.getRoomName() + " (Sự cố #" + ticketId + ")")
                    .amount(totalExpense)
                    .expenseDate(java.time.LocalDate.now())
                    .receiptImage(maintenance.getProofImageUrl())
                    .build();
            expenseRepository.save(expense);
        }

        processSharedFacilityCost(maintenance);

        return populateTransientFields(maintenance);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void approveTicket(Long ownerId, Long ticketId, Double staffBonus) {
        Maintenance maintenance = maintenanceRepository.findById(ticketId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố ID: " + ticketId));

        Room room = roomRepository.findById(maintenance.getRoomId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng trọ"));

        if (!room.getOwnerId().equals(ownerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền phê duyệt sự cố này");
        }

        if (!"COMPLETED".equals(maintenance.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ có thể phê duyệt sự cố đã hoàn thành");
        }

        // 1. Cập nhật cố định trạng thái CLOSED và staff_bonus
        maintenance.setStatus("CLOSED");
        maintenance.setStaffBonus(staffBonus != null ? staffBonus : 0.0);
        maintenanceRepository.save(maintenance);

        Double materialCost = maintenance.getMaterialCost();
        Long staffId = maintenance.getAssignedStaffId();

        // 2. Nếu nhân viên tự ứng tiền mua vật tư (material_cost > 0), cập nhật ví nhân viên
        if (materialCost != null && materialCost > 0) {
            if (staffId == null) {
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Không tìm thấy nhân viên của ca sửa chữa");
            }
            StaffWallet wallet = staffWalletRepository.findByStaffId(staffId)
                    .orElseGet(() -> StaffWallet.builder()
                            .staffId(staffId)
                            .cashCollected(0.0)
                            .cashSpent(0.0)
                            .build());
            wallet.setCashSpent(wallet.getCashSpent() + materialCost);
            staffWalletRepository.save(wallet);
        }

        // 3. Tạo báo cáo chi phí cho chủ nhà
        double totalExpense = (materialCost != null ? materialCost : 0.0) + (staffBonus != null ? staffBonus : 0.0);
        FinancialReport report = FinancialReport.builder()
                .ownerId(ownerId)
                .type("EXPENSE")
                .amount(totalExpense)
                .description("Chi phí sửa chữa phòng " + room.getRoomName() + " (Vật tư: " + materialCost + ", Thưởng: " + staffBonus + ")")
                .build();
        financialReportRepository.save(report);

        // 4. Lưu trực tiếp vào sổ Thu Chi (Expense) để hiển thị ngoài màn hình chính
        if (totalExpense > 0) {
            Expense expense = Expense.builder()
                    .ownerId(ownerId)
                    .branchId(room.getBranchId())
                    .category("REPAIR")
                    .description("Sửa chữa phòng " + room.getRoomName() + " (Sự cố #" + ticketId + ")")
                    .amount(totalExpense)
                    .expenseDate(java.time.LocalDate.now())
                    .receiptImage(maintenance.getProofImageUrl())
                    .build();
            expenseRepository.save(expense);
        }

        // Thông báo cho nhân viên
        if (staffId != null) {
            String title = "Ca sửa chữa được duyệt";
            String body = "Chủ nhà đã duyệt ca sửa chữa của bạn. Thưởng: " + staffBonus;
            notificationService.send(ownerId, staffId, NotificationScope.INDIVIDUAL, title, body, NotificationType.MAINTENANCE_RESOLVED, ticketId, false, null, null);
            webSocketSessionManager.sendEvent(staffId, "{\"event\": \"ticket_verified\", \"ticketId\": " + maintenance.getId() + "}");
        }

        processSharedFacilityCost(maintenance);
    }

    @Override
    @Transactional
    public void cancelTicket(Long ownerId, Long ticketId, String reason) {
        Maintenance maintenance = maintenanceRepository.findById(ticketId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố"));

        Room room = roomRepository.findById(maintenance.getRoomId()).orElse(null);
        if (room == null || !room.getOwnerId().equals(ownerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Không có quyền");
        }

        maintenance.setStatus("REJECTED");
        String timestampStr = "[" + java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").format(java.time.LocalDateTime.now()) + "]";
        String currentDetails = maintenance.getRepairDetails() == null ? "" : maintenance.getRepairDetails() + "\n";
        maintenance.setRepairDetails(currentDetails + timestampStr + " [CHỦ NHÀ HỦY YÊU CẦU] Lý do: " + reason);
        maintenanceRepository.save(maintenance);
        
        Long staffId = maintenance.getAssignedStaffId();
        if (staffId != null) {
            String title = "Sự cố đã bị hủy";
            String body = "Chủ nhà đã hủy yêu cầu xử lý sự cố phòng " + room.getRoomName() + " với lý do: " + reason;
            notificationService.send(ownerId, staffId, NotificationScope.INDIVIDUAL, title, body, NotificationType.MAINTENANCE_RESOLVED, ticketId, false, null, null);
        }
    }

    @Override
    @Transactional
    public void rejectTicket(Long ownerId, Long ticketId, String reason) {
        Maintenance maintenance = maintenanceRepository.findById(ticketId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố"));

        Room room = roomRepository.findById(maintenance.getRoomId()).orElse(null);
        if (room == null || !room.getOwnerId().equals(ownerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Không có quyền");
        }

        if (!"COMPLETED".equals(maintenance.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ có thể từ chối sự cố đang ở trạng thái chờ duyệt (COMPLETED)");
        }

        maintenance.setStatus("PROCESSING"); // Quay lại cho staff làm tiếp
        String timestampStr = "[" + java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").format(java.time.LocalDateTime.now()) + "]";
        String currentDetails = maintenance.getRepairDetails() == null ? "" : maintenance.getRepairDetails() + "\n";
        maintenance.setRepairDetails(currentDetails + timestampStr + " [TỪ CHỐI NGHIỆM THU] Lý do: " + reason);
        maintenanceRepository.save(maintenance);

        Long staffId = maintenance.getAssignedStaffId();
        if (staffId != null) {
            String title = "Nghiệm thu bị từ chối";
            String body = "Chủ nhà đã từ chối báo cáo của bạn ở phòng " + room.getRoomName() + ". Vui lòng kiểm tra lại. Lý do: " + reason;
            notificationService.send(ownerId, staffId, NotificationScope.INDIVIDUAL, title, body, NotificationType.MAINTENANCE_ASSIGNED, ticketId, false, null, null);
            webSocketSessionManager.sendEvent(staffId, "{\"event\": \"ticket_rejected\", \"ticketId\": " + ticketId + "}");
        }
    }


    private java.util.List<Maintenance> populateTransientFieldsBatch(java.util.List<Maintenance> list) {
        if (list == null || list.isEmpty()) return list;

        java.util.Set<Long> tenantIds = list.stream().map(Maintenance::getTenantId).filter(java.util.Objects::nonNull).collect(java.util.stream.Collectors.toSet());
        java.util.Set<Long> roomIds = list.stream().map(Maintenance::getRoomId).filter(java.util.Objects::nonNull).collect(java.util.stream.Collectors.toSet());

        java.util.Map<Long, User> userMap = userRepository.findAllById(tenantIds).stream()
                .collect(java.util.stream.Collectors.toMap(User::getId, u -> u));

        java.util.Map<Long, Room> roomMap = roomRepository.findAllById(roomIds).stream()
                .collect(java.util.stream.Collectors.toMap(Room::getId, r -> r));

        java.util.Set<Long> branchIds = roomMap.values().stream().map(Room::getBranchId).filter(java.util.Objects::nonNull).collect(java.util.stream.Collectors.toSet());
        java.util.Map<Long, Branch> branchMap = branchRepository.findAllById(branchIds).stream()
                .collect(java.util.stream.Collectors.toMap(Branch::getId, b -> b));

        java.util.Map<Long, java.util.List<Roommate>> roommatesMap = roommateRepository.findByRoomIdInAndIsActiveTrue(new java.util.ArrayList<>(roomIds))
                .stream().collect(java.util.stream.Collectors.groupingBy(Roommate::getRoomId));

        for (Maintenance m : list) {
            java.util.List<String> phones = new java.util.ArrayList<>();

            User u = userMap.get(m.getTenantId());
            if (u != null) {
                m.setTenantName(u.getName());
                m.setTenantPhone(u.getPhoneNumber());
                if (u.getPhoneNumber() != null) phones.add(u.getPhoneNumber());
            }

            Room r = roomMap.get(m.getRoomId());
            if (r != null) {
                m.setRoomName(r.getRoomName());
                m.setRoomPrice(r.getPrice());
                m.setRoomArea(r.getFloorArea() != null ? r.getFloorArea() : 0.0);

                Branch b = branchMap.get(r.getBranchId());
                if (b != null) {
                    m.setBranchName(b.getBranchName());
                    m.setPropertyAddress(b.getAddress());
                }

                java.util.List<Roommate> roommates = roommatesMap.getOrDefault(r.getId(), java.util.Collections.emptyList());
                for (Roommate rm : roommates) {
                    if (rm.getPhoneNumber() != null && !rm.getPhoneNumber().isEmpty() && !phones.contains(rm.getPhoneNumber())) {
                        phones.add(rm.getPhoneNumber());
                    }
                }
            }
            m.setRoommatesPhones(phones);
        }
        return list;
    }

    private Maintenance populateTransientFields(Maintenance m) {
        if (m == null) return null;
        java.util.List<Maintenance> list = java.util.Collections.singletonList(m);
        return populateTransientFieldsBatch(list).get(0);
    }

    @Override
    @Transactional
    public Maintenance updateTicketStatus(Long userId, Long ticketId, String status) {
        Maintenance maintenance = maintenanceRepository.findById(ticketId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sự cố"));

        Room room = roomRepository.findById(maintenance.getRoomId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng trọ"));

        boolean isOwner = room.getOwnerId().equals(userId);
        boolean isAssignedStaff = maintenance.getAssignedStaffId() != null && maintenance.getAssignedStaffId().equals(userId);

        if (!isOwner && maintenance.getAssignedStaffId() != null && !isAssignedStaff) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền cập nhật sự cố này");
        }

        java.util.List<String> allowedStatuses = java.util.Arrays.asList("PENDING", "PROCESSING", "ASSIGNED");
        if (!allowedStatuses.contains(status)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trạng thái " + status + " không hợp lệ hoặc phải dùng luồng chuyên biệt");
        }

        // Nếu status = PROCESSING thì cập nhật
        if ("PROCESSING".equals(status)) {
            maintenance.setStatus("PROCESSING");
            // Gán người xử lý là staff này nếu chưa được gán và người gọi ko phải owner
            if (maintenance.getAssignedStaffId() == null && !isOwner) {
                maintenance.setAssignedStaffId(userId);
            }
        } else {
            maintenance.setStatus(status);
        }

        return maintenanceRepository.save(maintenance);
    }

    private void processSharedFacilityCost(Maintenance maintenance) {
        if (maintenance.getSharedFacilityId() == null || maintenance.getMaterialCost() == null || maintenance.getMaterialCost() <= 0) {
            return;
        }

        SharedFacility facility = sharedFacilityRepository.findById(maintenance.getSharedFacilityId()).orElse(null);
        if (facility == null || facility.getRooms() == null || facility.getRooms().isEmpty()) {
            return;
        }

        double costPerRoom = maintenance.getMaterialCost() / facility.getRooms().size();
        String reason = "Phí sửa chữa chung: " + facility.getName() + " (Sự cố #" + maintenance.getId() + ")";

        int currentMonth = java.time.LocalDate.now().getMonthValue();
        int currentYear = java.time.LocalDate.now().getYear();

        for (Room r : facility.getRooms()) {
            java.util.Optional<Bill> optionalBill = billRepository.findByRoomIdAndMonthAndYear(r.getId(), currentMonth, currentYear);
            if (optionalBill.isPresent()) {
                Bill bill = optionalBill.get();
                if ("PENDING".equals(bill.getStatus())) {
                    double currentDamageFee = bill.getDamageFee() != null ? bill.getDamageFee() : 0.0;
                    bill.setDamageFee(currentDamageFee + costPerRoom);
                    
                    String currentReason = bill.getDamageReason() != null ? bill.getDamageReason() : "";
                    if (!currentReason.isEmpty()) currentReason += "\n";
                    bill.setDamageReason(currentReason + reason + " - " + costPerRoom + "đ");
                    
                    bill.setTotalAmount((bill.getTotalAmount() != null ? bill.getTotalAmount() : 0.0) + costPerRoom);
                    billRepository.save(bill);
                }
            } else {
                Bill newBill = Bill.builder()
                        .roomId(r.getId())
                        .tenantId(r.getCurrentTenantId())
                        .contractId(r.getCurrentContractId())
                        .month(currentMonth)
                        .year(currentYear)
                        .damageFee(costPerRoom)
                        .damageReason(reason + " - " + costPerRoom + "đ")
                        .totalAmount(costPerRoom)
                        .originalAmount(costPerRoom)
                        .status("PENDING")
                        .type("MONTHLY")
                        .build();
                billRepository.save(newBill);
            }
        }
    }
}

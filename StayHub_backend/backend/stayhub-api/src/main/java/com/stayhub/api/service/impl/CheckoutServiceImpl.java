package com.stayhub.api.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.stayhub.api.dto.CheckoutRequestDto;
import com.stayhub.api.dto.CreateCheckoutBillDto;
import com.stayhub.api.entity.*;
import com.stayhub.api.repository.*;
import com.stayhub.api.service.BranchGroupChatService;
import com.stayhub.api.service.CheckoutService;
import com.stayhub.api.service.CloudStorageService;
import com.stayhub.api.service.NotificationService;
import com.stayhub.api.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class CheckoutServiceImpl implements CheckoutService {

    private final CheckoutRequestRepository checkoutRequestRepository;
    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;
    private final MaintenanceRepository maintenanceRepository;
    private final BillRepository billRepository;
    private final BranchGroupChatService branchGroupChatService;
    private final FinancialReportRepository financialReportRepository;
    private final CloudStorageService cloudStorageService;
    private final ObjectMapper objectMapper;
    private final NotificationService notificationService;
    private final UserRepository userRepository;
    private final RoomAssetRepository roomAssetRepository;
    private final BranchRepository branchRepository;

    @Override
    @Transactional
    public CheckoutRequest createCheckoutRequest(CheckoutRequestDto dto, List<MultipartFile> files) {
        Contract contract = contractRepository.findById(dto.getContractId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không tìm thấy hợp đồng."));

        if (!"ACTIVE".equals(contract.getStatus().name())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hợp đồng không ở trạng thái hoạt động.");
        }

        List<Maintenance> pendingMaintenances = maintenanceRepository.findPendingByRoomId(contract.getRoomId());
        if (!pendingMaintenances.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng xử lý dứt điểm các sự cố bảo trì trước khi trả phòng.");
        }

        // Check for duplicates
        List<CheckoutRequest> existingRequests = checkoutRequestRepository.findByRoomId(contract.getRoomId());
        for (CheckoutRequest req : existingRequests) {
            if ("PENDING".equals(req.getStatus()) || "PAYMENT_PENDING".equals(req.getStatus())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đã có yêu cầu trả phòng đang xử lý cho phòng này.");
            }
        }

        List<String> imageUrls = new ArrayList<>();
        if (files != null) {
            for (MultipartFile file : files) {
                String url = cloudStorageService.uploadFile(file);
                if (url != null) {
                    imageUrls.add(url);
                }
            }
        }

        String imagesJson;
        try {
            imagesJson = objectMapper.writeValueAsString(imageUrls);
        } catch (Exception e) {
            imagesJson = "[]";
        }

        CheckoutRequest request = CheckoutRequest.builder()
                .roomId(contract.getRoomId())
                .tenantId(contract.getTenantId())
                .ownerId(contract.getOwnerId())
                .contractId(contract.getId())
                .status("PENDING")
                .targetCheckoutDate(dto.getTargetCheckoutDate())
                .checkoutImages(imagesJson)
                .tenantNote(dto.getTenantNote())
                .build();

        CheckoutRequest saved = checkoutRequestRepository.save(request);

        String roomName = roomRepository.findById(contract.getRoomId()).map(Room::getRoomName).orElse(String.valueOf(contract.getRoomId()));
        String branchName = "";
        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        if (room != null && room.getBranchId() != null) {
            branchName = branchRepository.findById(room.getBranchId())
                    .map(Branch::getBranchName)
                    .orElse("");
        }
        User tenant = userRepository.findById(contract.getTenantId()).orElse(null);
        String customerName = tenant != null ? tenant.getName() : "Khách hàng";
        String phoneNumber = tenant != null ? tenant.getPhoneNumber() : "";
        
        java.util.Map<String, Object> payloadMap = new java.util.LinkedHashMap<>();
        payloadMap.put("roomName", roomName);
        payloadMap.put("branchName", branchName);
        payloadMap.put("customerName", customerName);
        payloadMap.put("phoneNumber", phoneNumber);
        payloadMap.put("contractCode", "HD-" + contract.getId());
        payloadMap.put("startDate", contract.getStartDate() != null ? contract.getStartDate().toString() : "");
        payloadMap.put("endDate", contract.getEndDate() != null ? contract.getEndDate().toString() : "");
        payloadMap.put("deposit", contract.getDepositAmount());
        payloadMap.put("targetDate", dto.getTargetCheckoutDate() != null ? dto.getTargetCheckoutDate().toString() : "");
        payloadMap.put("note", dto.getTenantNote() != null ? dto.getTenantNote() : "");

        String payloadJson = "{}";
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            payloadJson = mapper.writeValueAsString(payloadMap);
        } catch (Exception e) { log.error("Exception in CheckoutServiceImpl: ", e); }

        notificationService.send(
                contract.getTenantId(),
                contract.getOwnerId(),
                NotificationScope.INDIVIDUAL,
                "Yêu cầu trả phòng mới",
                "Phòng " + roomName + " vừa gửi yêu cầu trả phòng.",
                NotificationType.CHECKOUT_REQUESTED,
                saved.getId(),
                true,
                NotificationActionStatus.PENDING,
                "{\"endpoint\": \"/v1/checkouts/owner/approve/" + saved.getId() + "\", \"method\": \"POST\", \"payload\": " + payloadJson + "}"
        );

        return saved;
    }

    @Override
    public List<CheckoutRequest> getRequestsForOwner(Long ownerId) {
        return checkoutRequestRepository.findByOwnerId(ownerId);
    }

    @Override
    public List<CheckoutRequest> getRequestsForTenant(Long tenantId) {
        return checkoutRequestRepository.findByTenantId(tenantId);
    }

    @Override
    @Transactional
    public CheckoutRequest rejectRequest(Long id, String ownerReason) {
        CheckoutRequest request = checkoutRequestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu trả phòng."));
        request.setStatus("REJECTED");
        request.setOwnerReason(ownerReason);
        CheckoutRequest saved = checkoutRequestRepository.save(request);
        notificationService.send(
                request.getOwnerId(),
                request.getTenantId(),
                NotificationScope.INDIVIDUAL,
                "Yêu cầu trả phòng bị từ chối",
                "Lý do: " + ownerReason,
                NotificationType.CHECKOUT_REJECTED,
                saved.getId(), false, null, null
        );
        return saved;
    }

    @Override
    @Transactional
    public Map<String, Object> approveAndCreateBill(Long id, CreateCheckoutBillDto billDto) {
        CheckoutRequest request = checkoutRequestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu trả phòng."));

        request.setStatus("PAYMENT_PENDING");
        checkoutRequestRepository.save(request);

        Contract contract = contractRepository.findById(request.getContractId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng."));

        Room room = roomRepository.findByIdWithPessimisticLock(request.getRoomId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng."));
        room.setStatus(RoomStatus.CLEANING_TURNOVER);
        roomRepository.save(room);


        Double totalAmount = billDto.getRentAmount() + billDto.getElectricAmount() 
                           + billDto.getWaterAmount() + billDto.getServiceAmount();
                           
        if (billDto.getDamageFee() != null) {
            totalAmount += billDto.getDamageFee();
        }

        // Khấu trừ tiền cọc
        Double deposit = contract.getDepositAmount() != null ? contract.getDepositAmount() : 0.0;
        totalAmount = totalAmount - deposit;

        Bill bill = Bill.builder()
                .roomId(request.getRoomId())
                .tenantId(request.getTenantId())
                .contractId(request.getContractId())
                .month(request.getTargetCheckoutDate().getMonthValue())
                .year(request.getTargetCheckoutDate().getYear())
                .type("CHECKOUT")
                .status("PENDING")
                .electricCurrent(billDto.getElectricCurrent())
                .waterCurrent(billDto.getWaterCurrent())
                .rentAmount(billDto.getRentAmount())
                .electricAmount(billDto.getElectricAmount())
                .waterAmount(billDto.getWaterAmount())
                .serviceAmount(billDto.getServiceAmount())
                .damageFee(billDto.getDamageFee())
                .damageReason(billDto.getDamageReason())
                .totalAmount(totalAmount)
                .build();

        billRepository.save(bill);

        notificationService.send(
                request.getOwnerId(),
                request.getTenantId(),
                NotificationScope.INDIVIDUAL,
                "Yêu cầu trả phòng được duyệt",
                "Chủ nhà đã duyệt yêu cầu trả phòng và tạo hóa đơn thanh toán cuối cùng. Vui lòng thanh toán để hoàn tất.",
                NotificationType.CHECKOUT_APPROVED,
                bill.getId(), false, null, null
        );

        // Send system message to branch group chat
        if (room.getBranchId() != null) {
            branchGroupChatService.sendSystemMessage(
                    room.getBranchId(),
                    "Người thuê phòng " + room.getRoomName() + " đã trả phòng và rời khỏi nhóm nhà."
            );
        }

        return Map.of("request", request, "bill", bill);
    }

    @Override
    public String analyzeImagesWithAI(Long id) {
        // Tích hợp giả lập Gemini AI Auto-Detection
        CheckoutRequest request = checkoutRequestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu."));
        
        Contract contract = contractRepository.findById(request.getContractId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hợp đồng."));

        log.info("Calling Gemini API to compare images: {} vs {}", contract.getContractImages(), request.getCheckoutImages());
        
        // Trả về một câu ngẫu nhiên hoặc logic mock
        return "Phát hiện móp góc tủ lạnh và vết xước trên tường, có thể yêu cầu đền bù.";
    }

    @Override
    @Transactional
    public void completeCheckoutAndFreeRoom(Long billId) {
        Bill bill = billRepository.findById(billId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn."));
        
        if (!"CHECKOUT".equals(bill.getType())) {
            throw new RuntimeException("Đây không phải hóa đơn quyết toán.");
        }

        bill.setStatus("PAID"); // trigger PreUpdate
        billRepository.save(bill);

        // Note: Logic chuyển trạng thái phòng và kết thúc hợp đồng đã được chuyển sang BillServiceImpl
        // khi khách thanh toán sạch nợ (Tất cả hóa đơn PAID).


        List<CheckoutRequest> requests = checkoutRequestRepository.findByRoomId(bill.getRoomId());
        for (CheckoutRequest req : requests) {
            if ("PAYMENT_PENDING".equals(req.getStatus())) {
                req.setStatus("COMPLETED");
                checkoutRequestRepository.save(req);
            }
        }

        // Tạo FinancialReport cho các khoản phát sinh (thu từ tiền phạt)
        if (bill.getDamageFee() != null && bill.getDamageFee() > 0) {
            Room damageRoom = roomRepository.findById(bill.getRoomId()).orElseThrow();
            FinancialReport report = FinancialReport.builder()
                    .ownerId(damageRoom.getOwnerId())
                    .type("REVENUE")
                    .amount(bill.getDamageFee())
                    .description("Thu đền bù tài sản trả phòng " + bill.getRoomId() + " - " + bill.getDamageReason())
                    .build();
            financialReportRepository.save(report);
        }
    }

    @Override
    public Map<String, Object> getTrackingSummary(Long id) {
        CheckoutRequest request = checkoutRequestRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy yêu cầu trả phòng"));

        Room room = roomRepository.findById(request.getRoomId()).orElse(null);
        Contract contract = contractRepository.findById(request.getContractId()).orElse(null);
        User tenant = userRepository.findById(request.getTenantId()).orElse(null);

        long stayDurationDays = 0;
        if (contract != null && contract.getStartDate() != null) {
            stayDurationDays = java.time.temporal.ChronoUnit.DAYS.between(contract.getStartDate(), java.time.LocalDate.now());
            if (stayDurationDays < 0) stayDurationDays = 0;
        }

        List<Maintenance> tickets = maintenanceRepository.findByRoomId(request.getRoomId());
        long incidentCount = tickets.stream().filter(t -> t.getTenantId().equals(request.getTenantId())).count();

        List<Bill> bills = billRepository.findByRoomId(request.getRoomId());
        long totalBills = bills.stream().filter(b -> b.getTenantId() != null && b.getTenantId().equals(request.getTenantId())).count();
        long paidBills = bills.stream().filter(b -> b.getTenantId() != null && b.getTenantId().equals(request.getTenantId()) && "PAID".equals(b.getStatus())).count();

        Map<String, Object> summary = new java.util.HashMap<>();
        summary.put("request", request);
        summary.put("room", room);
        summary.put("contract", contract);
        summary.put("tenant", tenant);
        summary.put("stayDurationDays", stayDurationDays);
        summary.put("incidentCount", incidentCount);
        summary.put("totalBills", totalBills);
        summary.put("paidBills", paidBills);

        return summary;
    }

    @Override
    public Map<String, Object> getCheckoutDetails(Long id) {
        CheckoutRequest req = checkoutRequestRepository.findById(id).orElse(null);
        if (req == null) return null;
        
        Contract contract = contractRepository.findById(req.getContractId()).orElse(null);
        String roomName = roomRepository.findById(req.getRoomId()).map(Room::getRoomName).orElse(String.valueOf(req.getRoomId()));
        String branchName = "";
        Room reqRoom = roomRepository.findById(req.getRoomId()).orElse(null);
        if (reqRoom != null && reqRoom.getBranchId() != null) {
            branchName = branchRepository.findById(reqRoom.getBranchId())
                    .map(Branch::getBranchName)
                    .orElse("");
        }
        User tenant = userRepository.findById(req.getTenantId()).orElse(null);
        
        Map<String, Object> payloadMap = new java.util.LinkedHashMap<>();
        payloadMap.put("roomName", roomName);
        payloadMap.put("branchName", branchName);
        payloadMap.put("customerName", tenant != null ? tenant.getName() : "Khách hàng");
        payloadMap.put("phoneNumber", tenant != null ? tenant.getPhoneNumber() : "");
        if (contract != null) {
            payloadMap.put("contractCode", "HD-" + contract.getId());
            payloadMap.put("startDate", contract.getStartDate() != null ? contract.getStartDate().toString() : "");
            payloadMap.put("endDate", contract.getEndDate() != null ? contract.getEndDate().toString() : "");
            payloadMap.put("deposit", contract.getDepositAmount());
            
            Double outstandingBalance = 0.0;
            List<Bill> roomBills = billRepository.findByRoomId(req.getRoomId());
            for (Bill bill : roomBills) {
                if (bill.getContractId() != null && bill.getContractId().equals(contract.getId())) {
                    if (bill.getIsPaid() == null || !bill.getIsPaid()) {
                        outstandingBalance += (bill.getTotalAmount() != null ? bill.getTotalAmount() : 0.0);
                    }
                }
            }
            payloadMap.put("outstandingBalance", outstandingBalance);
        }
        
        int equipmentCount = 0;
        List<RoomAsset> assets = roomAssetRepository.findByRoomId(req.getRoomId());
        for (RoomAsset asset : assets) {
            equipmentCount += (asset.getQuantity() != null ? asset.getQuantity() : 1);
        }
        payloadMap.put("equipmentCount", equipmentCount);

        payloadMap.put("targetDate", req.getTargetCheckoutDate() != null ? req.getTargetCheckoutDate().toString() : "");
        payloadMap.put("note", req.getTenantNote() != null ? req.getTenantNote() : "");
        
        return payloadMap;
    }
}

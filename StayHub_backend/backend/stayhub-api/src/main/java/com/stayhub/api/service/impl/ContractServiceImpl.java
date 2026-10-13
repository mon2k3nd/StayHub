package com.stayhub.api.service.impl;

import com.stayhub.api.entity.*;
import com.stayhub.api.dto.response.ContractDetailResponse;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.InspectionLogRepository;
import com.stayhub.api.repository.RentalRequestRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.WishlistRepository;
import com.stayhub.api.service.CloudStorageService;
import com.stayhub.api.service.BranchGroupChatService;
import com.stayhub.api.service.ContractService;
import com.stayhub.api.service.NotificationService;
import com.stayhub.api.service.VoucherValidationService;
import com.stayhub.api.entity.Voucher;
import com.stayhub.api.repository.VoucherRepository;
import com.stayhub.api.repository.ContractVoucherRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.util.stream.Collectors;
import java.util.ArrayList;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ContractServiceImpl implements ContractService {

    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;
    private final NotificationService notificationService;
    private final CloudStorageService cloudStorageService;
    private final InspectionLogRepository inspectionLogRepository;
    private final ObjectMapper objectMapper;
    private final UserRepository userRepository;
    private final RentalRequestRepository rentalRequestRepository;
    private final BranchRepository branchRepository;
    private final com.stayhub.api.service.BillService billService;
    private final BranchGroupChatService branchGroupChatService;
    private final WishlistRepository wishlistRepository;
    private final VoucherValidationService voucherValidationService;
    private final ContractVoucherRepository contractVoucherRepository;
    private final VoucherRepository voucherRepository;


    @Override
    public List<Contract> getByTenant(Long tenantId) {
        return contractRepository.findByTenantId(tenantId);
    }

    @Override
    public List<Contract> getByOwner(Long ownerId) {
        return contractRepository.findByOwnerId(ownerId);
    }

    @Override
    public Contract getActiveByRoom(Long roomId) {
        return contractRepository.findByRoomIdAndStatusIn(roomId,
                Arrays.asList(ContractStatus.ACTIVE, ContractStatus.PENDING))
                .orElseThrow(() -> new ResourceNotFoundException("Không có hợp đồng đang hoạt động cho phòng này"));
    }

    @Override
    @Transactional
    public Contract create(Contract contract) {
        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        if (room != null && room.getStatus() == RoomStatus.BAO_TRI) {
            throw new IllegalStateException("PhÃ²ng Ä‘ang trong tráº¡ng thÃ¡i Báº¢O TRÃŒ, khÃ´ng thá»ƒ táº¡o há»£p Ä‘á»“ng má»›i!");
        }

        contract.setStatus(ContractStatus.ACTIVE);
        contract.setSignedAt(LocalDateTime.now());
        Contract saved = contractRepository.save(contract);

        // Cập nhật trạng thái phòng -> DA_THUE
        if (room != null) {
            room.setStatus(RoomStatus.DA_THUE);
            room.setCurrentTenantId(contract.getTenantId());
            room.setCurrentContractId(saved.getId());
            roomRepository.save(room);
        }

        // Gửi thông báo cho tenant
        notificationService.send(contract.getOwnerId(), contract.getTenantId(), NotificationScope.INDIVIDUAL,
                "Hợp đồng đã được ký kết!",
                "Chào mừng bạn đến ở. Hợp đồng của bạn có hiệu lực từ " + contract.getStartDate(),
                NotificationType.CONTRACT_SIGNED, saved.getId(), false, null, null);
        return saved;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Contract verifyContract(Long id, Long tenantId, List<MultipartFile> contractImages,
                                   MultipartFile electricityMeterImage, MultipartFile waterMeterImage,
                                   List<MultipartFile> inspectionImages, List<MultipartFile> furnitureImages, List<String> furnitureNotes) {
        Contract contract = contractRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + id));

        if (!contract.getTenantId().equals(tenantId)) {
            throw new IllegalArgumentException("Không có quyền nghiệm thu hợp đồng này.");
        }

        // Upload images
        List<String> contractImageUrls = new ArrayList<>();
        if (contractImages != null && !contractImages.isEmpty()) {
            contractImageUrls = contractImages.stream()
                    .filter(f -> !f.isEmpty())
                    .map(cloudStorageService::uploadFile)
                    .collect(Collectors.toList());
        }

        List<String> inspectionImageUrls = new ArrayList<>();
        if (inspectionImages != null && !inspectionImages.isEmpty()) {
            inspectionImageUrls = inspectionImages.stream()
                    .filter(f -> !f.isEmpty())
                    .map(cloudStorageService::uploadFile)
                    .collect(Collectors.toList());
        }

        List<Map<String, String>> furnitureJsonList = new ArrayList<>();
        if (furnitureImages != null && !furnitureImages.isEmpty()) {
            for (int i = 0; i < furnitureImages.size(); i++) {
                MultipartFile f = furnitureImages.get(i);
                if (!f.isEmpty()) {
                    String url = cloudStorageService.uploadFile(f);
                    String note = (furnitureNotes != null && furnitureNotes.size() > i) ? furnitureNotes.get(i) : "";
                    Map<String, String> item = new java.util.HashMap<>();
                    item.put("url", url);
                    item.put("note", note);
                    furnitureJsonList.add(item);
                }
            }
        }

        String electricityUrl = (electricityMeterImage != null && !electricityMeterImage.isEmpty()) 
                ? cloudStorageService.uploadFile(electricityMeterImage) : null;
        String waterUrl = (waterMeterImage != null && !waterMeterImage.isEmpty()) 
                ? cloudStorageService.uploadFile(waterMeterImage) : null;

        try {
            String contractImagesJson = objectMapper.writeValueAsString(contractImageUrls);
            String inspectionImagesJson = objectMapper.writeValueAsString(inspectionImageUrls);
            String furnitureImagesJson = objectMapper.writeValueAsString(furnitureJsonList);

            // Cập nhật hợp đồng
            contract.setContractImages(contractImagesJson);
            contract.setElectricityMeterImage(electricityUrl);
            contract.setWaterMeterImage(waterUrl);
            contract.setStatus(ContractStatus.ACTIVE);
            contract.setSignedAt(LocalDateTime.now());
            Contract savedContract = contractRepository.save(contract);

            // Đổi trạng thái phòng
            Room room = roomRepository.findById(contract.getRoomId())
                    .orElseThrow(() -> new ResourceNotFoundException("Phòng không tồn tại"));
            room.setStatus(RoomStatus.DA_THUE);
            room.setCurrentTenantId(tenantId);
            room.setCurrentContractId(contract.getId());
            roomRepository.save(room);

            // Lưu vết lịch sử
            InspectionLog log = InspectionLog.builder()
                    .roomId(room.getId())
                    .tenantId(tenantId)
                    .contractImages(contractImagesJson)
                    .inspectionImages(inspectionImagesJson)
                    .furnitureImages(furnitureImagesJson)
                    .electricityMeterImage(electricityUrl)
                    .waterMeterImage(waterUrl)
                    .build();
            inspectionLogRepository.save(log);

            // Cập nhật Role cho Khách
            User tenant = userRepository.findById(tenantId).orElse(null);
            if (tenant != null) {
                tenant.setRoleId("ACTIVE_TENANT");
                userRepository.save(tenant);
            }

            // Hoàn tất yêu cầu thuê phòng
            List<RentalRequest> requests = rentalRequestRepository.findAllByRoomIdInAndStatus(
                List.of(room.getId()), RequestStatus.APPROVED_WAITING_HANDOVER);
            for (RentalRequest req : requests) {
                if (req.getTenantId().equals(tenantId)) {
                    req.setStatus(RequestStatus.COMPLETED);
                    rentalRequestRepository.save(req);
                }
            }

            // Tạo hóa đơn tháng đầu tiên và tiền cọc sau khi nhận phòng
            billService.createInitialBill(savedContract);

            // Send system message to branch group chat
            if (room.getBranchId() != null) {
                branchGroupChatService.sendSystemMessage(
                        room.getBranchId(),
                        "Người thuê mới đã tham gia nhóm nhà từ " + room.getRoomName()
                );
            }

            return savedContract;
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Lỗi xử lý JSON khi lưu hình ảnh", e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Contract offlineVerifyContract(Long id, Long ownerId, List<MultipartFile> contractImages, List<MultipartFile> cccdImages) {
        Contract contract = contractRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + id));

        if (!contract.getOwnerId().equals(ownerId)) {
            throw new IllegalArgumentException("Không có quyền thao tác hợp đồng này.");
        }

        // Upload images
        List<String> contractImageUrls = new ArrayList<>();
        if (contractImages != null && !contractImages.isEmpty()) {
            contractImageUrls = contractImages.stream()
                    .filter(f -> !f.isEmpty())
                    .map(cloudStorageService::uploadFile)
                    .collect(Collectors.toList());
        }

        List<String> cccdImageUrls = new ArrayList<>();
        if (cccdImages != null && !cccdImages.isEmpty()) {
            cccdImageUrls = cccdImages.stream()
                    .filter(f -> !f.isEmpty())
                    .map(cloudStorageService::uploadFile)
                    .collect(Collectors.toList());
        }

        try {
            String contractImagesJson = objectMapper.writeValueAsString(contractImageUrls);
            String cccdImagesJson = objectMapper.writeValueAsString(cccdImageUrls);

            // Cập nhật hợp đồng
            contract.setContractImages(contractImagesJson);
            contract.setCccdImages(cccdImagesJson);
            contract.setStatus(ContractStatus.ACTIVE);
            contract.setSignedAt(LocalDateTime.now());
            Contract savedContract = contractRepository.save(contract);

            // Đổi trạng thái phòng
            Room room = roomRepository.findById(contract.getRoomId())
                    .orElseThrow(() -> new ResourceNotFoundException("Phòng không tồn tại"));
            room.setStatus(RoomStatus.DA_THUE);
            room.setCurrentTenantId(contract.getTenantId());
            room.setCurrentContractId(contract.getId());
            roomRepository.save(room);

            // Cập nhật Role cho Khách nếu chưa có
            User tenant = userRepository.findById(contract.getTenantId()).orElse(null);
            if (tenant != null && !"ACTIVE_TENANT".equals(tenant.getRoleId())) {
                tenant.setRoleId("ACTIVE_TENANT");
                userRepository.save(tenant);
            }

            // Hoàn tất yêu cầu thuê phòng nếu có
            List<RentalRequest> requests = rentalRequestRepository.findAllByRoomIdInAndStatus(
                List.of(room.getId()), RequestStatus.APPROVED_WAITING_HANDOVER);
            for (RentalRequest req : requests) {
                if (req.getTenantId().equals(contract.getTenantId())) {
                    req.setStatus(RequestStatus.COMPLETED);
                    rentalRequestRepository.save(req);
                }
            }

            // Send system message to branch group chat
            if (room.getBranchId() != null) {
                branchGroupChatService.sendSystemMessage(
                        room.getBranchId(),
                        "Người thuê mới đã tham gia nhóm nhà từ " + room.getRoomName()
                );
            }

            return savedContract;
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Lỗi xử lý JSON khi lưu hình ảnh", e);
        }
    }

    @Override
    @Transactional
    public Contract terminate(Long id, String reason) {
        return terminate(id, null, reason);
    }

    @Transactional
    public Contract terminate(Long id, Long requesterId, String reason) {
        Contract contract = contractRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + id));

        // Kiểm tra quyền: chỉ Owner hoặc Tenant của hợp đồng mới được terminate
        if (requesterId != null) {
            boolean isOwner = contract.getOwnerId() != null && contract.getOwnerId().equals(requesterId);
            boolean isTenant = contract.getTenantId() != null && contract.getTenantId().equals(requesterId);
            if (!isOwner && !isTenant) {
                throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền chấm dứt hợp đồng này");
            }
        }

        contract.setStatus(ContractStatus.TERMINATED);
        contract.setTerminatedAt(LocalDateTime.now());
        contract.setTerminationReason(reason);

        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);

        // Xử lý Voucher Lifecycle: Dừng áp dụng voucher sớm
        contractVoucherRepository.findByContractIdAndStatus(id, com.stayhub.api.entity.ContractVoucher.ContractVoucherStatus.ACTIVE)
            .ifPresent(snapshot -> {
                snapshot.setStatus(com.stayhub.api.entity.ContractVoucher.ContractVoucherStatus.TERMINATED);
                contractVoucherRepository.save(snapshot);
            });

        // Giải phóng phòng
        freeRoom(contract.getRoomId());

        if (requesterId != null && requesterId.equals(contract.getTenantId())) {
            // Khách thuê yêu cầu chấm dứt
            notificationService.send(contract.getTenantId(), contract.getOwnerId(), NotificationScope.INDIVIDUAL,
                    "Khách đã chấm dứt hợp đồng",
                    "Hợp đồng đã bị chấm dứt bởi khách thuê. Lý do: " + reason,
                    NotificationType.CONTRACT_TERMINATED, id, false, null, null);
        } else {
            // Chủ nhà yêu cầu chấm dứt
            notificationService.send(contract.getOwnerId(), contract.getTenantId(), NotificationScope.INDIVIDUAL,
                    "Hợp đồng đã bị chấm dứt",
                    "Hợp đồng của bạn đã bị chấm dứt. Lý do: " + reason,
                    NotificationType.CONTRACT_TERMINATED, id, false, null, null);
        }

        if (room != null && room.getBranchId() != null) {
            branchGroupChatService.sendSystemMessage(
                    room.getBranchId(),
                    "Khách thuê từ phòng " + room.getRoomName() + " đã trả phòng và rời nhóm."
            );
        }

        return contractRepository.save(contract);
    }

    @Override
    @Transactional
    public Contract renew(Long id, int months) {
        return renew(id, null, months);
    }

    @Transactional
    public Contract renew(Long id, Long requesterId, int months) {
        Contract contract = contractRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + id));

        // Kiểm tra quyền: chỉ Owner của hợp đồng mới được gia hạn
        if (requesterId != null) {
            boolean isOwner = contract.getOwnerId() != null && contract.getOwnerId().equals(requesterId);
            if (!isOwner) {
                throw new org.springframework.security.access.AccessDeniedException("Chỉ chủ nhà mới có quyền gia hạn hợp đồng");
            }
        }

        if (contract.getStatus() != ContractStatus.ACTIVE && contract.getStatus() != ContractStatus.PENDING) {
            throw new IllegalStateException("Chỉ có thể gia hạn hợp đồng đang active");
        }

        contract.setEndDate(contract.getEndDate().plusMonths(months));
        contract.setStatus(ContractStatus.ACTIVE);

        // Thông báo cho khách thuê
        notificationService.send(contract.getOwnerId(), contract.getTenantId(), NotificationScope.INDIVIDUAL,
                "Hợp đồng đã được gia hạn",
                "Hợp đồng thuê phòng của bạn đã được gia hạn thêm " + months + " tháng.",
                NotificationType.GENERAL, id, false, null, null);

        return contractRepository.save(contract);
    }

    @Override
    @Transactional
    public Map<String, Object> liquidate(Long id, Map<String, Object> data) {
        Contract contract = contractRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + id));

        double totalDeposit = contract.getDepositAmount() != null ? contract.getDepositAmount() : 0.0;
        double damageDeduction = data.containsKey("damageDeduction")
                ? Double.parseDouble(data.get("damageDeduction").toString()) : 0.0;
        double depositRefund = Math.max(totalDeposit - damageDeduction, 0);
        String damageNote = data.containsKey("damageNote") ? data.get("damageNote").toString() : "";

        contract.setStatus(ContractStatus.LIQUIDATED);
        contract.setTerminatedAt(LocalDateTime.now());
        if (!damageNote.isEmpty()) {
            contract.setTerminationReason("Thanh lý: " + damageNote);
        }
        contractRepository.save(contract);

        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        freeRoom(contract.getRoomId());

        if (room != null && room.getBranchId() != null) {
            branchGroupChatService.sendSystemMessage(
                    room.getBranchId(),
                    "Khách thuê từ phòng " + room.getRoomName() + " đã trả phòng và rời nhóm."
            );
        }

        // Thông báo hoàn cọc cho khách thuê
        String depositMsg = damageDeduction > 0
                ? String.format("Tiền cọc của bạn là %.0f VNĐ. Khấu trừ hư hỏng: %.0f VNĐ. Hoàn trả: %.0f VNĐ. Ghi chú: %s",
                    totalDeposit, damageDeduction, depositRefund, damageNote.isEmpty() ? "Không có" : damageNote)
                : String.format("Hợp đồng đã thanh lý. Hoàn trả toàn bộ tiền cọc: %.0f VNĐ.", depositRefund);
        notificationService.send(contract.getOwnerId(), contract.getTenantId(), NotificationScope.INDIVIDUAL,
                "Thông báo hoàn trả tiền cọc",
                depositMsg,
                NotificationType.GENERAL, id, true, NotificationActionStatus.PENDING, null);

        Map<String, Object> result = new HashMap<>();
        result.put("contractId", id);
        result.put("totalDeposit", totalDeposit);
        result.put("damageDeduction", damageDeduction);
        result.put("depositRefund", depositRefund);
        result.put("damageNote", damageNote);
        result.put("message", String.format("Thanh lý hợp đồng thành công. Hoàn trả cọc: %.0f VNĐ", depositRefund));
        return result;
    }

    private void freeRoom(Long roomId) {
        Room room = roomRepository.findById(roomId).orElse(null);
        if (room != null) {
            Long tenantId = room.getCurrentTenantId();
            room.setStatus(RoomStatus.TRONG);
            room.setCurrentTenantId(null);
            room.setCurrentContractId(null);
            roomRepository.save(room);

            // Revert Role to TENANT if they have no other active contracts
            if (tenantId != null) {
                long activeContractsCount = contractRepository.countByTenantIdAndStatus(tenantId, ContractStatus.ACTIVE);
                if (activeContractsCount == 0) {
                    User tenant = userRepository.findById(tenantId).orElse(null);
                    if (tenant != null && "ACTIVE_TENANT".equals(tenant.getRoleId())) {
                        tenant.setRoleId("TENANT");
                        userRepository.save(tenant);
                    }
                }
            }

            // Gửi thông báo cho tất cả user đã lưu phòng này vào wishlist
            notifyWishlistUsers(room);
        }
    }

    private void notifyWishlistUsers(Room room) {
        List<com.stayhub.api.entity.Wishlist> wishers = wishlistRepository.findByRoomId(room.getId());
        for (com.stayhub.api.entity.Wishlist w : wishers) {
            notificationService.send(
                null, w.getUserId(),
                NotificationScope.INDIVIDUAL,
                "📢 Phòng bạn quan tâm đã trống!",
                "Phòng \"" + room.getRoomName() + "\" " +
                (room.getAddress() != null ? "tại " + room.getAddress() + " " : "") +
                "đã có sẵn để thuê. Liên hệ ngay trước khi hết!",
                NotificationType.ROOM_AVAILABLE_ALERT,
                room.getId(), false, null, null
            );
        }
    }

    @Override
    public Object getInspectionLog(Long contractId, Long tenantId) {
        Contract contract = contractRepository.findByIdWithPessimisticLock(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Hợp đồng không tồn tại"));
        if (!contract.getTenantId().equals(tenantId) && !contract.getOwnerId().equals(tenantId)) {
            throw new IllegalArgumentException("Không có quyền xem nghiệm thu của hợp đồng này");
        }
        
        List<InspectionLog> logs = inspectionLogRepository.findByRoomId(contract.getRoomId());
        // Lấy biên bản nghiệm thu mới nhất của tenant này
        return logs.stream()
                .filter(l -> l.getTenantId().equals(contract.getTenantId()))
                .max(java.util.Comparator.comparing(InspectionLog::getCreatedAt))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy biên bản nghiệm thu"));
    }

    @Override
    public ContractDetailResponse getContractDetail(Long contractId) {
        Contract contract = contractRepository.findByIdWithPessimisticLock(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + contractId));

        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        User tenant = userRepository.findById(contract.getTenantId()).orElse(null);
        User owner = userRepository.findById(contract.getOwnerId()).orElse(null);

        Branch branch = null;
        if (room != null && room.getBranchId() != null) {
            branch = branchRepository.findById(room.getBranchId()).orElse(null);
        }

        return ContractDetailResponse.builder()
                // Contract base
                .id(contract.getId())
                .status(contract.getStatus() != null ? contract.getStatus().name() : "PENDING")
                .startDate(contract.getStartDate())
                .endDate(contract.getEndDate())
                .monthlyRent(contract.getMonthlyRent())
                .depositAmount(contract.getDepositAmount())
                .electricityPrice(contract.getElectricityPrice())
                .waterPrice(contract.getWaterPrice())
                .serviceFee(contract.getServiceFee())
                .terms(contract.getTerms())
                .signedAt(contract.getSignedAt())
                .createdAt(contract.getCreatedAt())
                .handoverCondition(contract.getHandoverCondition())
                .ownerSignature(contract.getOwnerSignature())
                .tenantSignature(contract.getTenantSignature())
                // Room
                .roomId(room != null ? room.getId() : null)
                .roomName(room != null ? room.getRoomName() : "")
                .roomAddress(room != null && room.getAddressOld() != null ? 
                    com.stayhub.api.service.AddressMapper.mapTo3Tier(room.getAddressOld()).toFullAddress() : 
                    (room != null ? room.getAddress() : ""))
                .roomCode(room != null ? room.getRoomCode() : "")
                .floor(room != null ? room.getFloor() : null)
                .floorArea(room != null ? room.getFloorArea() : null)
                // Branch
                .branchId(branch != null ? branch.getId() : null)
                .branchName(branch != null ? branch.getBranchName() : "")
                .branchAddress(branch != null && branch.getAddressOld() != null ? 
                    com.stayhub.api.service.AddressMapper.mapTo3Tier(branch.getAddressOld()).toFullAddress() : 
                    (branch != null ? branch.getAddress() : ""))
                // Tenant
                .tenantId(tenant != null ? tenant.getId() : null)
                .tenantName(tenant != null ? tenant.getName() : "")
                .tenantPhone(tenant != null ? tenant.getPhoneNumber() : "")
                .tenantEmail(tenant != null ? tenant.getEmail() : "")
                .tenantCccd(tenant != null && tenant.getTenantProfile() != null ? tenant.getTenantProfile().getCccdNumber() : "")
                .tenantHometown(tenant != null && tenant.getTenantProfile() != null ? tenant.getTenantProfile().getHometown() : "")
                .tenantOccupation(tenant != null && tenant.getTenantProfile() != null ? tenant.getTenantProfile().getOccupation() : "")
                // Owner
                .ownerId(owner != null ? owner.getId() : null)
                .ownerName(owner != null ? owner.getName() : "")
                .ownerPhone(owner != null ? owner.getPhoneNumber() : "")
                .ownerEmail(owner != null ? owner.getEmail() : "")
                .build();
    }

    @Override
    @Transactional
    public Contract tenantSignContract(Long contractId, Long tenantId, String tenantSignature, String handoverCondition) {
        Contract contract = contractRepository.findByIdWithPessimisticLock(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + contractId));

        if (!contract.getTenantId().equals(tenantId)) {
            throw new IllegalArgumentException("Bạn không có quyền ký hợp đồng này.");
        }
        if (contract.getStatus() != ContractStatus.PENDING) {
            throw new IllegalStateException("Hợp đồng này không ở trạng thái chờ ký.");
        }

        // Đánh dấu đã ký - chuyển trạng thái sang ACTIVE
        contract.setStatus(ContractStatus.ACTIVE);
        contract.setSignedAt(java.time.LocalDateTime.now());
        contract.setTenantSignature(tenantSignature);
        contract.setHandoverCondition(handoverCondition);

        // Đổi trạng thái phòng sang NGHIEM_THU để khách bắt đầu nghiệm thu
        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        if (room != null) {
            room.setStatus(RoomStatus.NGHIEM_THU);
            room.setCurrentTenantId(contract.getTenantId());
            room.setCurrentContractId(contract.getId());
            roomRepository.save(room);
        }

        // Thông báo cho chủ nhà
        notificationService.send(contract.getTenantId(), contract.getOwnerId(),
                NotificationScope.INDIVIDUAL,
                "Khách đã ký hợp đồng!",
                "Khách thuê đã ký hợp đồng. Phòng đang chờ nghiệm thu.",
                NotificationType.CONTRACT_SIGNED, contract.getId(), false, null, null);

        // [MỚI] Consume phiếu giảm giá (nếu có)
        // [MỚI] Consume phiếu giảm giá (nếu có) và tạo Snapshot
        if (contract.getVoucherId() != null) {
            try {
                Voucher voucher = voucherValidationService.validateAndLockVoucher(
                    contract.getVoucherId(), contract.getTenantId(), contract.getOwnerId(), contract.getRoomId(), room.getBranchId());
                
                ContractVoucher snapshot = ContractVoucher.builder()
                    .contractId(contract.getId())
                    .voucherId(voucher.getId())
                    .snapshotCode(voucher.getCode())
                    .snapshotDiscountType(voucher.getDiscountType())
                    .snapshotDiscountAmount(voucher.getDiscountAmount())
                    .snapshotDiscountPercent(voucher.getDiscountPercent())
                    .snapshotMaxDiscount(voucher.getMaxDiscountAmount())
                    .snapshotFundedBy(voucher.getFundedBy())
                    .snapshotAppliesTo(voucher.getAppliesToTarget())
                    .snapshotMonthsPerTenant(voucher.getMonthsPerTenant())
                    .build();
                contractVoucherRepository.save(snapshot);
            } catch (Exception e) {
                // If validation fails, we shouldn't block the contract, just remove the voucher
                contract.setVoucherId(null);
            }
        }

        return contractRepository.save(contract);
    }

    @Override
    @Transactional
    public Contract offlineCreateContract(Long ownerId, com.stayhub.api.dto.request.OfflineContractCreateRequest request) {
        
        Room room = roomRepository.findById(request.getRoomId())
            .orElseThrow(() -> new ResourceNotFoundException("PhÃ²ng khÃ´ng tá»“n táº¡i!"));
            
        if (room.getStatus() == RoomStatus.BAO_TRI) {
            throw new IllegalStateException("PhÃ²ng Ä‘ang trong tráº¡ng thÃ¡i Báº¢O TRÃŒ, khÃ´ng thá»ƒ táº¡o há»£p Ä‘á»“ng má»›i!");
        }
        // Tìm hoặc tạo tenant
        User tenant = userRepository.findByPhoneNumber(request.getTenantPhone()).orElseGet(() -> {
            User newUser = new User();
            newUser.setPhoneNumber(request.getTenantPhone());
            newUser.setName(request.getTenantName());
            newUser.setRoleId("TENANT");
            newUser.setStatus(User.UserStatus.ACTIVE);
            newUser.setPasswordHash("$2a$10$dummyhashdummyhashdummyhashdummyhashdummyhashdummyhash"); // Dummy hash
            return userRepository.save(newUser);
        });

        Contract contract = new Contract();
        contract.setRoomId(request.getRoomId());
        contract.setTenantId(tenant.getId());
        contract.setOwnerId(ownerId);
        contract.setStartDate(java.time.LocalDate.parse(request.getStartDate()));
        contract.setEndDate(java.time.LocalDate.parse(request.getEndDate()));
        contract.setMonthlyRent(request.getMonthlyRent());
        contract.setDepositAmount(request.getDepositAmount());
        contract.setElectricityPrice(request.getElectricityPrice());
        contract.setWaterPrice(request.getWaterPrice());
        if (request.getInitialElectricIndex() != null) {
            contract.setInitialElectricIndex(request.getInitialElectricIndex());
        }
        if (request.getInitialWaterIndex() != null) {
            contract.setInitialWaterIndex(request.getInitialWaterIndex());
        }
        contract.setServiceFee(room.getServiceFee() != null ? room.getServiceFee() : 0.0);
        contract.setTerms(request.getTerms());
        contract.setStatus(ContractStatus.PENDING);
        
        Contract saved = contractRepository.save(contract);

        room.setStatus(RoomStatus.CHO_KICH_HOAT);
        room.setCurrentContractId(saved.getId());
        roomRepository.save(room);

        // [MỚI] Consume phiếu giảm giá (nếu có)
        // [MỚI] Consume phiếu giảm giá (nếu có) và tạo Snapshot cho offline
        if (saved.getVoucherId() != null) {
            try {
                Voucher voucher = voucherValidationService.validateAndLockVoucher(
                    saved.getVoucherId(), saved.getTenantId(), saved.getOwnerId(), saved.getRoomId(), room.getBranchId());
                
                ContractVoucher snapshot = ContractVoucher.builder()
                    .contractId(saved.getId())
                    .voucherId(voucher.getId())
                    .snapshotCode(voucher.getCode())
                    .snapshotDiscountType(voucher.getDiscountType())
                    .snapshotDiscountAmount(voucher.getDiscountAmount())
                    .snapshotDiscountPercent(voucher.getDiscountPercent())
                    .snapshotMaxDiscount(voucher.getMaxDiscountAmount())
                    .snapshotFundedBy(voucher.getFundedBy())
                    .snapshotAppliesTo(voucher.getAppliesToTarget())
                    .snapshotMonthsPerTenant(voucher.getMonthsPerTenant())
                    .build();
                contractVoucherRepository.save(snapshot);
            } catch (Exception e) {
                // Offline creation, just remove voucher if invalid
                saved.setVoucherId(null);
            }
        }

        return saved;
    }

    @Override
    @Transactional
    public Contract cancelOfflineContract(Long contractId, Long ownerId) {
        Contract contract = contractRepository.findByIdWithPessimisticLock(contractId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng ID: " + contractId));

        if (!contract.getOwnerId().equals(ownerId)) {
            throw new IllegalArgumentException("Không có quyền hủy hợp đồng này.");
        }
        if (contract.getStatus() != ContractStatus.PENDING) {
            throw new IllegalStateException("Chỉ có thể hủy hợp đồng đang chờ kích hoạt.");
        }

        contract.setStatus(ContractStatus.CANCELLED);
        contract.setTerminatedAt(java.time.LocalDateTime.now());
        contractRepository.save(contract);
        
        // Xử lý Voucher Lifecycle: Hoàn lại Quota khi hủy trước khi ở
        if (contract.getVoucherId() != null) {
            voucherRepository.findByIdWithPessimisticLock(contract.getVoucherId()).ifPresent(v -> {
                if (v.getUsedCount() > 0) {
                    v.setUsedCount(v.getUsedCount() - 1);
                    voucherRepository.save(v);
                }
            });
        }

        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        if (room != null && contract.getId().equals(room.getCurrentContractId())) {
            room.setStatus(RoomStatus.TRONG);
            room.setCurrentContractId(null);
            roomRepository.save(room);
        }

        return contract;
    }
}

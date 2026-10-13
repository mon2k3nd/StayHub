package com.stayhub.api.controller;

import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.entity.ElectronicContract;
import com.stayhub.api.entity.ElectronicContractStatus;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.RoomStatus;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.ElectronicContractRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.service.BillService;
import com.stayhub.api.service.ContractAiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/v1/electronic-contracts")
@RequiredArgsConstructor
@Slf4j
public class ElectronicContractController {

    private final ElectronicContractRepository electronicContractRepository;
    private final ContractAiService contractAiService;
    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;
    private final DisputeChatController disputeChatController;
    private final BillService billService;
    private final com.stayhub.api.repository.StaffAssignmentRepository staffAssignmentRepository;

    @PostMapping("/draft")
    public Mono<ResponseEntity<ElectronicContract>> createDraft(@RequestBody Map<String, Long> payload, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        
        Long rentalRequestId = payload.get("rentalRequestId");
        Long roomId = payload.get("roomId");
        Long tenantId = payload.get("tenantId");

        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Không tìm thấy phòng"));
                
        final Long secureOwnerId = room.getOwnerId();

        if (isOwner) {
            if (!secureOwnerId.equals(userId)) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền tạo hợp đồng cho phòng này");
            }
        } else if (isStaff) {
            boolean hasAssignment = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId).stream()
                    .anyMatch(a -> a.getBranchId().equals(room.getBranchId()));
            if (!hasAssignment) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không được phân công quản lý nhánh này");
            }
        } else {
            if (!userId.equals(tenantId)) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Dữ liệu tenant không hợp lệ");
            }
        }

        // 1. Sinh AI Appendix (Sử dụng secureOwnerId)
        return contractAiService.generateAiAppendix(rentalRequestId, roomId, tenantId, secureOwnerId)
                .flatMap(appendix -> {
                    ElectronicContract contract = ElectronicContract.builder()
                            .rentalRequestId(rentalRequestId)
                            .roomId(roomId)
                            .tenantId(tenantId)
                            .ownerId(secureOwnerId)
                            .status(ElectronicContractStatus.PENDING_AI)
                            .aiAppendixClauses(appendix)
                            .tenantSignatureOtp("123456") // Mock OTP
                            .ownerSignatureOtp("654321") // Mock OTP
                            .build();

                    // 2. Lưu vào DB
                    ElectronicContract savedContract = electronicContractRepository.save(contract);

                    // 3. Render PDF
                    return contractAiService.generateAndUploadPdf(savedContract)
                            .map(pdfUrl -> {
                                savedContract.setRawPdfUrl(pdfUrl);
                                savedContract.setStatus(ElectronicContractStatus.AWAITING_SIGNATURES);
                                electronicContractRepository.save(savedContract);
                                return ResponseEntity.ok(savedContract);
                            });
                });
    }

    @PostMapping("/{id}/sign")
    @Transactional
    public ResponseEntity<?> signContract(@PathVariable Long id, @RequestBody Map<String, String> payload, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        
        String role = payload.get("role"); // "TENANT" or "OWNER"
        String otp = payload.get("otp");

        // 1. Lấy hợp đồng với Pessimistic Lock
        ElectronicContract contract = electronicContractRepository.findByIdForSigning(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hợp đồng điện tử"));
                
        if ("TENANT".equals(role) && !userId.equals(contract.getTenantId())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không phải là khách thuê của hợp đồng này");
        }
        if ("OWNER".equals(role) && !userId.equals(contract.getOwnerId())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không phải là chủ nhà của hợp đồng này");
        }

        if (contract.getStatus() == ElectronicContractStatus.REJECTED || contract.getStatus() == ElectronicContractStatus.OWNER_SIGNED) {
            throw new IllegalStateException("Hợp đồng này không thể ký nữa vì đã hoàn tất hoặc bị hủy.");
        }

        // 2. Xác thực OTP
        if ("TENANT".equals(role)) {
            if (!contract.getTenantSignatureOtp().equals(otp)) {
                throw new IllegalArgumentException("Mã OTP không hợp lệ.");
            }
            if (contract.getStatus() == ElectronicContractStatus.AWAITING_SIGNATURES) {
                contract.setStatus(ElectronicContractStatus.TENANT_SIGNED);
                contract.setSignedAt(LocalDateTime.now());
                
                // PhAt s kin SSE cho KhAch thuA
                disputeChatController.broadcastTenantSignedSuccess(contract.getRoomId());
            } else {
                throw new IllegalStateException("Hợp đồng chưa sẵn sàng để khách thuê ký.");
            }
        } else if ("OWNER".equals(role)) {
            if (!contract.getOwnerSignatureOtp().equals(otp)) {
                throw new IllegalArgumentException("Mã OTP không hợp lệ.");
            }
            if (contract.getStatus() == ElectronicContractStatus.TENANT_SIGNED) {
                contract.setStatus(ElectronicContractStatus.OWNER_SIGNED);
                contract.setSignedAt(LocalDateTime.now());

                // THE FINAL DATABASE TRIGGER
                activateContractAndRoom(contract);
                
                // Phát sự kiện SSE
                disputeChatController.broadcastContractSignedSuccess(contract.getRoomId());
            } else {
                throw new IllegalStateException("Khách thuê chưa ký, Chủ nhà không thể ký.");
            }
        } else {
            throw new IllegalArgumentException("Vai trò không hợp lệ.");
        }

        electronicContractRepository.save(contract);
        return ResponseEntity.ok(Map.of("success", true, "status", contract.getStatus()));
    }

    private void activateContractAndRoom(ElectronicContract ec) {
        // Activate main contract
        contractRepository.findByRoomIdAndTenantIdAndStatus(ec.getRoomId(), ec.getTenantId(), ContractStatus.PENDING)
                .ifPresent(mainContract -> {
                    mainContract.setStatus(ContractStatus.ACTIVE);
                    contractRepository.save(mainContract);
                });

        // Assign tenant to room
        Room room = roomRepository.findById(ec.getRoomId())
                .orElseThrow(() -> new IllegalStateException("Không tìm thấy phòng"));
        
        if (room.getStatus() != RoomStatus.TRONG && room.getStatus() != RoomStatus.CHO_DUYET && room.getStatus() != RoomStatus.NGHIEM_THU) {
            // Already occupied, but let's override for the sake of the trigger or throw error
            log.warn("Room {} is not empty or waiting handover, but owner signed the contract. Forcing update.", room.getId());
        }
        
        room.setStatus(RoomStatus.DA_THUE);
        roomRepository.save(room);
        log.info("Room {} activated", room.getId());
    }

    @PostMapping("/{id}/upload-paper")
    @Transactional
    public ResponseEntity<?> uploadPaperContract(@PathVariable Long id, @RequestBody Map<String, String> payload, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        
        String paperContractImages = payload.get("paperContractImages");

        ElectronicContract contract = electronicContractRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hợp đồng điện tử"));
                
        if (!userId.equals(contract.getTenantId())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền tải hợp đồng giấy cho phòng này");
        }

        if (contract.getStatus() == ElectronicContractStatus.REJECTED || contract.getStatus() == ElectronicContractStatus.OWNER_SIGNED) {
            throw new IllegalStateException("Hợp đồng này không thể tải lên ảnh nữa.");
        }

        contract.setPaperContractImages(paperContractImages);
        contract.setStatus(ElectronicContractStatus.TENANT_SIGNED);
        contract.setSignedAt(LocalDateTime.now());

        electronicContractRepository.save(contract);
        
        // Phát sự kiện SSE cho Khách thuê
        disputeChatController.broadcastTenantSignedSuccess(contract.getRoomId());

        return ResponseEntity.ok(Map.of("success", true, "status", contract.getStatus()));
    }
}

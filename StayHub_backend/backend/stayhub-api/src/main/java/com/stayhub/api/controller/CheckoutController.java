package com.stayhub.api.controller;

import com.stayhub.api.dto.CheckoutRequestDto;
import com.stayhub.api.dto.CreateCheckoutBillDto;
import com.stayhub.api.entity.CheckoutRequest;
import com.stayhub.api.service.CheckoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.stayhub.api.dto.request.*;

import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/checkouts")
@RequiredArgsConstructor
public class CheckoutController {

    private final CheckoutService checkoutService;
    private final com.stayhub.api.repository.RoomRepository roomRepository;
    private final com.stayhub.api.repository.StaffAssignmentRepository staffAssignmentRepository;
    private final com.stayhub.api.repository.CheckoutRequestRepository checkoutRequestRepository;

    // 1. Khách gửi yêu cầu trả phòng (Giai đoạn 1)
    @PostMapping
    public ResponseEntity<Map<String, Object>> createCheckoutRequest(
            @ModelAttribute CheckoutRequestDto requestDto,
            @RequestParam("files") List<MultipartFile> files,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        requestDto.setTenantId(userId); // Ensure tenantId is securely set from token
        CheckoutRequest created = checkoutService.createCheckoutRequest(requestDto, files);
        return ResponseEntity.ok(Map.of("success", true, "data", created));
    }

    // 2. Danh sách yêu cầu cho chủ nhà (Giai đoạn 2)
    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<Map<String, Object>> getRequestsForOwner(@PathVariable Long ownerId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(ownerId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_STAFF"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        List<CheckoutRequest> requests = checkoutService.getRequestsForOwner(ownerId);
        
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (isStaff) {
             List<com.stayhub.api.entity.StaffAssignment> assignments = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId);
             requests = requests.stream().filter(req -> {
                 com.stayhub.api.entity.Room room = roomRepository.findById(req.getRoomId()).orElse(null);
                 if (room == null) return false;
                 return assignments.stream().anyMatch(a -> a.getBranchId().equals(room.getBranchId()));
             }).collect(java.util.stream.Collectors.toList());
        }
        
        return ResponseEntity.ok(Map.of("success", true, "data", requests));
    }
    
    // Khách xem yêu cầu của mình
    @GetMapping("/tenant/{tenantId}")
    public ResponseEntity<Map<String, Object>> getRequestsForTenant(@PathVariable Long tenantId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(tenantId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        List<CheckoutRequest> requests = checkoutService.getRequestsForTenant(tenantId);
        return ResponseEntity.ok(Map.of("success", true, "data", requests));
    }



    // 3. Chủ nhà từ chối
    @PutMapping("/{id}/reject")
    public ResponseEntity<Map<String, Object>> rejectRequest(
            @PathVariable Long id,
            @RequestBody RejectCheckoutRequest request,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER") || a.getAuthority().equals("ROLE_STAFF"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        
        Long userId = (Long) auth.getPrincipal();
        verifyCheckoutOwnership(userId, id, auth);
        
        String ownerReason = request.getReason();
        if (ownerReason == null || ownerReason.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Lý do từ chối không được để trống"));
        }
        CheckoutRequest updated = checkoutService.rejectRequest(id, ownerReason);
        return ResponseEntity.ok(Map.of("success", true, "data", updated));
    }

    // 4. Chủ nhà tạo hóa đơn quyết toán
    @PostMapping("/{id}/approve-and-bill")
    public ResponseEntity<Map<String, Object>> approveAndCreateBill(
            @PathVariable Long id,
            @RequestBody CreateCheckoutBillDto billDto,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER") || a.getAuthority().equals("ROLE_STAFF"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
            
        Long userId = (Long) auth.getPrincipal();
        verifyCheckoutOwnership(userId, id, auth);
        
        if (billDto.getDamageFee() != null && billDto.getDamageFee() > 0) {
            if (billDto.getDamageReason() == null || billDto.getDamageReason().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Bắt buộc nhập lý do phạt nếu tiền phạt > 0"));
            }
        }
        var result = checkoutService.approveAndCreateBill(id, billDto);
        return ResponseEntity.ok(Map.of("success", true, "data", result));
    }

    // 5. Tích hợp AI so sánh ảnh
    @GetMapping("/{id}/ai-analyze")
    public ResponseEntity<Map<String, Object>> analyzeWithAI(@PathVariable Long id, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        verifyCheckoutOwnership(userId, id, auth);
        
        String aiSuggestion = checkoutService.analyzeImagesWithAI(id);
        return ResponseEntity.ok(Map.of("success", true, "data", aiSuggestion));
    }

    // 6. Lấy thông tin Tracking (Dành cho Tenant)
    @GetMapping("/{id}/tracking-summary")
    public ResponseEntity<Map<String, Object>> getTrackingSummary(@PathVariable Long id, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        verifyCheckoutOwnership(userId, id, auth);
        
        Map<String, Object> summary = checkoutService.getTrackingSummary(id);
        return ResponseEntity.ok(Map.of("success", true, "data", summary));
    }

    // 7. Lấy chi tiết thông tin trả phòng (Cho Notification Detail)
    @GetMapping("/{id}/details")
    public ResponseEntity<Map<String, Object>> getCheckoutDetails(@PathVariable Long id, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        verifyCheckoutOwnership(userId, id, auth);
        
        Map<String, Object> details = checkoutService.getCheckoutDetails(id);
        if (details == null) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Không tìm thấy yêu cầu"));
        }
        return ResponseEntity.ok(Map.of("success", true, "data", details));
    }

    private void verifyCheckoutOwnership(Long userId, Long checkoutId, org.springframework.security.core.Authentication auth) {
        CheckoutRequest request = checkoutRequestRepository.findById(checkoutId).orElse(null);
        if (request == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Không tìm thấy yêu cầu");
        }
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        if (isOwner) {
            com.stayhub.api.entity.Room room = roomRepository.findById(request.getRoomId()).orElse(null);
            if (room == null || !room.getOwnerId().equals(userId)) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên yêu cầu này");
            }
        } else if (isStaff) {
            com.stayhub.api.entity.Room room = roomRepository.findById(request.getRoomId()).orElse(null);
            if (room == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND);
            boolean hasAssignment = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId).stream()
                    .anyMatch(a -> a.getBranchId().equals(room.getBranchId()));
            if (!hasAssignment) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên yêu cầu này");
            }
        } else if (!request.getTenantId().equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên yêu cầu này");
        }
    }
}

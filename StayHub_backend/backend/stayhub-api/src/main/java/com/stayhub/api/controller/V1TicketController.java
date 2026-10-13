package com.stayhub.api.controller;

import com.stayhub.api.config.CheckRole;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Maintenance;
import com.stayhub.api.repository.MaintenanceRepository;
import com.stayhub.api.service.V1TicketService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/tickets")
@RequiredArgsConstructor
@Slf4j
public class V1TicketController {

    private final V1TicketService ticketService;
    private final MaintenanceRepository maintenanceRepository;
    private final com.stayhub.api.repository.StaffAssignmentRepository staffAssignmentRepository;
    private final com.stayhub.api.repository.RoomRepository roomRepository;

    @GetMapping("/staff/{staffId}")
    public ResponseEntity<ApiResponse<List<Maintenance>>> getTicketsByStaff(
            @PathVariable Long staffId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        if (isOwner) {
            boolean managesStaff = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(staffId)
                    .stream()
                    .anyMatch(a -> a.getOwnerId().equals(userId));
            if (!managesStaff) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem ticket của nhân viên này");
            }
        } else if (!userId.equals(staffId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem ticket của nhân viên khác");
        }
        
        return ResponseEntity.ok(ApiResponse.<List<Maintenance>>builder()
                .success(true).message("Thành công!")
                .data(ticketService.getTicketsByStaff(staffId)).build());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Maintenance>> getTicketById(@PathVariable Long id, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        Maintenance ticket = ticketService.getTicketById(id);
        // Chỉ người tạo (tenant), nhân viên được assign, hoặc owner mới xem được
        boolean isTenant = ticket.getTenantId() != null && ticket.getTenantId().equals(userId);
        boolean isAssignedStaff = ticket.getAssignedStaffId() != null && ticket.getAssignedStaffId().equals(userId);
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isTenant && !isAssignedStaff && !isOwner) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem ticket này");
        }
        return ResponseEntity.ok(ApiResponse.<Maintenance>builder()
                .success(true).message("Thành công!")
                .data(ticket).build());
    }

    @GetMapping("/tenant/{tenantId}")
    public ResponseEntity<ApiResponse<List<Maintenance>>> getTicketsByTenant(
            @PathVariable Long tenantId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        if (isOwner) {
            List<Maintenance> tickets = ticketService.getTicketsByTenant(tenantId);
            tickets = tickets.stream().filter(t -> {
                return roomRepository.findById(t.getRoomId())
                        .map(r -> r.getOwnerId().equals(userId))
                        .orElse(false);
            }).collect(java.util.stream.Collectors.toList());
            return ResponseEntity.ok(ApiResponse.<List<Maintenance>>builder()
                    .success(true).message("Thành công!")
                    .data(tickets).build());
        } else if (!userId.equals(tenantId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem ticket của người khác");
        }
        
        return ResponseEntity.ok(ApiResponse.<List<Maintenance>>builder()
                .success(true).message("Thành công!")
                .data(ticketService.getTicketsByTenant(tenantId)).build());
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<Maintenance>>> getTicketsByOwner(
            @PathVariable Long ownerId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!userId.equals(ownerId) && !isStaff) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem ticket của chủ nhà khác");
        }
        return ResponseEntity.ok(ApiResponse.<List<Maintenance>>builder()
                .success(true).message("Thành công!")
                .data(ticketService.getTicketsByOwner(ownerId)).build());
    }


    @PostMapping("/create")
    @CheckRole({"TENANT", "ACTIVE_TENANT"})
    public ResponseEntity<ApiResponse<Maintenance>> createTicket(
            Authentication auth,
            @RequestParam("roomId") Long roomId,
            @RequestParam("category") String category,
            @RequestParam("description") String description,
            @RequestParam(value = "severity", required = false) String severity,
            @RequestParam(value = "tenantDesire", required = false) String tenantDesire,
            @RequestParam(value = "poolId", required = false) Long poolId,
            @RequestParam(value = "sharedFacilityId", required = false) Long sharedFacilityId,
            @RequestParam(value = "image", required = false) MultipartFile image) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        Long tenantId = (Long) auth.getPrincipal();
        Maintenance maintenance;
        if (sharedFacilityId != null) {
            maintenance = ticketService.createTicketWithFacility(tenantId, roomId, sharedFacilityId, category, description, severity, tenantDesire, image);
        } else if (poolId != null) {
            maintenance = ticketService.createTicketWithPool(tenantId, roomId, poolId, category, description, severity, tenantDesire, image);
        } else {
            maintenance = ticketService.createTicket(tenantId, roomId, category, description, severity, tenantDesire, image);
        }

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<Maintenance>builder()
                        .success(true)
                        .message("Tạo yêu cầu sửa chữa sự cố thành công!")
                        .data(maintenance)
                        .build());
    }

    @PutMapping("/assign")
    @CheckRole("OWNER")
    public ResponseEntity<ApiResponse<Maintenance>> assignTicket(
            Authentication auth,
            @RequestBody Map<String, Object> body) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        if (!body.containsKey("ticketId") || !body.containsKey("assignedStaffId")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu tham số ticketId hoặc assignedStaffId");
        }

        Long ownerId = (Long) auth.getPrincipal();
        Long ticketId = Long.valueOf(body.get("ticketId").toString());
        Long assignedStaffId = Long.valueOf(body.get("assignedStaffId").toString());

        Maintenance maintenance = ticketService.assignTicket(ownerId, ticketId, assignedStaffId);

        return ResponseEntity.ok(ApiResponse.<Maintenance>builder()
                .success(true)
                .message("Đã giao việc cho nhân viên thành công!")
                .data(maintenance)
                .build());
    }

    @PutMapping("/staff-complete")
    @CheckRole("STAFF")
    public ResponseEntity<ApiResponse<Maintenance>> completeTicket(
            Authentication auth,
            @RequestParam("ticketId") Long ticketId,
            @RequestParam("materialCost") Double materialCost,
            @RequestParam(value = "isSuccessful", required = false) Boolean isSuccessful,
            @RequestParam(value = "repairDetails", required = false) String repairDetails,
            @RequestParam(value = "image", required = false) MultipartFile image) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        Long staffId = (Long) auth.getPrincipal();
        Maintenance maintenance = ticketService.completeTicket(staffId, ticketId, materialCost, isSuccessful, repairDetails, image);

        return ResponseEntity.ok(ApiResponse.<Maintenance>builder()
                .success(true)
                .message("Nhân viên báo cáo hoàn thành thành công!")
                .data(maintenance)
                .build());
    }

    @PutMapping("/owner-complete")
    @CheckRole("OWNER")
    public ResponseEntity<ApiResponse<Maintenance>> ownerCompleteTicket(
            Authentication auth,
            @RequestParam("ticketId") Long ticketId,
            @RequestParam("materialCost") Double materialCost,
            @RequestParam(value = "isSuccessful", required = false) Boolean isSuccessful,
            @RequestParam(value = "repairDetails", required = false) String repairDetails,
            @RequestParam(value = "image", required = false) MultipartFile image) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        Long ownerId = (Long) auth.getPrincipal();
        Maintenance maintenance = ticketService.ownerCompleteTicket(ownerId, ticketId, materialCost, isSuccessful, repairDetails, image);

        return ResponseEntity.ok(ApiResponse.<Maintenance>builder()
                .success(true)
                .message("Chủ nhà tự hoàn tất sự cố thành công!")
                .data(maintenance)
                .build());
    }

    @PostMapping("/owner-approve")
    @CheckRole("OWNER")
    public ResponseEntity<ApiResponse<Void>> approveTicket(
            Authentication auth,
            @RequestBody Map<String, Object> body) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        if (!body.containsKey("ticketId") || !body.containsKey("staffBonus")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu tham số ticketId hoặc staffBonus");
        }

        Long ownerId = (Long) auth.getPrincipal();
        Long ticketId = Long.valueOf(body.get("ticketId").toString());
        Double staffBonus = Double.valueOf(body.get("staffBonus").toString());

        ticketService.approveTicket(ownerId, ticketId, staffBonus);

        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Chủ nhà phê duyệt chi phí thành công!")
                .build());
    }

    @PostMapping("/owner-cancel")
    @CheckRole("OWNER")
    public ResponseEntity<ApiResponse<Void>> cancelTicket(
            Authentication auth,
            @RequestBody Map<String, Object> body) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        if (!body.containsKey("ticketId") || !body.containsKey("reason")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu tham số ticketId hoặc reason");
        }

        Long ownerId = (Long) auth.getPrincipal();
        Long ticketId = Long.valueOf(body.get("ticketId").toString());
        String reason = body.get("reason").toString();

        ticketService.cancelTicket(ownerId, ticketId, reason);

        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Đã hủy yêu cầu sửa chữa!")
                .build());
    }

    @PostMapping("/owner-reject")
    @CheckRole("OWNER")
    public ResponseEntity<ApiResponse<Void>> rejectTicket(
            Authentication auth,
            @RequestBody Map<String, Object> body) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        if (!body.containsKey("ticketId") || !body.containsKey("reason")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu tham số ticketId hoặc reason");
        }

        Long ownerId = (Long) auth.getPrincipal();
        Long ticketId = Long.valueOf(body.get("ticketId").toString());
        String reason = body.get("reason").toString();

        ticketService.rejectTicket(ownerId, ticketId, reason);

        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Đã từ chối nghiệm thu, yêu cầu nhân viên xử lý lại!")
                .build());
    }

    @PatchMapping("/{id}/status")
    @CheckRole({"STAFF", "OWNER"})
    public ResponseEntity<ApiResponse<Maintenance>> updateTicketStatus(
            Authentication auth,
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        if (!body.containsKey("status")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu tham số status");
        }

        Long userId = (Long) auth.getPrincipal();
        String status = body.get("status").toString();

        Maintenance maintenance = ticketService.updateTicketStatus(userId, id, status);

        return ResponseEntity.ok(ApiResponse.<Maintenance>builder()
                .success(true)
                .message("Cập nhật trạng thái thành công!")
                .data(maintenance)
                .build());
    }
}

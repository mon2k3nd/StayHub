package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Bill;
import com.stayhub.api.service.BillService;
import com.stayhub.api.service.CheckoutService;
import com.stayhub.api.service.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.stayhub.api.dto.request.*;

import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import com.stayhub.api.repository.StaffWalletRepository;
import com.stayhub.api.entity.StaffWallet;
import com.stayhub.api.repository.CashSessionRepository;
import com.stayhub.api.entity.CashSession;

import com.stayhub.api.service.NotificationService;
import com.stayhub.api.entity.NotificationType;
import com.stayhub.api.entity.NotificationScope;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.VoucherRepository;
import com.stayhub.api.repository.MaintenanceRepository;
import com.stayhub.api.entity.Maintenance;
import com.stayhub.api.repository.DisputeMessageRepository;
import com.stayhub.api.entity.DisputeMessage;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/v1/bills")
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class V1BillController {

    private final BillService billService;
    private final CheckoutService checkoutService;
    private final DisputeChatController disputeChatController;
    private final BillRepository billRepository;
    private final RoomRepository roomRepository;
    private final StaffWalletRepository staffWalletRepository;
    private final CashSessionRepository cashSessionRepository;
    private final VoucherRepository voucherRepository;
    private final NotificationService notificationService;
    private final MaintenanceRepository maintenanceRepository;
    private final DisputeMessageRepository disputeMessageRepository;
    private final StaffService staffService;
    private final com.stayhub.api.repository.StaffAssignmentRepository staffAssignmentRepository;
    private final com.stayhub.api.repository.BranchRepository branchRepository;

    /** Khách thuê khiếu nại hóa đơn */
    @PostMapping("/{id}/dispute")
    public ResponseEntity<ApiResponse<Bill>> disputeBill(
            @PathVariable Long id,
            @RequestBody DisputeBillRequest request,
            org.springframework.security.core.Authentication auth) {
            
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();

        String reason = (request != null && request.getReason() != null) ? request.getReason() : "Khách thuê có thắc mắc về hóa đơn";
        
        Bill bill = billRepository.findById(id).orElseThrow(() -> new RuntimeException("Bill not found"));
        
        if (!bill.getTenantId().equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền khiếu nại hóa đơn của người khác");
        }
        
        bill.setStatus("DISPUTED");
        Bill updated = billRepository.save(bill);

        Maintenance incident = Maintenance.builder()
                .roomId(bill.getRoomId())
                .tenantId(bill.getTenantId())
                .category("Khiếu nại Hóa đơn")
                .description("Hóa đơn #" + bill.getId() + " bị khiếu nại. Lý do: " + reason)
                .severity("HIGH")
                .status("NEW")
                .build();
        maintenanceRepository.save(incident);

        DisputeMessage initialMessage = DisputeMessage.builder()
                .billId(bill.getId())
                .senderId(bill.getTenantId())
                .message("Tôi có thắc mắc về hóa đơn này. Lý do: " + reason)
                .createdAt(LocalDateTime.now())
                .build();
        disputeMessageRepository.save(initialMessage);

        roomRepository.findById(bill.getRoomId()).ifPresent(room -> {
            notificationService.send(bill.getTenantId(), room.getOwnerId(), NotificationScope.INDIVIDUAL,
                    "Khiếu nại Hóa đơn", 
                    "Khách thuê phòng " + room.getRoomName() + " vừa tạo khiếu nại hóa đơn. Lý do: " + reason,
                    NotificationType.SYSTEM_ALERT, bill.getId(), false, null, "{\"event\":\"BILL_DISPUTED\"}");
        });

        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true).message("Đã gửi khiếu nại tới Chủ nhà!")
                .data(updated).build());
    }

    /** Lấy chi tiết hóa đơn theo ID */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Bill>> getById(@PathVariable Long id, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        verifyBillOwnership(userId, id, auth);
        
        Bill bill = billRepository.findById(id).orElseThrow(() -> new RuntimeException("Bill not found"));
        
        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true).message("Thành công!")
                .data(bill).build());
    }

    /** Lấy tất cả hóa đơn của khách thuê */
    @GetMapping("/tenant/{tenantId}")
    public ResponseEntity<ApiResponse<List<Bill>>> getByTenant(@PathVariable Long tenantId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        
        List<Bill> bills = billService.getByTenant(tenantId);
        
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        if (isOwner) {
             bills = bills.stream().filter(b -> {
                 com.stayhub.api.entity.Room room = roomRepository.findById(b.getRoomId()).orElse(null);
                 return room != null && room.getOwnerId().equals(userId);
             }).collect(java.util.stream.Collectors.toList());
        } else if (isStaff) {
             List<com.stayhub.api.entity.StaffAssignment> assignments = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId);
             bills = bills.stream().filter(b -> {
                 com.stayhub.api.entity.Room room = roomRepository.findById(b.getRoomId()).orElse(null);
                 if (room == null) return false;
                 return assignments.stream().anyMatch(a -> a.getBranchId().equals(room.getBranchId()));
             }).collect(java.util.stream.Collectors.toList());
        } else if (!userId.equals(tenantId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true).message("Thành công!")
                .data(bills).build());
    }

    /** Lấy hóa đơn chưa thanh toán của khách */
    @GetMapping("/tenant/{tenantId}/unpaid")
    public ResponseEntity<ApiResponse<List<Bill>>> getUnpaid(@PathVariable Long tenantId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        
        List<Bill> bills = billService.getUnpaidByTenant(tenantId);
        
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        if (isOwner) {
             bills = bills.stream().filter(b -> {
                 com.stayhub.api.entity.Room room = roomRepository.findById(b.getRoomId()).orElse(null);
                 return room != null && room.getOwnerId().equals(userId);
             }).collect(java.util.stream.Collectors.toList());
        } else if (isStaff) {
             List<com.stayhub.api.entity.StaffAssignment> assignments = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId);
             bills = bills.stream().filter(b -> {
                 com.stayhub.api.entity.Room room = roomRepository.findById(b.getRoomId()).orElse(null);
                 if (room == null) return false;
                 return assignments.stream().anyMatch(a -> a.getBranchId().equals(room.getBranchId()));
             }).collect(java.util.stream.Collectors.toList());
        } else if (!userId.equals(tenantId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true).message("Thành công!")
                .data(bills).build());
    }

    /** Lấy hóa đơn theo phòng */
    @GetMapping("/room/{roomId}")
    public ResponseEntity<ApiResponse<List<Bill>>> getByRoom(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        com.stayhub.api.entity.Room room = roomRepository.findById(roomId).orElseThrow(() -> new RuntimeException("Room not found"));
        
        if (isOwner) {
            if (!room.getOwnerId().equals(userId)) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        } else if (isStaff) {
            boolean hasAssignment = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId).stream()
                    .anyMatch(a -> a.getBranchId().equals(room.getBranchId()));
            if (!hasAssignment) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        } else {
            // Check if tenant
            boolean isTenant = billService.getByRoom(roomId).stream().anyMatch(b -> b.getTenantId().equals(userId));
            if (!isTenant) {
                throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
            }
        }
        
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true).message("Thành công!")
                .data(billService.getByRoom(roomId)).build());
    }

    /** Lấy hóa đơn theo chủ nhà */
    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<Bill>>> getByOwner(@PathVariable Long ownerId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(ownerId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_STAFF"))) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true).message("Thành công!")
                .data(billService.getByOwner(ownerId)).build());
    }

    /** Lấy hóa đơn theo nhân viên */
    @GetMapping("/staff/{staffId}")
    public ResponseEntity<ApiResponse<List<Bill>>> getByStaff(@PathVariable Long staffId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        if (isOwner) {
             boolean managesStaff = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(staffId).stream()
                     .anyMatch(a -> a.getOwnerId().equals(userId));
             if (!managesStaff) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        } else if (!userId.equals(staffId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true).message("Thành công!")
                .data(billService.getByStaff(staffId)).build());
    }

    /** Chủ nhà / Nhân viên tạo hóa đơn tháng. Giá điện/nước lấy từ hợp đồng. */
    @PostMapping
    public ResponseEntity<ApiResponse<Bill>> createBill(
            @RequestBody Bill bill,
            org.springframework.security.core.Authentication auth) {
            
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Room room = null;
        if (bill.getRoomId() != null) {
            room = roomRepository.findById(bill.getRoomId()).orElse(null);
        } else if (bill.getContractId() != null) {
            com.stayhub.api.entity.Contract contract = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ContractRepository.class).findById(bill.getContractId()).orElse(null);
            if (contract != null) {
                room = roomRepository.findById(contract.getRoomId()).orElse(null);
            }
        }
        
        if (room == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.BAD_REQUEST, "Không xác định được phòng");
        }
        
        if (isStaff) {
             final com.stayhub.api.entity.Room finalRoom = room;
             java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
             boolean hasAccess = assignments.stream().anyMatch(a -> a.getBranchId().equals(finalRoom.getBranchId()));
             if (!hasAccess) {
                 throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
             }
        } else {
             if (!room.getOwnerId().equals(userId)) {
                 throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền tạo hóa đơn cho phòng này");
             }
        }

        Bill saved = billService.createBill(bill);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<Bill>builder()
                        .success(true).message("Tạo hóa đơn thành công!")
                        .data(saved).build());
    }

    /** Chốt số và tạo hóa đơn hàng loạt */
    @PostMapping("/batch-generate")
    public ResponseEntity<ApiResponse<List<Bill>>> batchGenerateBills(
            @RequestBody List<Bill> bills,
            org.springframework.security.core.Authentication auth) {
            
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = isStaff ? staffService.getAssignments(userId) : java.util.Collections.emptyList();

        List<Bill> savedBills = new java.util.ArrayList<>();
        for (Bill bill : bills) {
            com.stayhub.api.entity.Room room = null;
            if (bill.getRoomId() != null) {
                room = roomRepository.findById(bill.getRoomId()).orElse(null);
            } else if (bill.getContractId() != null) {
                com.stayhub.api.entity.Contract contract = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ContractRepository.class).findById(bill.getContractId()).orElse(null);
                if (contract != null) {
                    room = roomRepository.findById(contract.getRoomId()).orElse(null);
                }
            }
            
            if (room != null) {
                boolean hasAccess = false;
                if (isStaff) {
                     com.stayhub.api.entity.Room finalRoom = room;
                     hasAccess = assignments.stream().anyMatch(a -> a.getBranchId().equals(finalRoom.getBranchId()));
                } else {
                     hasAccess = room.getOwnerId().equals(userId);
                }
                
                if (hasAccess) {
                    savedBills.add(billService.createBill(bill));
                    // Trigger auto send multi-channel Zalo OA (Mock)
                    log.info("Zalo OA (Mock): Đã gửi thông báo hóa đơn tự động cho Phòng ID={}", bill.getRoomId());
                } else {
                    log.warn("Bỏ qua tạo bill cho phòng {} do không có quyền", room.getId());
                }
            }
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<List<Bill>>builder()
                        .success(true).message("Chốt số hàng loạt thành công!")
                        .data(savedBills).build());
    }

    /** Đánh dấu đã thanh toán tiền mặt */
    @PostMapping("/{id}/pay-cash")
    public ResponseEntity<ApiResponse<Bill>> payCash(
            @PathVariable Long id,
            @RequestBody(required = false) CashPaymentRequest request,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long staffId = (Long) auth.getPrincipal();
        
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        
        if (!isStaff && !isOwner) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền thực hiện thanh toán");
        }

        verifyBillOwnership(staffId, id, auth);

        Bill bill = billRepository.findById(id).orElse(null);

        if (auth != null && auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"))) {
            // Branch access already checked by verifyBillOwnership

            // Check max_cash_limit
            if (bill != null && bill.getTotalAmount() != null) {
                StaffWallet wallet = staffWalletRepository.findByStaffId(staffId).orElse(null);
                if (wallet != null && wallet.getMaxCashLimit() != null) {
                    double currentHoldings = wallet.getCashCollected() - wallet.getCashSpent();
                    if (currentHoldings + bill.getTotalAmount() > wallet.getMaxCashLimit()) {
                        throw new RuntimeException("Vượt quá định mức tiền mặt cho phép (" + wallet.getMaxCashLimit() + "đ). Vui lòng nộp bớt tiền mặt cho Chủ trọ.");
                    }
                }
            }
        }

        // Validate sessionId if present
        if (request != null && request.getSessionId() != null) {
            String sessionId = request.getSessionId();
            CashSession session = cashSessionRepository.findBySessionId(sessionId).orElse(null);
            if (session == null || !"PENDING".equals(session.getStatus())) {
                throw new RuntimeException("Phiên thu tiền không hợp lệ hoặc đã hoàn tất.");
            }
            session.setStatus("COMPLETED");
            session.setCompletedAt(LocalDateTime.now());
            if (bill != null) session.setAmount(bill.getTotalAmount());
            cashSessionRepository.save(session);
        }

        Bill updated = billService.payCash(id, staffId);
        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true).message("Đã ghi nhận thanh toán!")
                .data(updated).build());
    }

    /** Chủ nhà xác nhận đã nhận tiền mặt */
    @PostMapping("/{id}/confirm-cash")
    public ResponseEntity<ApiResponse<Bill>> confirmCash(
            @PathVariable Long id,
            @RequestBody(required = false) CashConfirmRequest request,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long ownerId = (Long) auth.getPrincipal();
        
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isOwner) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ chủ nhà mới có thể xác nhận thu tiền mặt");
        }
        
        Bill bill = billRepository.findById(id).orElseThrow(() -> new RuntimeException("Bill not found"));
        com.stayhub.api.entity.Room room = roomRepository.findById(bill.getRoomId()).orElse(null);
        if (room == null || !room.getOwnerId().equals(ownerId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không phải chủ phòng này");
        }
        
        Bill updated = billService.confirmCashPayment(id, ownerId);

        if ("CHECKOUT".equals(updated.getType())) {
            checkoutService.completeCheckoutAndFreeRoom(id);
            disputeChatController.broadcastPaymentSuccess(id);
        }

        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true).message("Đã xác nhận thu tiền mặt!")
                .data(updated).build());
    }

    /** Giả lập thanh toán chuyển khoản thành công */
    @PostMapping("/{id}/simulate-online-payment")
    public ResponseEntity<ApiResponse<Bill>> simulateOnlinePayment(@PathVariable Long id, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        verifyBillOwnership(userId, id, auth);
        
        // This is a simulation, ideally anyone can pay online via webhook, but let's assume it requires tenant or owner
        Bill updated = billService.confirmCashPayment(id, null);

        if ("CHECKOUT".equals(updated.getType())) {
            checkoutService.completeCheckoutAndFreeRoom(id);
            disputeChatController.broadcastPaymentSuccess(id);
        }

        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true).message("Đã thanh toán chuyển khoản thành công!")
                .data(updated).build());
    }

    /** AI Receipt Scanner (Giả lập) */
    @PostMapping("/{id}/scan-receipt")
    public ResponseEntity<ApiResponse<Bill>> scanReceipt(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        verifyBillOwnership(userId, id, auth);
        
        // Giả lập xử lý AI mất 1.5s
        try { Thread.sleep(1500); } catch (InterruptedException ignored) {}

        // Coi như OCR nhận diện thành công và chuyển trạng thái PAID
        Bill updated = billService.confirmCashPayment(id, null);
        
        if ("CHECKOUT".equals(updated.getType())) {
            checkoutService.completeCheckoutAndFreeRoom(id);
            disputeChatController.broadcastPaymentSuccess(id);
        }

        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true)
                .message("AI đã trích xuất: Số tiền khớp. Hóa đơn đã được gạch nợ!")
                .data(updated).build());
    }

    /** Áp dụng Voucher vào Bill */
    @PostMapping("/{id}/apply-voucher")
    public ResponseEntity<ApiResponse<Bill>> applyVoucher(
            @PathVariable Long id,
            @RequestBody ApplyVoucherRequest request,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        Long tenantId = (Long) auth.getPrincipal();
        
        String code = request.getCode();
        Bill bill = billRepository.findById(id).orElseThrow(() -> new RuntimeException("Bill not found"));
        
        if (!bill.getTenantId().equals(tenantId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Không thể áp dụng voucher cho hóa đơn của người khác");
        }
        if (bill.getVoucherId() != null) {
            throw new IllegalArgumentException("Hóa đơn này đã áp dụng voucher.");
        }
        
        com.stayhub.api.entity.Voucher voucher = voucherRepository.findByCodeAndIsActiveTrue(code)
                .orElseThrow(() -> new RuntimeException("Voucher không tồn tại hoặc đã hết hạn."));
                
        if (!voucher.isValidForNewUse()) {
            throw new IllegalArgumentException("Voucher không còn hiệu lực hoặc đã hết lượt sử dụng.");
        }

        double discount = bill.getTotalAmount() - voucher.computeDiscountedPrice(bill.getTotalAmount());
        
        bill.setVoucherId(voucher.getId());
        bill.setDiscountAmount(discount);
        bill.setTotalAmount(bill.getTotalAmount() - discount);
        
        voucher.setUsedCount(voucher.getUsedCount() + 1);
        voucherRepository.save(voucher);
        
        Bill updated = billRepository.save(bill);
        
        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true)
                .message("Áp dụng voucher thành công! Đã giảm " + discount + "đ")
                .data(updated).build());
    }

    /** Cập nhật chỉ số điện nước cho hóa đơn nháp */
    @PutMapping("/{id}/utilities")
    public ResponseEntity<ApiResponse<Bill>> updateUtilities(
            @PathVariable Long id,
            @RequestBody UpdateUtilitiesRequest request,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isStaff && !isOwner) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        
        Long userId = (Long) auth.getPrincipal();
        verifyBillOwnership(userId, id, auth);
        
        Double electricCurrent = request != null ? request.getElectricCurrent() : null;
        Double waterCurrent = request != null ? request.getWaterCurrent() : null;
        String electricImage = request != null ? request.getElectricImage() : null;
        String waterImage = request != null ? request.getWaterImage() : null;
        
        Bill updated = billService.updateUtilities(id, electricCurrent, waterCurrent, electricImage, waterImage);
        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true).message("Đã chốt số điện nước!")
                .data(updated).build());
    }

    /** Cập nhật chỉ số điện nước cho hóa đơn nháp theo phòng và tháng hiện tại */
    @PutMapping("/room/{roomId}/utilities")
    public ResponseEntity<ApiResponse<Bill>> updateUtilitiesByRoom(
            @PathVariable Long roomId,
            @RequestBody UpdateUtilitiesRequest request,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isStaff && !isOwner) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        
        Long userId = (Long) auth.getPrincipal();
        
        com.stayhub.api.entity.Room room = roomRepository.findById(roomId).orElseThrow(() -> new RuntimeException("Room not found"));
        verifyBranchOwnership(userId, room.getBranchId(), auth);
        
        Double electricCurrent = request != null ? request.getElectricCurrent() : null;
        Double waterCurrent = request != null ? request.getWaterCurrent() : null;
        String electricImage = request != null ? request.getElectricImage() : null;
        String waterImage = request != null ? request.getWaterImage() : null;
        
        java.time.LocalDate today = java.time.LocalDate.now();
        int month = today.getMonthValue();
        int year = today.getYear();
        
        Bill bill = billService.getByRoom(roomId).stream()
                .filter(b -> b.getMonth() == month && b.getYear() == year)
                .findFirst()
                .orElse(null);
                
        if (bill == null) {
            bill = billService.generateBillForRoom(roomId, month, year);
        }
        
        Bill updated = billService.updateUtilities(bill.getId(), electricCurrent, waterCurrent, electricImage, waterImage);
        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true).message("Đã chốt số điện nước!")
                .data(updated).build());
    }
    /** Lấy danh sách chốt số điện nước của một dãy trọ */
    @GetMapping("/branch/{branchId}/meter-readings")
    public ResponseEntity<ApiResponse<List<com.stayhub.api.dto.response.RoomMeterReadingDto>>> getMeterReadings(
            @PathVariable Long branchId,
            @RequestParam int month,
            @RequestParam int year,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isStaff && !isOwner) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        
        Long userId = (Long) auth.getPrincipal();
        verifyBranchOwnership(userId, branchId, auth);
        
        return ResponseEntity.ok(ApiResponse.<List<com.stayhub.api.dto.response.RoomMeterReadingDto>>builder()
                .success(true).message("Thành công!")
                .data(billService.getMeterReadingsByBranch(branchId, month, year)).build());
    }

    /** Tạo hóa đơn nháp hàng loạt cho một dãy trọ */
    @PostMapping("/branch/{branchId}/generate")
    public ResponseEntity<ApiResponse<List<Bill>>> generateBills(
            @PathVariable Long branchId,
            @RequestParam int month,
            @RequestParam int year,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED);
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        if (!isStaff && !isOwner) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN);
        
        Long userId = (Long) auth.getPrincipal();
        verifyBranchOwnership(userId, branchId, auth);
        
        List<Bill> generated = billService.generateBillsForBranch(branchId, month, year);
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true)
                .message("Đã tạo " + generated.size() + " hóa đơn nháp!")
                .data(generated)
                .build());
    }

    private void verifyBillOwnership(Long userId, Long billId, org.springframework.security.core.Authentication auth) {
        Bill bill = billRepository.findById(billId).orElseThrow(() -> new RuntimeException("Bill not found"));
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        if (isOwner) {
            com.stayhub.api.entity.Room room = roomRepository.findById(bill.getRoomId()).orElse(null);
            if (room == null || !room.getOwnerId().equals(userId)) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên hóa đơn này");
            }
        } else if (isStaff) {
            com.stayhub.api.entity.Room room = roomRepository.findById(bill.getRoomId()).orElse(null);
            if (room == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND);
            boolean hasAssignment = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId).stream()
                    .anyMatch(a -> a.getBranchId().equals(room.getBranchId()));
            if (!hasAssignment) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên hóa đơn này");
            }
        } else if (!bill.getTenantId().equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên hóa đơn này");
        }
    }

    private void verifyBranchOwnership(Long userId, Long branchId, org.springframework.security.core.Authentication auth) {
        boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        if (isOwner) {
            com.stayhub.api.entity.Branch branch = branchRepository.findById(branchId).orElse(null);
            if (branch == null || !branch.getOwnerId().equals(userId)) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên chi nhánh này");
            }
        } else if (isStaff) {
            boolean hasAssignment = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(userId).stream()
                    .anyMatch(a -> a.getBranchId().equals(branchId));
            if (!hasAssignment) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên chi nhánh này");
            }
        } else {
             throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
    }
}

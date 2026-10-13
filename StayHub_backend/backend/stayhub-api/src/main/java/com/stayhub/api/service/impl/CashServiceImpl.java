package com.stayhub.api.service.impl;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.CashSession;
import com.stayhub.api.entity.StaffWallet;
import com.stayhub.api.repository.CashSessionRepository;
import com.stayhub.api.repository.StaffWalletRepository;
import com.stayhub.api.service.CashService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
@Slf4j
public class CashServiceImpl implements CashService {

    private final CashSessionRepository cashSessionRepository;
    private final StaffWalletRepository staffWalletRepository;
    private final com.stayhub.api.repository.BillRepository billRepository;
    private final com.stayhub.api.service.BillService billService;
    private final com.stayhub.api.repository.UserRepository userRepository;
    
    // ownerId -> List of SseEmitters
    private final Map<Long, java.util.List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    @Override
    public SseEmitter createSseEmitter(Long ownerId) {
        SseEmitter emitter = new SseEmitter(10 * 60 * 1000L); com.stayhub.api.service.SseHeartbeatService.register(emitter); // 10 minutes timeout
        emitters.computeIfAbsent(ownerId, k -> new java.util.concurrent.CopyOnWriteArrayList<>()).add(emitter);

        Runnable cleanup = () -> {
            java.util.List<SseEmitter> list = emitters.get(ownerId);
            if (list != null) {
                list.remove(emitter);
                if (list.isEmpty()) {
                    emitters.remove(ownerId);
                }
            }
        };

        emitter.onCompletion(cleanup);
        emitter.onTimeout(cleanup);
        emitter.onError(e -> cleanup.run());

        try {
            emitter.send(SseEmitter.event().name("INIT").data("Connected"));
        } catch (IOException e) {
            cleanup.run();
        }

        return emitter;
    }

    private void dispatchEventToOwner(Long ownerId, String eventName, Object data) {
        java.util.List<SseEmitter> list = emitters.get(ownerId);
        if (list != null) {
            java.util.List<SseEmitter> deadEmitters = new java.util.ArrayList<>();
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name(eventName).data(data));
                } catch (IOException e) {
                    deadEmitters.add(emitter);
                }
            }
            if (!deadEmitters.isEmpty()) {
                list.removeAll(deadEmitters);
                if (list.isEmpty()) {
                    emitters.remove(ownerId);
                }
            }
        }
    }

    @Override
    @Transactional
    public ApiResponse<Map<String, String>> generateQr(Long userId, String sessionType, Long branchId) {
        CashSession session = CashSession.builder()
                .creatorUserId(userId)
                .sessionType(sessionType)
                .branchId(branchId)
                .expiresAt(LocalDateTime.now().plusMinutes(5)) // 5 phút hết hạn
                .build();
        
        cashSessionRepository.save(session);
        
        return ApiResponse.<Map<String, String>>builder()
                .success(true)
                .message("Generated QR successfully")
                .data(Map.of("sessionId", session.getSessionId()))
                .build();
    }

    @Override
    public ApiResponse<Map<String, Object>> previewScan(Long scannerUserId, String sessionId) {
        Optional<CashSession> sessionOpt = cashSessionRepository.findBySessionId(sessionId);
        if (sessionOpt.isEmpty()) {
            return ApiResponse.<Map<String, Object>>builder().success(false).message("Mã QR không tồn tại").build();
        }

        CashSession session = sessionOpt.get();
        if (session.getExpiresAt() != null && LocalDateTime.now().isAfter(session.getExpiresAt())) {
            return ApiResponse.<Map<String, Object>>builder().success(false).message("Mã QR đã hết hạn").build();
        }

        if (!session.getStatus().equals("PENDING")) {
            return ApiResponse.<Map<String, Object>>builder().success(false).message("Mã QR đã được quét hoặc không còn hợp lệ").build();
        }

        java.util.List<com.stayhub.api.entity.Bill> bills = new java.util.ArrayList<>();
        if ("OWNER_RECEIVE".equals(session.getSessionType()) || "TENANT_PAY_BILL".equals(session.getSessionType())) {
            bills = billRepository.findUnpaidByTenant(scannerUserId);
        } else if ("STAFF_HANDOVER_CASH".equals(session.getSessionType())) {
            bills = billRepository.findUnremittedByStaff(scannerUserId);
        }

        String creatorName = "Người dùng";
        String creatorRole = "Quản lý";
        Optional<com.stayhub.api.entity.User> creatorOpt = userRepository.findById(session.getCreatorUserId());
        if (creatorOpt.isPresent()) {
            com.stayhub.api.entity.User creator = creatorOpt.get();
            creatorName = creator.getName();
            creatorRole = "STAFF".equals(creator.getRoleId()) ? "Nhân viên" : ("OWNER".equals(creator.getRoleId()) ? "Chủ nhà" : "Người dùng");
        }

        return ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .data(Map.of(
                        "sessionType", session.getSessionType(),
                        "bills", bills,
                        "creatorName", creatorName,
                        "creatorRole", creatorRole
                ))
                .build();
    }

    @Override
    @Transactional
    public ApiResponse<Void> scanQr(Long scannerUserId, String sessionId, Double amount, java.util.List<Long> itemIds) {
        if (itemIds == null || itemIds.isEmpty()) {
            return ApiResponse.<Void>builder().success(false).message("Vui lòng chọn ít nhất 1 hóa đơn/khoản tiền").build();
        }

        Optional<CashSession> sessionOpt = cashSessionRepository.findBySessionIdWithLock(sessionId);
        if (sessionOpt.isEmpty()) {
            return ApiResponse.<Void>builder().success(false).message("Mã QR không tồn tại").build();
        }

        CashSession session = sessionOpt.get();
        if (session.getExpiresAt() != null && LocalDateTime.now().isAfter(session.getExpiresAt())) {
            session.setStatus("EXPIRED");
            cashSessionRepository.save(session);
            return ApiResponse.<Void>builder().success(false).message("Mã QR đã hết hạn").build();
        }

        if (!session.getStatus().equals("PENDING")) {
            return ApiResponse.<Void>builder().success(false).message("Mã QR đã được quét hoặc không còn hợp lệ").build();
        }

        java.util.List<Long> finalItemIds = itemIds;
        java.util.List<com.stayhub.api.entity.Bill> bills = billRepository.findAllById(finalItemIds);
        double calculatedAmount = 0.0;
        for (com.stayhub.api.entity.Bill bill : bills) {
            if ("OWNER_RECEIVE".equals(session.getSessionType()) || "TENANT_PAY_BILL".equals(session.getSessionType())) {
                if (!scannerUserId.equals(bill.getTenantId())) {
                    return ApiResponse.<Void>builder().success(false).message("Phát hiện hóa đơn không hợp lệ").build();
                }
                if (Boolean.TRUE.equals(bill.getIsPaid())) {
                    return ApiResponse.<Void>builder().success(false).message("Có hóa đơn đã được thanh toán").build();
                }
            } else if ("STAFF_HANDOVER_CASH".equals(session.getSessionType())) {
                if (!scannerUserId.equals(bill.getCollectedByStaffId())) {
                    return ApiResponse.<Void>builder().success(false).message("Phát hiện hóa đơn không hợp lệ").build();
                }
                if (Boolean.TRUE.equals(bill.getIsRemitted())) {
                    return ApiResponse.<Void>builder().success(false).message("Có hóa đơn đã được nộp").build();
                }
            }
            double billTotal = bill.getTotalAmount() != null ? bill.getTotalAmount() : 0.0;
            if (billTotal < 0) {
                return ApiResponse.<Void>builder().success(false).message("Không thể chọn hóa đơn có tổng tiền âm").build();
            }
            calculatedAmount += billTotal;
        }
        
        if (calculatedAmount <= 0) {
            return ApiResponse.<Void>builder().success(false).message("Tổng số tiền quét phải lớn hơn 0").build();
        }
        amount = calculatedAmount;

        session.setScannerUserId(scannerUserId);
        session.setAmount(amount);
        session.setItemIds(finalItemIds);
        session.setStatus("SCANNED");
        cashSessionRepository.save(session);

        String scannerName = "Người dùng";
        String scannerRole = "Khách thuê";
        Optional<com.stayhub.api.entity.User> scannerOpt = userRepository.findById(scannerUserId);
        if (scannerOpt.isPresent()) {
            com.stayhub.api.entity.User scanner = scannerOpt.get();
            scannerName = scanner.getName();
            scannerRole = "STAFF".equals(scanner.getRoleId()) ? "Nhân viên" : ("TENANT".equals(scanner.getRoleId()) ? "Khách thuê" : "Người dùng");
        }

        // Bắn SSE cho Owner (người tạo QR)
        Map<String, Object> eventData = Map.of(
            "sessionId", session.getSessionId(),
            "amount", amount,
            "scannerId", scannerUserId,
            "scannerName", scannerName,
            "scannerRole", scannerRole,
            "type", session.getSessionType(),
            "time", LocalDateTime.now().toString()
        );
        dispatchEventToOwner(session.getCreatorUserId(), "QR_SCANNED", eventData);

        return ApiResponse.<Void>builder()
                .success(true)
                .message("Đã gửi yêu cầu nhận tiền, chờ Chủ nhà duyệt")
                .build();
    }

    @Override
    @Transactional
    public ApiResponse<Void> confirmSession(Long userId, String sessionId) {
        Optional<CashSession> sessionOpt = cashSessionRepository.findBySessionIdWithLock(sessionId);
        if (sessionOpt.isEmpty()) {
            return ApiResponse.<Void>builder().success(false).message("Session not found").build();
        }

        CashSession session = sessionOpt.get();
        if (session.getExpiresAt() != null && LocalDateTime.now().isAfter(session.getExpiresAt())) {
            session.setStatus("EXPIRED");
            cashSessionRepository.save(session);
            return ApiResponse.<Void>builder().success(false).message("Mã QR đã hết hạn").build();
        }

        if (!session.getStatus().equals("SCANNED")) {
            return ApiResponse.<Void>builder().success(false).message("Chưa có ai quét mã QR này").build();
        }

        if (!session.getCreatorUserId().equals(userId)) {
            return ApiResponse.<Void>builder().success(false).message("Không có quyền duyệt").build();
        }

        // Logic to update staff wallet if session is STAFF_HANDOVER_CASH
        if ("STAFF_HANDOVER_CASH".equals(session.getSessionType())) {
            Optional<StaffWallet> walletOpt = staffWalletRepository.findByStaffId(session.getScannerUserId());
            if (walletOpt.isEmpty()) {
                return ApiResponse.<Void>builder().success(false).message("Không tìm thấy thông tin Ví tiền mặt của nhân viên").build();
            }
            
            StaffWallet wallet = walletOpt.get();
            wallet.setCashSpent(wallet.getCashSpent() + session.getAmount());
            staffWalletRepository.save(wallet);
            if (session.getItemIds() != null) {
                java.util.List<com.stayhub.api.entity.Bill> bills = billRepository.findAllById(session.getItemIds());
                for (com.stayhub.api.entity.Bill bill : bills) {
                    if (Boolean.TRUE.equals(bill.getIsRemitted())) {
                        return ApiResponse.<Void>builder().success(false).message("Có hóa đơn đã được nộp tiền trước đó").build();
                    }
                    bill.setIsRemitted(true);
                }
                billRepository.saveAll(bills);
            }
        } else if ("OWNER_RECEIVE".equals(session.getSessionType()) || "TENANT_PAY_BILL".equals(session.getSessionType())) {
            if (session.getItemIds() != null) {
                java.util.List<com.stayhub.api.entity.Bill> bills = billRepository.findAllById(session.getItemIds());
                com.stayhub.api.entity.User creator = userRepository.findById(session.getCreatorUserId()).orElse(null);
                boolean isStaff = creator != null && "STAFF".equals(creator.getRoleId());
                Optional<StaffWallet> staffWalletOpt = staffWalletRepository.findByStaffId(session.getCreatorUserId());

                if (isStaff && staffWalletOpt.isEmpty()) {
                    return ApiResponse.<Void>builder().success(false).message("Không tìm thấy thông tin Ví tiền mặt của nhân viên tạo QR").build();
                }

                for (com.stayhub.api.entity.Bill bill : bills) {
                    if (Boolean.TRUE.equals(bill.getIsPaid())) {
                        return ApiResponse.<Void>builder().success(false).message("Có hóa đơn đã được thanh toán bằng hình thức khác").build();
                    }
                    bill.setIsPaid(true);
                    bill.setPaidByCash(true);
                    bill.setStatus("PAID");
                    bill.setPaidAt(LocalDateTime.now());
                    
                    if (isStaff) {
                        bill.setCollectedByStaffId(session.getCreatorUserId());
                    }
                    
                    if (bill.getRoomId() != null) {
                        billService.checkAndFreeRoomIfNoUnpaidBills(bill.getRoomId());
                    }
                }
                billRepository.saveAll(bills);

                if (isStaff) {
                    StaffWallet wallet = staffWalletOpt.get();
                    wallet.setCashCollected(wallet.getCashCollected() + session.getAmount());
                    staffWalletRepository.save(wallet);
                }
            }
        }

        session.setStatus("COMPLETED");
        session.setCompletedAt(LocalDateTime.now());
        cashSessionRepository.save(session);

        return ApiResponse.<Void>builder()
                .success(true)
                .message("Đã duyệt thành công")
                .build();
    }

    @Override
    @Transactional
    public ApiResponse<Void> cancelSession(Long userId, String sessionId) {
        Optional<CashSession> sessionOpt = cashSessionRepository.findBySessionIdWithLock(sessionId);
        if (sessionOpt.isEmpty()) {
            return ApiResponse.<Void>builder().success(false).message("Session not found").build();
        }

        CashSession session = sessionOpt.get();
        if (!session.getCreatorUserId().equals(userId)) {
            return ApiResponse.<Void>builder().success(false).message("Không có quyền từ chối").build();
        }

        if (!session.getStatus().equals("SCANNED")) {
            return ApiResponse.<Void>builder().success(false).message("Giao dịch không ở trạng thái chờ duyệt").build();
        }

        session.setStatus("CANCELLED");
        cashSessionRepository.save(session);

        return ApiResponse.<Void>builder()
                .success(true)
                .message("Đã từ chối giao dịch")
                .build();
    }
}

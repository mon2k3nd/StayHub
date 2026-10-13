package com.stayhub.api.service;

import com.stayhub.api.entity.AddonService;
import com.stayhub.api.entity.TenantAddonRequest;
import com.stayhub.api.repository.AddonServiceRepository;
import com.stayhub.api.repository.TenantAddonRequestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class AddonServiceService {

    private final AddonServiceRepository addonRepository;
    private final TenantAddonRequestRepository requestRepository;
    private final com.stayhub.api.repository.RoomRepository roomRepository;
    private final NotificationService notificationService;

    // --- OWNER APIs ---
    
    public List<AddonService> getOwnerAddons(Long ownerId) {
        return addonRepository.findByOwnerIdAndIsActiveTrue(ownerId);
    }

    @Transactional
    public AddonService createAddon(Long ownerId, Map<String, Object> body) {
        String name = body.get("name").toString();
        Double price = Double.valueOf(body.get("price").toString());
        String description = body.containsKey("description") ? body.get("description").toString() : null;
        String iconUrl = body.containsKey("iconUrl") ? body.get("iconUrl").toString() : null;

        AddonService addon = AddonService.builder()
                .ownerId(ownerId)
                .name(name)
                .price(price)
                .description(description)
                .iconUrl(iconUrl)
                .build();
        return addonRepository.save(addon);
    }

    @Transactional
    public void deleteAddon(Long addonId) {
        AddonService addon = addonRepository.findById(addonId).orElseThrow(() -> new IllegalArgumentException("Không tìm thấy dịch vụ"));
        addon.setIsActive(false);
        addonRepository.save(addon);
    }

    // --- TENANT APIs ---

    public List<AddonService> getAvailableAddonsForRoom(Long roomId) {
        com.stayhub.api.entity.Room room = roomRepository.findById(roomId)
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phòng"));
        return addonRepository.findByOwnerIdAndIsActiveTrue(room.getOwnerId());
    }

    @Transactional
    public TenantAddonRequest orderAddon(Long tenantId, Long roomId, Map<String, Object> body) {
        Long addonId = Long.valueOf(body.get("addonId").toString());
        Integer quantity = Integer.valueOf(body.getOrDefault("quantity", 1).toString());
        
        // Xác định tháng/năm hiện tại để gán vào hóa đơn tháng tới
        java.time.LocalDate now = java.time.LocalDate.now();
        int targetMonth = now.getMonthValue();
        int targetYear = now.getYear();

        AddonService addon = addonRepository.findById(addonId).orElseThrow(() -> new IllegalArgumentException("Không tìm thấy dịch vụ"));
        if (!addon.getIsActive()) {
            throw new IllegalStateException("Dịch vụ này đã ngừng cung cấp");
        }

        TenantAddonRequest request = TenantAddonRequest.builder()
                .tenantId(tenantId)
                .roomId(roomId)
                .addonService(addon)
                .quantity(quantity)
                .billMonth(targetMonth)
                .billYear(targetYear)
                .build();

        TenantAddonRequest saved = requestRepository.save(request);

        try {
            notificationService.send(
                    tenantId,
                    addon.getOwnerId(),
                    com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    "Yêu cầu dịch vụ mới",
                    "Khách thuê vừa đăng ký thêm dịch vụ: " + addon.getName() + " (SL: " + quantity + ").",
                    com.stayhub.api.entity.NotificationType.GENERAL,
                    saved.getId(),
                    false,
                    null,
                    null
            );
        } catch (Exception e) {
            log.warn("Failed to send addon order notification: {}", e.getMessage());
        }

        return saved;
    }

    public List<TenantAddonRequest> getTenantRequests(Long tenantId) {
        return requestRepository.findByTenantId(tenantId);
    }

    // --- OWNER / STAFF APPROVAL APIs ---

    public List<TenantAddonRequest> getRoomRequests(Long roomId, String status) {
        return requestRepository.findByRoomIdAndStatus(roomId, status);
    }

    @Transactional
    public TenantAddonRequest respondToRequest(Long requestId, boolean approved, String note) {
        TenantAddonRequest req = requestRepository.findById(requestId).orElseThrow(() -> new IllegalArgumentException("Không tìm thấy yêu cầu"));
        
        if (!"PENDING".equals(req.getStatus())) {
            throw new IllegalStateException("Yêu cầu này đã được xử lý");
        }

        req.setStatus(approved ? "APPROVED" : "REJECTED");
        req.setStatusNote(note);
        req.setResolvedAt(java.time.LocalDateTime.now());

        TenantAddonRequest saved = requestRepository.save(req);

        try {
            notificationService.send(
                    req.getAddonService().getOwnerId(),
                    req.getTenantId(),
                    com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    approved ? "Dịch vụ được chấp nhận" : "Dịch vụ bị từ chối",
                    "Yêu cầu dịch vụ " + req.getAddonService().getName() + " của bạn đã bị " + (approved ? "chấp nhận" : "từ chối") + ". " + (note != null ? "Ghi chú: " + note : ""),
                    com.stayhub.api.entity.NotificationType.GENERAL,
                    saved.getId(),
                    false,
                    null,
                    null
            );
        } catch (Exception e) {
            log.warn("Failed to send addon response notification: {}", e.getMessage());
        }

        return saved;
    }
}

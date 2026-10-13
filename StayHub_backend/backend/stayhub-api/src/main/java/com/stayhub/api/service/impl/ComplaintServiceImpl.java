package com.stayhub.api.service.impl;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.request.ComplaintRequest;
import com.stayhub.api.dto.request.ComplaintStatusUpdateRequest;
import com.stayhub.api.dto.response.ComplaintResponse;
import com.stayhub.api.entity.Complaint;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.Room;
import com.stayhub.api.repository.ComplaintRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.service.ComplaintService;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class ComplaintServiceImpl implements ComplaintService {

    private final ComplaintRepository complaintRepository;
    private final UserRepository userRepository;
    private final RoomRepository roomRepository;
    private final NotificationService notificationService;

    // branchId -> List of SseEmitters for Owners/Managers
    private final Map<Long, List<SseEmitter>> branchEmitters = new ConcurrentHashMap<>();
    
    // tenantId -> List of SseEmitters for Tenants
    private final Map<Long, List<SseEmitter>> tenantEmitters = new ConcurrentHashMap<>();

    public SseEmitter registerBranchEmitter(Long branchId) {
        SseEmitter emitter = new SseEmitter(60 * 60 * 1000L); com.stayhub.api.service.SseHeartbeatService.register(emitter); // 1h
        branchEmitters.computeIfAbsent(branchId, k -> new CopyOnWriteArrayList<>()).add(emitter);
        emitter.onCompletion(() -> removeBranchEmitter(branchId, emitter));
        emitter.onTimeout(() -> removeBranchEmitter(branchId, emitter));
        emitter.onError((e) -> removeBranchEmitter(branchId, emitter));
        try {
            emitter.send(SseEmitter.event().name("INIT").data("Connected to branch " + branchId));
        } catch (Exception ignored) { log.warn("Ignored exception in ComplaintServiceImpl: ", ignored); }
        return emitter;
    }

    private void removeBranchEmitter(Long branchId, SseEmitter emitter) {
        List<SseEmitter> list = branchEmitters.get(branchId);
        if (list != null) {
            list.remove(emitter);
            if (list.isEmpty()) {
                branchEmitters.remove(branchId);
            }
        }
    }

    public SseEmitter registerTenantEmitter(Long tenantId) {
        SseEmitter emitter = new SseEmitter(60 * 60 * 1000L); com.stayhub.api.service.SseHeartbeatService.register(emitter);
        tenantEmitters.computeIfAbsent(tenantId, k -> new CopyOnWriteArrayList<>()).add(emitter);
        emitter.onCompletion(() -> removeTenantEmitter(tenantId, emitter));
        emitter.onTimeout(() -> removeTenantEmitter(tenantId, emitter));
        emitter.onError((e) -> removeTenantEmitter(tenantId, emitter));
        try {
            emitter.send(SseEmitter.event().name("INIT").data("Connected to tenant " + tenantId));
        } catch (Exception ignored) { log.warn("Ignored exception in ComplaintServiceImpl: ", ignored); }
        return emitter;
    }

    private void removeTenantEmitter(Long tenantId, SseEmitter emitter) {
        List<SseEmitter> list = tenantEmitters.get(tenantId);
        if (list != null) {
            list.remove(emitter);
            if (list.isEmpty()) {
                tenantEmitters.remove(tenantId);
            }
        }
    }

    private void notifyBranch(Long branchId, String eventName, Object data) {
        List<SseEmitter> list = branchEmitters.get(branchId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name(eventName).data(data));
                } catch (Exception e) {
                    removeBranchEmitter(branchId, emitter);
                }
            }
        }
    }

    private void notifyTenant(Long tenantId, String eventName, Object data) {
        List<SseEmitter> list = tenantEmitters.get(tenantId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name(eventName).data(data));
                } catch (Exception e) {
                    removeTenantEmitter(tenantId, emitter);
                }
            }
        }
    }

    @Override
    public ApiResponse<ComplaintResponse> createComplaint(Long tenantId, ComplaintRequest request) {
        Complaint complaint = Complaint.builder()
                .tenantId(tenantId)
                .branchId(request.getBranchId())
                .roomId(request.getRoomId())
                .category(request.getCategory())
                .priority(request.getPriority() != null ? request.getPriority() : "MEDIUM")
                .title(request.getTitle())
                .description(request.getDescription())
                .imagesJson(request.getImages() != null ? String.join(",", request.getImages()) : null)
                .status("PENDING")
                .build();
        
        complaint = complaintRepository.save(complaint);
        ComplaintResponse response = mapToResponse(complaint);

        // Notify branch owner/manager
        notifyBranch(request.getBranchId(), "NEW_COMPLAINT", response);
        try {
            notificationService.broadcastToBranch(
                    null, // we don't have ownerId easily here without a query, broadcastToBranch will fetch owner/managers
                    request.getBranchId(),
                    "Phản ánh mới",
                    "Bạn có phản ánh mới từ khách thuê: " + request.getTitle()
            );
        } catch (Exception e) {
            log.warn("Failed to send complaint notification: {}", e.getMessage());
        }

        return ApiResponse.<ComplaintResponse>builder().success(true).data(response).message("Gửi phản ánh thành công").build();
    }

    @Override
    public ApiResponse<List<ComplaintResponse>> getComplaintsByBranch(Long branchId, String status) {
        List<Complaint> complaints;
        if (status != null && !status.isEmpty()) {
            complaints = complaintRepository.findByBranchIdAndStatusOrderByCreatedAtDesc(branchId, status);
        } else {
            complaints = complaintRepository.findByBranchIdOrderByCreatedAtDesc(branchId);
        }
        List<ComplaintResponse> responses = complaints.stream().map(this::mapToResponse).collect(Collectors.toList());
        return ApiResponse.<List<ComplaintResponse>>builder().success(true).data(responses).build();
    }

    @Override
    public ApiResponse<List<ComplaintResponse>> getComplaintsByTenant(Long tenantId) {
        List<Complaint> complaints = complaintRepository.findByTenantIdOrderByCreatedAtDesc(tenantId);
        List<ComplaintResponse> responses = complaints.stream().map(this::mapToResponse).collect(Collectors.toList());
        return ApiResponse.<List<ComplaintResponse>>builder().success(true).data(responses).build();
    }

    @Override
    public ApiResponse<ComplaintResponse> updateComplaintStatus(Long complaintId, Long adminId, ComplaintStatusUpdateRequest request) {
        Complaint complaint = complaintRepository.findById(complaintId).orElse(null);
        if (complaint == null) {
            return ApiResponse.<ComplaintResponse>builder().success(false).message("Không tìm thấy phản ánh").build();
        }

        complaint.setStatus(request.getStatus());
        if (request.getAdminNote() != null) {
            complaint.setAdminNote(request.getAdminNote());
        }
        
        complaint = complaintRepository.save(complaint);
        ComplaintResponse response = mapToResponse(complaint);

        // Notify tenant about status change
        notifyTenant(complaint.getTenantId(), "COMPLAINT_UPDATED", response);
        try {
            notificationService.send(
                    adminId,
                    complaint.getTenantId(),
                    com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    "Cập nhật khiếu nại/phản ánh",
                    "Phản ánh của bạn đã được chuyển sang trạng thái: " + request.getStatus(),
                    com.stayhub.api.entity.NotificationType.GENERAL,
                    complaint.getId(),
                    false,
                    null,
                    null
            );
        } catch (Exception e) {
            log.warn("Failed to send complaint status notification: {}", e.getMessage());
        }

        return ApiResponse.<ComplaintResponse>builder().success(true).data(response).message("Cập nhật trạng thái thành công").build();
    }

    private ComplaintResponse mapToResponse(Complaint c) {
        User tenant = userRepository.findById(c.getTenantId()).orElse(null);
        String roomName = null;
        if (c.getRoomId() != null) {
            Room room = roomRepository.findById(c.getRoomId()).orElse(null);
            if (room != null) roomName = room.getRoomName();
        }

        return ComplaintResponse.builder()
                .id(c.getId())
                .tenantId(c.getTenantId())
                .tenantName(tenant != null ? tenant.getName() : "Unknown")
                .tenantPhone(tenant != null ? tenant.getPhoneNumber() : "Unknown")
                .branchId(c.getBranchId())
                .roomId(c.getRoomId())
                .roomName(roomName)
                .category(c.getCategory())
                .priority(c.getPriority())
                .title(c.getTitle())
                .description(c.getDescription())
                .images(c.getImagesJson() != null && !c.getImagesJson().isEmpty() ? List.of(c.getImagesJson().split(",")) : new ArrayList<>())
                .status(c.getStatus())
                .adminNote(c.getAdminNote())
                .createdAt(c.getCreatedAt())
                .updatedAt(c.getUpdatedAt())
                .build();
    }
}

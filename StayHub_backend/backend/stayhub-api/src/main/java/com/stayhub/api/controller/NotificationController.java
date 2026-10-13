package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Notification;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final com.stayhub.api.repository.NotificationRepository notificationRepository;

    @GetMapping("/stream/{userId}")
    public org.springframework.web.servlet.mvc.method.annotation.SseEmitter streamUnreadCount(
            @PathVariable Long userId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return null;
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId)) return null; // Chỉ stream của chính mình
        return notificationService.registerEmitter(userId);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<Notification>>> getByUser(
            @PathVariable Long userId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.error("Không có quyền xem thông báo của người khác"));
        return ResponseEntity.ok(ApiResponse.<List<Notification>>builder()
                .success(true).message("Thành công!").data(notificationService.getByUser(userId)).build());
    }

    @GetMapping("/user/{userId}/sent")
    public ResponseEntity<ApiResponse<List<Notification>>> getSentByUser(
            @PathVariable Long userId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.error("Không có quyền"));
        return ResponseEntity.ok(ApiResponse.<List<Notification>>builder()
                .success(true).message("Thành công!").data(notificationService.getSentByUser(userId)).build());
    }

    @GetMapping("/user/{userId}/unread-count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount(
            @PathVariable Long userId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.error("Không có quyền"));
        return ResponseEntity.ok(ApiResponse.<Long>builder()
                .success(true).message("Thành công!").data(notificationService.countUnread(userId)).build());
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markRead(
            @PathVariable Long id, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        notificationService.markRead(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã đọc!").build());
    }

    @PostMapping("/user/{userId}/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllRead(
            @PathVariable Long userId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.error("Không có quyền"));
        notificationService.markAllRead(userId);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã đọc tất cả!").build());
    }

    @PostMapping("/owner-broadcast")
    public ResponseEntity<ApiResponse<Void>> ownerBroadcast(
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        Long caller = (Long) auth.getPrincipal();
        // Lấy ownerId từ token thay vì từ body (tránh giả mạo ownerId)
        Long branchId = Long.valueOf(body.get("branchId").toString());
        String title = body.get("title").toString();
        String content = body.get("content").toString();
        notificationService.broadcastToBranch(caller, branchId, title, content);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã gửi broadcast thành công!").build());
    }

    @PutMapping("/{id}/action-status")
    public ResponseEntity<ApiResponse<Void>> updateActionStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        }
        Long caller = (Long) auth.getPrincipal();
        com.stayhub.api.entity.Notification notification = notificationRepository.findById(id).orElse(null);
        if (notification == null) return ResponseEntity.status(404).body(ApiResponse.error("Không tìm thấy thông báo"));
        if (!notification.getReceiverId().equals(caller)) {
             return ResponseEntity.status(403).body(ApiResponse.error("Không có quyền"));
        }
        com.stayhub.api.entity.NotificationActionStatus status = com.stayhub.api.entity.NotificationActionStatus.valueOf(body.get("status").toString());
        notificationService.updateActionStatus(id, status);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Cập nhật trạng thái Action thành công!").build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteNotification(
            @PathVariable Long id,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("Yêu cầu xác thực"));
        }
        Long caller = (Long) auth.getPrincipal();
        com.stayhub.api.entity.Notification notification = notificationRepository.findById(id).orElse(null);
        if (notification == null) return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã xóa thông báo!").build());
        if (!notification.getReceiverId().equals(caller)) {
             return ResponseEntity.status(403).body(ApiResponse.error("Không có quyền"));
        }
        notificationService.deleteNotification(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã xóa thông báo!").build());
    }

    // Endpoint /mock đã được xóa vì lý do bảo mật
    // (Không được để endpoint debug mở public trong môi trường production)
}

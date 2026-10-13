package com.stayhub.api.service;

import com.stayhub.api.entity.Notification;
import com.stayhub.api.entity.NotificationType;
import com.stayhub.api.entity.NotificationScope;
import com.stayhub.api.entity.NotificationActionStatus;
import java.util.List;

public interface NotificationService {
    List<Notification> getByUser(Long receiverId);
    List<Notification> getSentByUser(Long senderId);
    long countUnread(Long receiverId);
    void markRead(Long notificationId);
    void markAllRead(Long receiverId);
    void deleteNotification(Long notificationId);
    
    void send(Long senderId, Long receiverId, NotificationScope scope, String title, String content, NotificationType type, Long refId, Boolean isActionable, NotificationActionStatus actionStatus, String actionMetadata);
    
    void broadcastToBranch(Long ownerId, Long branchId, String title, String content);
    void broadcastGlobal(Long adminId, NotificationScope scope, String title, String content);
    void updateActionStatus(Long notificationId, NotificationActionStatus status);
    org.springframework.web.servlet.mvc.method.annotation.SseEmitter registerEmitter(Long userId);
}

package com.stayhub.api.service.impl;

import com.stayhub.api.entity.*;
import com.stayhub.api.repository.NotificationRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Async;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;
    private final RoomRepository roomRepository;
    private final ContractRepository contractRepository;
    private final UserRepository userRepository;
    private final com.stayhub.api.service.PushNotificationService pushNotificationService;
    private final com.stayhub.api.repository.RoommateRepository roommateRepository;

    private final Map<Long, List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    @Override
    public List<Notification> getByUser(Long receiverId) {
        return notificationRepository.findByReceiverIdAndIsDeletedFalseOrderByCreatedAtDesc(receiverId);
    }

    @Override
    public List<Notification> getSentByUser(Long senderId) {
        return notificationRepository.findBySenderIdAndIsDeletedFalseOrderByCreatedAtDesc(senderId);
    }

    @Override
    public long countUnread(Long receiverId) {
        return notificationRepository.countUnreadNotifications(receiverId);
    }

    @Override
    public void markRead(Long notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setIsRead(true);
            notificationRepository.save(n);
        });
    }

    @Override
    public void markAllRead(Long receiverId) {
        List<Notification> unread = notificationRepository.findByReceiverIdAndIsReadFalseAndIsDeletedFalse(receiverId);
        unread.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(unread);
    }

    @Override
    public void deleteNotification(Long notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setIsDeleted(true);
            notificationRepository.save(n);
        });
    }

    @Override
    public void send(Long senderId, Long receiverId, NotificationScope scope, String title, String content, NotificationType type, Long refId, Boolean isActionable, NotificationActionStatus actionStatus, String actionMetadata) {
        Notification notification = Notification.builder()
                .senderId(senderId)
                .receiverId(receiverId)
                .scope(scope)
                .title(title)
                .content(content)
                .type(type)
                .refId(refId)
                .isActionable(isActionable)
                .actionStatus(actionStatus)
                .actionMetadata(actionMetadata)
                .isRead(false)
                .build();
        notificationRepository.save(notification);
        
        // Notify via SSE
        List<SseEmitter> userEmitters = emitters.get(receiverId);
        if (userEmitters != null) {
            long unreadCount = countUnread(receiverId);
            userEmitters.removeIf(emitter -> {
                try {
                    emitter.send(SseEmitter.event().name("unread-count").data(String.valueOf(unreadCount)));
                    return false;
                } catch (Exception e) {
                    return true; // Remove emitter on error
                }
            });
        }
        // FCM push
        userRepository.findById(receiverId).ifPresent(receiver -> {
            if (receiver.getFcmToken() != null && !receiver.getFcmToken().isBlank()) {
                pushNotificationService.sendToDevice(
                        receiver.getFcmToken(),
                        title,
                        content,
                        Map.of("type", type.name(), "refId", refId != null ? String.valueOf(refId) : "")
                );
            }
        });
    }

    @Async
    @Override
    public void broadcastToBranch(Long ownerId, Long branchId, String title, String content) {
        List<Room> rooms = roomRepository.findByBranchId(branchId);
        for (Room room : rooms) {
            contractRepository.findByRoomIdAndStatus(room.getId(), ContractStatus.ACTIVE)
                    .forEach(contract -> {
                        // Send to main tenant
                        send(ownerId, contract.getTenantId(), NotificationScope.BRANCH, title, content, NotificationType.SYSTEM_ALERT, branchId, false, null, null);
                        
                        // Send to roommates
                        roommateRepository.findByContractIdAndIsActiveTrue(contract.getId()).forEach(roommate -> {
                            if (roommate.getUserId() != null) {
                                send(ownerId, roommate.getUserId(), NotificationScope.BRANCH, title, content, NotificationType.SYSTEM_ALERT, branchId, false, null, null);
                            }
                        });
                    });
        }
    }

    @Async
    @Override
    public void broadcastGlobal(Long adminId, NotificationScope scope, String title, String content) {
        if (scope == NotificationScope.GLOBAL) {
            userRepository.findAll().forEach(user -> {
                send(adminId, user.getId(), NotificationScope.GLOBAL, title, content, NotificationType.SYSTEM_ALERT, null, false, null, null);
            });
        } else if (scope == NotificationScope.OWNER_ALL) {
            userRepository.findByRoleId("OWNER").forEach(user -> {
                send(adminId, user.getId(), NotificationScope.OWNER_ALL, title, content, NotificationType.SYSTEM_ALERT, null, false, null, null);
            });
        }
    }

    @Override
    public void updateActionStatus(Long notificationId, NotificationActionStatus status) {
        Notification n = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));
        if (n.getActionStatus() != NotificationActionStatus.PENDING) {
            throw new RuntimeException("Action already taken or not actionable.");
        }
        n.setActionStatus(status);
        n.setIsActionable(false);
        n.setIsRead(true);
        notificationRepository.save(n);
    }

    @Override
    public SseEmitter registerEmitter(Long userId) {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); com.stayhub.api.service.SseHeartbeatService.register(emitter);
        emitters.computeIfAbsent(userId, k -> new java.util.concurrent.CopyOnWriteArrayList<>()).add(emitter);

        emitter.onCompletion(() -> removeEmitter(userId, emitter));
        emitter.onTimeout(() -> removeEmitter(userId, emitter));
        emitter.onError(e -> removeEmitter(userId, emitter));

        try {
            long unreadCount = countUnread(userId);
            emitter.send(SseEmitter.event().name("unread-count").data(String.valueOf(unreadCount)));
        } catch (Exception e) {
            removeEmitter(userId, emitter);
        }

        return emitter;
    }

    private void removeEmitter(Long userId, SseEmitter emitter) {
        List<SseEmitter> list = emitters.get(userId);
        if (list != null) {
            list.remove(emitter);
        }
    }
}

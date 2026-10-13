package com.stayhub.api.controller;

import com.stayhub.api.entity.DirectMessage;
import com.stayhub.api.repository.DirectMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@RestController
@RequestMapping("/v1/messages")
@RequiredArgsConstructor
public class V1DirectMessageController {

    private final DirectMessageRepository directMessageRepository;
    private final Map<Long, List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    @GetMapping("/{roomId}")
    public List<DirectMessage> getHistory(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        verifyRoomAccess(roomId, auth);
        return directMessageRepository.findByRoomIdOrderByCreatedAtAsc(roomId);
    }

    @GetMapping(value = "/stream/{roomId}", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribe(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        verifyRoomAccess(roomId, auth);
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); com.stayhub.api.service.SseHeartbeatService.register(emitter);
        emitters.computeIfAbsent(roomId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        emitter.onCompletion(() -> removeEmitter(roomId, emitter));
        emitter.onTimeout(() -> removeEmitter(roomId, emitter));
        emitter.onError((e) -> removeEmitter(roomId, emitter));

        try {
            emitter.send(SseEmitter.event().name("CONNECT").data("Connected to chat " + roomId));
        } catch (IOException e) {
            removeEmitter(roomId, emitter);
        }

        return emitter;
    }

    private void removeEmitter(Long roomId, SseEmitter emitter) {
        List<SseEmitter> list = emitters.get(roomId);
        if (list != null) {
            list.remove(emitter);
        }
    }

    @org.springframework.beans.factory.annotation.Autowired
    private com.stayhub.api.repository.RoomRepository roomRepository;

    @org.springframework.beans.factory.annotation.Autowired
    private com.stayhub.api.repository.ContractRepository contractRepository;

    @org.springframework.beans.factory.annotation.Autowired
    private com.stayhub.api.repository.UserRepository userRepository;

    @org.springframework.beans.factory.annotation.Autowired
    private com.stayhub.api.service.PushNotificationService pushNotificationService;

    @PostMapping("/{roomId}")
    public DirectMessage sendMessage(@PathVariable Long roomId, @RequestBody Map<String, String> payload, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        verifyRoomAccess(roomId, auth);
        Long senderId = (Long) auth.getPrincipal(); // FORCE SENDER ID FROM TOKEN

        String content = payload.get("message");
        String senderName = payload.get("senderName");
        String messageType = payload.getOrDefault("messageType", "TEXT");
        String metadata = payload.get("metadata");

        DirectMessage msg = DirectMessage.builder()
                .roomId(roomId)
                .senderId(senderId)
                .senderName(senderName)
                .content(content)
                .messageType(messageType)
                .metadata(metadata)
                .createdAt(LocalDateTime.now())
                .build();
        
        DirectMessage savedMsg = directMessageRepository.save(msg);

        // Gửi Push Notification
        com.stayhub.api.entity.Room room = roomRepository.findById(roomId).orElse(null);
        if (room != null) {
            Long receiverId = null;
            if (senderId.equals(room.getOwnerId())) {
                // Chủ nhà nhắn -> Người nhận là khách thuê
                com.stayhub.api.entity.Contract activeContract = contractRepository.findByRoomIdAndStatus(roomId, com.stayhub.api.entity.ContractStatus.ACTIVE).stream().findFirst().orElse(null);
                if (activeContract != null) {
                    receiverId = activeContract.getTenantId();
                }
            } else {
                // Khách thuê nhắn -> Người nhận là chủ nhà
                receiverId = room.getOwnerId();
            }
            if (receiverId != null) {
                com.stayhub.api.entity.User receiver = userRepository.findById(receiverId).orElse(null);
                if (receiver != null && receiver.getFcmToken() != null && !receiver.getFcmToken().isBlank()) {
                    String preview = content != null && content.length() > 100 ? content.substring(0, 100) + "..." : content;
                    pushNotificationService.sendToDevice(
                            receiver.getFcmToken(),
                            (senderName != null ? senderName : "Ai đó") + " (Tin nhắn phòng)",
                            preview,
                            Map.of("type", "direct_chat", "roomId", String.valueOf(roomId))
                    );
                }
            }
        }

        // Broadcast
        List<SseEmitter> list = emitters.get(roomId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("MESSAGE").data(Map.of(
                            "senderId", String.valueOf(senderId),
                            "senderName", senderName != null ? senderName : "",
                            "message", content,
                            "messageType", messageType,
                            "metadata", metadata != null ? metadata : ""
                    )));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(roomId, emitter);
                }
            }
        }

        return savedMsg;
    }

    public void broadcastSystemMessage(DirectMessage msg) {
        List<SseEmitter> list = emitters.get(msg.getRoomId());
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("MESSAGE").data(Map.of(
                            "senderId", String.valueOf(msg.getSenderId()),
                            "senderName", msg.getSenderName() != null ? msg.getSenderName() : "System",
                            "message", msg.getContent(),
                            "messageType", msg.getMessageType(),
                            "metadata", msg.getMetadata() != null ? msg.getMetadata() : ""
                    )));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(msg.getRoomId(), emitter);
                }
            }
        }
    }
    
    private void verifyRoomAccess(Long roomId, org.springframework.security.core.Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        com.stayhub.api.entity.Room room = roomRepository.findById(roomId).orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));
        
        com.stayhub.api.entity.Contract activeContract = contractRepository.findByRoomIdAndStatus(roomId, com.stayhub.api.entity.ContractStatus.ACTIVE).stream().findFirst().orElse(null);
        if (activeContract != null && activeContract.getTenantId().equals(userId)) {
            return; // Tenant OK
        }
        
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
            if (assignments.stream().anyMatch(a -> a.getBranchId().equals(room.getBranchId()))) {
                return; // Staff OK
            }
        } else if (room.getOwnerId().equals(userId)) {
            return; // Owner OK
        }
        
        throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền chat trong phòng này");
    }
}

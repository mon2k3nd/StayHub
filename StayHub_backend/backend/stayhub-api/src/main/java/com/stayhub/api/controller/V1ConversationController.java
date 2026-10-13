package com.stayhub.api.controller;

import com.stayhub.api.entity.MessageThread;
import com.stayhub.api.entity.ThreadMessage;
import com.stayhub.api.repository.MessageThreadRepository;
import com.stayhub.api.repository.ThreadMessageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/v1/conversations")
public class V1ConversationController {

    @Autowired
    private MessageThreadRepository threadRepository;

    @Autowired
    private ThreadMessageRepository messageRepository;

    @Autowired
    private com.stayhub.api.repository.UserRepository userRepository;

    @Autowired
    private com.stayhub.api.service.PushNotificationService pushNotificationService;

    private final Map<Long, Map<Long, SseEmitter>> emitters = new ConcurrentHashMap<>();

    @PostMapping
    public MessageThread createOrGetThread(@RequestBody Map<String, Object> payload, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long authUserId = (Long) auth.getPrincipal();
        Long userId1 = Long.valueOf(payload.get("userId1").toString());
        Long userId2 = Long.valueOf(payload.get("userId2").toString());
        
        if (!authUserId.equals(userId1) && !authUserId.equals(userId2)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không thể tạo thread cho người khác");
        }
        
        String type = payload.getOrDefault("threadType", "INQUIRY").toString();
        
        // BUGFIX: tìm cả hai chiều (A,B) và (B,A) để tránh tạo thread trùng
        // khi 2 người dùng đảo vai trò người khởi tạo.
        List<MessageThread> existing = threadRepository.findByUserPair(userId1, userId2);
        if (existing.isEmpty()) {
            existing = threadRepository.findByUserPair(userId2, userId1);
        }
        for (MessageThread t : existing) {
            if (t.getThreadType().equals(type)) {
                return t;
            }
        }
        
        MessageThread thread = MessageThread.builder()
                .userId1(userId1)
                .userId2(userId2)
                .threadType(type)
                .build();
        return threadRepository.save(thread);
    }

    @GetMapping("/user/{userId}")
    public List<MessageThread> getUserThreads(@PathVariable Long userId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền xem tin nhắn của người khác");
        }
        return threadRepository.findByUserId(userId);
    }

    @GetMapping("/{threadId}/messages")
    public List<ThreadMessage> getMessages(@PathVariable Long threadId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long authUserId = (Long) auth.getPrincipal();
        MessageThread thread = threadRepository.findById(threadId).orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));
        if (!authUserId.equals(thread.getUserId1()) && !authUserId.equals(thread.getUserId2())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        return messageRepository.findByThreadIdOrderByCreatedAtAsc(threadId);
    }

    @PutMapping("/{threadId}/read")
    public void markAsRead(@PathVariable Long threadId, @RequestParam Long userId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        MessageThread thread = threadRepository.findById(threadId).orElse(null);
        if (thread != null) {
            if (userId.equals(thread.getUserId1())) {
                thread.setUser1LastRead(LocalDateTime.now());
            } else if (userId.equals(thread.getUserId2())) {
                thread.setUser2LastRead(LocalDateTime.now());
            }
            threadRepository.save(thread);
        }
    }

    @PostMapping("/{threadId}/messages")
    public ThreadMessage sendMessage(@PathVariable Long threadId, @RequestBody Map<String, String> payload, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long senderId = (Long) auth.getPrincipal(); // FORCE SENDER ID FROM TOKEN
        
        MessageThread existingThread = threadRepository.findById(threadId).orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));
        if (!senderId.equals(existingThread.getUserId1()) && !senderId.equals(existingThread.getUserId2())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không thuộc hội thoại này");
        }
        
        String content = payload.get("message");
        String senderName = payload.get("senderName");
        String messageType = payload.getOrDefault("messageType", "TEXT");
        String metadata = payload.get("metadata");

        ThreadMessage msg = ThreadMessage.builder()
                .threadId(threadId)
                .senderId(senderId)
                .senderName(senderName)
                .content(content)
                .messageType(messageType)
                .metadata(metadata)
                .build();
        msg = messageRepository.save(msg);

        // Update thread updatedAt + last message preview
        MessageThread thread = threadRepository.findById(threadId).orElse(null);
        if (thread != null) {
            thread.setUpdatedAt(LocalDateTime.now());
            // Truncate preview to 100 chars
            String preview = content != null && content.length() > 100 ? content.substring(0, 100) + "..." : content;
            thread.setLastMessageContent(preview);
            thread.setLastSenderId(senderId);
            thread.setLastSenderName(senderName);
            threadRepository.save(thread);

            // Gửi Push Notification cho người nhận
            Long receiverId = senderId.equals(thread.getUserId1()) ? thread.getUserId2() : thread.getUserId1();
            com.stayhub.api.entity.User receiver = userRepository.findById(receiverId).orElse(null);
            if (receiver != null && receiver.getFcmToken() != null && !receiver.getFcmToken().isBlank()) {
                pushNotificationService.sendToDevice(
                        receiver.getFcmToken(),
                        senderName + " (Tin nhắn mới)",
                        preview,
                        Map.of("type", "chat", "threadId", String.valueOf(threadId))
                );
            }
        }

        // Broadcast
        Map<Long, SseEmitter> threadEmitters = emitters.get(threadId);
        if (threadEmitters != null) {
            List<Long> deadEmitters = new java.util.ArrayList<>();
            for (Map.Entry<Long, SseEmitter> entry : threadEmitters.entrySet()) {
                try {
                    entry.getValue().send(SseEmitter.event().name("MESSAGE").data(msg));
                } catch (IOException e) {
                    deadEmitters.add(entry.getKey());
                }
            }
            for (Long id : deadEmitters) {
                threadEmitters.remove(id);
            }
        }

        return msg;
    }

    @GetMapping(path = "/{threadId}/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamMessages(@PathVariable Long threadId, org.springframework.security.core.Authentication auth) {
        // BUGFIX: xác thực người gọi phải thuộc hội thoại trước khi mở SSE,
        // tránh nghe lén tin nhắn realtime của hội thoại người khác.
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        }
        Long authUserId = (Long) auth.getPrincipal();
        MessageThread streamThread = threadRepository.findById(threadId).orElseThrow(
                () -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));
        if (!authUserId.equals(streamThread.getUserId1()) && !authUserId.equals(streamThread.getUserId2())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }

        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); com.stayhub.api.service.SseHeartbeatService.register(emitter);
        emitters.putIfAbsent(threadId, new ConcurrentHashMap<>());
        
        Long emitterId = System.currentTimeMillis();
        emitters.get(threadId).put(emitterId, emitter);

        Runnable onDetach = () -> {
            if (emitters.containsKey(threadId)) {
                emitters.get(threadId).remove(emitterId);
                if (emitters.get(threadId).isEmpty()) {
                    emitters.remove(threadId);
                }
            }
        };

        emitter.onCompletion(onDetach);
        emitter.onTimeout(onDetach);
        emitter.onError((e) -> onDetach.run());

        return emitter;
    }

    @PutMapping("/{threadId}/save")
    public MessageThread toggleSave(@PathVariable Long threadId, @RequestParam Long userId, org.springframework.security.core.Authentication auth) {
        // BUGFIX: xác thực người gọi chính là userId và thuộc hội thoại.
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        }
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        MessageThread thread = threadRepository.findById(threadId).orElseThrow(
                () -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));
        if (!userId.equals(thread.getUserId1()) && !userId.equals(thread.getUserId2())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        if (userId.equals(thread.getUserId1())) {
            thread.setUser1IsSaved(thread.getUser1IsSaved() == null || !thread.getUser1IsSaved());
        } else {
            thread.setUser2IsSaved(thread.getUser2IsSaved() == null || !thread.getUser2IsSaved());
        }
        return threadRepository.save(thread);
    }

    @PutMapping("/{threadId}/delete")
    public MessageThread toggleDelete(@PathVariable Long threadId, @RequestParam Long userId, org.springframework.security.core.Authentication auth) {
        // BUGFIX: xác thực người gọi chính là userId và thuộc hội thoại.
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        }
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        MessageThread thread = threadRepository.findById(threadId).orElseThrow(
                () -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));
        if (!userId.equals(thread.getUserId1()) && !userId.equals(thread.getUserId2())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN);
        }
        if (userId.equals(thread.getUserId1())) {
            thread.setUser1IsDeleted(thread.getUser1IsDeleted() == null || !thread.getUser1IsDeleted());
        } else {
            thread.setUser2IsDeleted(thread.getUser2IsDeleted() == null || !thread.getUser2IsDeleted());
        }
        return threadRepository.save(thread);
    }
}

package com.stayhub.api.controller;

import com.stayhub.api.dto.request.DirectChatMessageRequest;
import com.stayhub.api.dto.response.DirectChatMessageDto;
import com.stayhub.api.service.DirectChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@RestController
@RequestMapping("/v1/direct-chat")
@RequiredArgsConstructor
public class V1DirectChatController {

    private final DirectChatService chatService;
    
    // Store emitters by userId
    private final Map<Long, List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    @GetMapping("/history")
    public ResponseEntity<List<DirectChatMessageDto>> getHistory(
            org.springframework.security.core.Authentication auth,
            @RequestParam Long partnerId) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long myUserId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(chatService.getHistory(myUserId, partnerId));
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribe(org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = (Long) auth.getPrincipal();
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); com.stayhub.api.service.SseHeartbeatService.register(emitter);
        emitters.computeIfAbsent(userId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        emitter.onCompletion(() -> removeEmitter(userId, emitter));
        emitter.onTimeout(() -> removeEmitter(userId, emitter));
        emitter.onError((e) -> removeEmitter(userId, emitter));

        try {
            emitter.send(SseEmitter.event().name("CONNECT").data("Connected user " + userId));
        } catch (IOException e) {
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

    @PostMapping("/send")
    public ResponseEntity<DirectChatMessageDto> sendMessage(
            org.springframework.security.core.Authentication auth,
            @RequestBody DirectChatMessageRequest request) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long senderId = (Long) auth.getPrincipal();
        
        DirectChatMessageDto msg = chatService.sendMessage(senderId, request);
        
        // Broadcast to receiver
        broadcastMessage(request.getReceiverId(), msg);
        // Also broadcast to sender (other sessions of the same user if any)
        broadcastMessage(senderId, msg);
        
        return ResponseEntity.ok(msg);
    }
    
    private void broadcastMessage(Long targetUserId, DirectChatMessageDto msg) {
        List<SseEmitter> list = emitters.get(targetUserId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("MESSAGE").data(msg));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(targetUserId, emitter);
                }
            }
        }
    }
}
